# ===============================================================
# 경로 : src/controllers/chat/chat_controller.py
# 명세 : 메신저 채팅방 관리 및 웹소켓 통신 컨트롤러
# ===============================================================
import json
from typing import List, Dict
from fastapi import APIRouter, Depends, HTTPException, status, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from config.db import get_db
from src.models.User import UserRole

router = APIRouter(prefix="/chat", tags=["Chat"])

# --- [웹소켓 매니저] ---
class ConnectionManager:
    def __init__(self):
        # room_id를 키로 하고, 접속한 websocket 리스트를 값으로 가짐
        self.active_connections: Dict[int, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, room_id: int):
        await websocket.accept()
        if room_id not in self.active_connections:
            self.active_connections[room_id] = []
        self.active_connections[room_id].append(websocket)

    def disconnect(self, websocket: WebSocket, room_id: int):
        if room_id in self.active_connections:
            self.active_connections[room_id].remove(websocket)
            if not self.active_connections[room_id]:
                del self.active_connections[room_id]

    async def broadcast_to_room(self, room_id: int, message: dict):
        if room_id in self.active_connections:
            for connection in self.active_connections[room_id]:
                await connection.send_text(json.dumps(message))

manager = ConnectionManager()

# --- [API Endpoints] ---

@router.get("/rooms/{facility_id}")
async def get_chat_rooms(facility_id: int, user_id: int, db: AsyncSession = Depends(get_db)):
    """
    [Page 1: Box #2] 참여 중인 채팅방 목록 조회
    - 정렬 규칙 적용을 위해 백엔드에서 type과 고정 여부 플래그를 달아서 반환합니다.
    """
    # 1. 유저 권한 확인
    user_query = text("SELECT role FROM user_table WHERE id = :user_id")
    user_res = await db.execute(user_query, {"user_id": user_id})
    user = user_res.fetchone()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

    is_admin = user.role in [UserRole.ADMIN.value, UserRole.DEVELOPER.value]

    # 2. 내가 참여중인 채팅방 목록 조회 (최근 메시지 포함)
    # TODO: 실제 쿼리는 Message 테이블 조인 후 최신 메시지 서브쿼리 사용 필요. 
    # 여기서는 프런트엔드 연동을 위한 더미 스키마 반환
    
    # 프런트 정렬을 위한 힌트 제공: 
    # sort_priority: 1 (최상단 고정 - 시설방), 2 (관리자 1:1 고정), 3 (즐겨찾기), 4 (일반)
    dummy_rooms = [
        {
            "room_id": 101,
            "room_name": f"시설 {facility_id} 공식 채팅방",
            "type": "FACILITY",
            "last_message": "최근 공지사항입니다.",
            "unread_count": 0,
            "sort_priority": 1 
        },
        {
            "room_id": 102,
            "room_name": "관리자 1:1 문의",
            "type": "DIRECT",
            "last_message": "네, 확인했습니다.",
            "unread_count": 2,
            "sort_priority": 2
        },
        {
            "room_id": 103,
            "room_name": "유지보수 단체방",
            "type": "GROUP",
            "last_message": "내일 점검 예정입니다.",
            "unread_count": 5,
            "sort_priority": 4
        }
    ]

    # TODO: 관리자인 경우 추가적으로 모든 1:1 방(sort_priority 2)을 끌어오도록 로직 분기

    return {"status": "success", "rooms": dummy_rooms, "is_admin": is_admin}


@router.post("/group")
async def create_group_chat(req_data: dict, db: AsyncSession = Depends(get_db)):
    """[관리자 전용] 단체 채팅방 생성"""
    # TODO: ChatRoom 생성 및 선택된 user_ids를 ChatParticipant에 INSERT
    return {"status": "success", "message": "단체 채팅방이 생성되었습니다.", "room_id": 999}


@router.delete("/room/{room_id}")
async def hide_or_delete_room(room_id: int, user_id: int, action: str = "hide", db: AsyncSession = Depends(get_db)):
    """
    채팅방 숨기기(hide) 또는 삭제(delete - 관리자용)
    """
    # TODO: action이 'hide'면 유저의 participant 상태를 변경, 'delete'면 완전 삭제
    return {"status": "success", "message": f"채팅방이 {action} 처리되었습니다."}


# --- [WebSocket Endpoint] ---

@router.websocket("/ws/{room_id}/{user_id}")
async def chat_websocket(websocket: WebSocket, room_id: int, user_id: int, db: AsyncSession = Depends(get_db)):
    """[Page 2] 단일 채팅방 실시간 통신 웹소켓"""
    await manager.connect(websocket, room_id)
    
    # 접속 알림 (선택적)
    # await manager.broadcast_to_room(room_id, {"type": "system", "content": f"User {user_id} joined."})
    
    try:
        while True:
            # 1. 클라이언트로부터 메시지 수신 (JSON 형태 기대)
            data = await websocket.receive_text()
            payload = json.loads(data)
            
            # 2. DB에 메시지 저장 로직 (비동기로 안전하게 처리)
            # new_msg = Message(room_id=room_id, user_id=user_id, content=payload['content'], ...)
            # db.add(new_msg); await db.commit()
            
            # 3. 방에 있는 모든 사용자에게 브로드캐스트
            broadcast_msg = {
                "type": "chat",
                "message_id": 12345, # DB에 저장 후 얻은 ID
                "user_id": user_id,
                "content": payload.get("content", ""),
                "created_at": "2026-07-22 16:52:00" # 실제 DB 시간으로 대체
            }
            await manager.broadcast_to_room(room_id, broadcast_msg)
            
    except WebSocketDisconnect:
        manager.disconnect(websocket, room_id)
        # 퇴장 알림 (선택적)