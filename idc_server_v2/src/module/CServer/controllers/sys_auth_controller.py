# ===============================================================
# 경로 : src/module/CServer/controllers/sys_auth_controller.py
# 명세 : 시스템 대 시스템 인증 및 스트리밍 컨트롤러


from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from pydantic import BaseModel

from src.config.database import get_db, AsyncSessionLocal
from src.module.Core.models.Facility import FacilityNode
from src.module.Core.security import create_system_token, verify_system_token, hash_api_key

router = APIRouter(prefix="/sys-auth", tags=["System Authentication"])
stream_router = APIRouter(tags=["System Stream"])

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
    
    node.status = "ONLINE"
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
    print(f"[CServer] 시설({facility_id}) 시스템 노드(ID: {node_id}) 연결 성공 및 스트리밍 시작")
    
    try:
        while True:
            data = await websocket.receive_text()
            # FServer가 정상 종료 전 던지는 메시지 감지
            if data == "__SHUTDOWN__":
                print(f"[CServer] 시설({facility_id}) 노드(ID: {node_id}) 정상 종료 통보 수신")
                break
    except WebSocketDisconnect:
        print(f"[CServer] 시설({facility_id}) 시스템 연결 단절됨")
    finally:
        # 단절 감지 즉시 DB 상태를 OFFLINE으로 변경
        # async with AsyncSessionLocal() as session:
        #     result = await session.execute(select(FacilityNode).where(FacilityNode.id == node_id))
        #     target_node = result.scalars().first()
        #     if target_node:
        #         target_node.status = "OFFLINE"
        #         await session.commit()

        async with AsyncSessionLocal() as session:
                result = await session.execute(select(FacilityNode).where(FacilityNode.id == node_id))
                target_node = result.scalars().first()
                if target_node:
                    target_node.last_heartbeat_at = func.now()
                    await session.commit()

            # print(f"받은 데이터: {data}")
                print(f"[CServer] 노드(ID: {node_id}) 상태를 OFFLINE으로 갱신 완료")