# src/module/CServer/controllers/sys_auth_controller.py 수정본
import json
from typing import Dict, Set
from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from pydantic import BaseModel

from src.config.database import get_db, AsyncSessionLocal
from src.module.Core.models.Facility import FacilityNode, NodeStatusType
from src.module.Core.security import create_system_token, verify_system_token, hash_api_key
from src.module.CServer.services.data_service import facility_log_check, facility_alarm_check, facility_remote_record

router = APIRouter(prefix="/sys-auth", tags=["System Authentication"])
stream_router = APIRouter(tags=["System Stream"])

# 시설별 FServer 웹소켓 및 클라이언트(앱/웹) 구독자 관리 브릿지
class FacilityStreamBridge:
    def __init__(self):
        self.fserver_conns: Dict[int, WebSocket] = {}
        self.client_Listeners: Dict[int, Set[WebSocket]] = {}
        self.latest_data: Dict[int, dict] = {}

    async def register_fserver(self, facility_id: int, ws: WebSocket):
        self.fserver_conns[facility_id] = ws

    def unregister_fserver(self, facility_id: int, ws: WebSocket):
        if self.fserver_conns.get(facility_id) is ws:
            del self.fserver_conns[facility_id]

    async def broadcast_to_clients(self, facility_id: int, payload: dict):
        self.latest_data[facility_id] = payload
        listeners = self.client_Listeners.get(facility_id, set()).copy()
        for client_ws in listeners:
            try:
                await client_ws.send_text(json.dumps(payload))
            except Exception:
                self.client_Listeners[facility_id].discard(client_ws)

    async def send_command_to_fserver(self, facility_id: int, command_str: str):
        f_ws = self.fserver_conns.get(facility_id)
        if f_ws:
            await f_ws.send_text(command_str)

stream_bridge = FacilityStreamBridge()

class SystemLoginReq(BaseModel):
    node_code: str
    api_key: str

@router.post("/login")
async def system_login(req: SystemLoginReq, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(FacilityNode).where(FacilityNode.node_code == req.node_code))
    node = result.scalars().first()
    
    if not node or not node.is_active:
        raise HTTPException(status_code=401, detail="유효하지 않은 시설 노드입니다.")
    
    if node.api_key_hash != hash_api_key(req.api_key):
        raise HTTPException(status_code=401, detail="API Key가 일치하지 않습니다.")

    token = create_system_token(node_id=node.id, facility_id=node.facility_id)
    
    node.status = NodeStatusType.ONLINE
    node.last_heartbeat_at = func.now()
    await db.commit()
    
    return {
        "access_token": token, 
        "token_type": "bearer", 
        "facility_id": node.facility_id,
        "node_id": node.id
    }

@stream_router.websocket("/data-stream/{facility_id}")
async def facility_data_stream(websocket: WebSocket, facility_id: int):
    token = websocket.headers.get("X-System-Token") or websocket.query_params.get("token")
    await websocket.accept()

    if not token:
        await websocket.close(code=4001, reason="토큰이 없습니다.")
        return

    payload = verify_system_token(token)
    if payload == "EXPIRED" or not payload or int(payload.get("facility_id", -1)) != int(facility_id):
        await websocket.close(code=4001, reason="유효하지 않거나 만료된 시스템 토큰입니다.")
        return

    node_id = int(payload.get("sub"))
    await stream_bridge.register_fserver(facility_id, websocket)
    print(f"[CServer] 시설({facility_id}) 시스템 노드(ID: {node_id}) 연결 성공 및 스트리밍 시작")
    
    try:
        while True:
            data = await websocket.receive_text()
            if data == "__SHUTDOWN__":
                print(f"[CServer] 시설({facility_id}) 노드(ID: {node_id}) 정상 종료 통보 수신")
                break
            
            # FServer로부터 수신한 계측 데이터를 클라이언트(App/Web)에 브로드캐스트
            try:
                parsed = json.loads(data)
                #데이터 브로드캐스트 및 알람 체크
                if "datas" in parsed:
                    await facility_alarm_check(parsed, facility_id)
                    await stream_bridge.broadcast_to_clients(facility_id, parsed)
                #1분 단위 정리분
                if "time" in parsed:
                    await facility_log_check(parsed, facility_id)
                #쓰기 응답 처리
                if "status" in parsed:
                    await facility_remote_record(parsed)
            except json.JSONDecodeError:
                pass

    except WebSocketDisconnect:
        print(f"[CServer] 시설({facility_id}) 시스템 연결 단절됨")
    finally:
        stream_bridge.unregister_fserver(facility_id, websocket)
        # 단절 감지 즉시 DB 상태를 OFFLINE으로 정확히 변경
        async with AsyncSessionLocal() as session:
            result = await session.execute(select(FacilityNode).where(FacilityNode.id == node_id))
            target_node = result.scalars().first()
            if target_node:
                target_node.status = NodeStatusType.OFFLINE
                target_node.last_heartbeat_at = func.now()
                await session.commit()
                print(f"[CServer] 노드(ID: {node_id}) 상태를 OFFLINE으로 갱신 완료")