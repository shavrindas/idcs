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
from src.models.Chat import Message, MessageType
from src.models.Chat import ChatParticipant, Message


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
    """[Page 2] 단일 채팅방 실시간 통신 웹소켓 및 DB 저장"""
    await manager.connect(websocket, room_id)
    
    try:
        while True:
            # 1. 클라이언트로부터 메시지 수신 (JSON 형태 기대)
            data = await websocket.receive_text()
            payload = json.loads(data)
            
            msg_type_str = payload.get("type", "TEXT")
            content = payload.get("content", "")
            
            # MessageType Enum 변환
            msg_type = MessageType.TEXT
            if msg_type_str == "IMAGE": msg_type = MessageType.IMAGE
            elif msg_type_str == "FILE": msg_type = MessageType.FILE

            # 2. DB에 메시지 저장 로직
            new_msg = Message(
                room_id=room_id, 
                user_id=user_id, 
                message_type=msg_type,
                content=content
            )
            db.add(new_msg)
            await db.commit()
            await db.refresh(new_msg)
            
            # 3. 방에 있는 모든 사용자에게 브로드캐스트 (실제 저장된 정보)
            broadcast_msg = {
                "type": "chat",
                "message_id": new_msg.message_id,
                "user_id": user_id,
                "message_type": new_msg.message_type.value,
                "content": new_msg.content,
                # DB의 Timestamp를 String 형태로 포맷팅하여 반환
                "created_at": new_msg.created_at.strftime("%Y-%m-%d %H:%M") if new_msg.created_at else "Just now"
            }
            await manager.broadcast_to_room(room_id, broadcast_msg)
            
    except WebSocketDisconnect:
        manager.disconnect(websocket, room_id)



@router.get("/room/{room_id}/messages", status_code=status.HTTP_200_OK)
async def get_chat_messages(
    room_id: int, 
    user_id: int, 
    limit: int = 50, 
    offset: int = 0, 
    db: AsyncSession = Depends(get_db)
):
    """
    [Page 2: Box #2] 단일 채팅방 과거 메시지 기록 조회
    - ListView.reverse 속성에 맞추기 위해 최신 메시지부터 내림차순(DESC)으로 정렬하여 반환합니다.
    """
    # 1. 권한 체크 (참여자인지 확인)
    part_query = text("""
        SELECT 1 FROM chatparticipants 
        WHERE room_id = :room_id AND user_id = :user_id
    """)
    is_participant = await db.execute(part_query, {"room_id": room_id, "user_id": user_id})
    
    # 만약 관리자(ADMIN, DEVELOPER)도 제한 없이 봐야 한다면 user_table의 role 조회 로직 추가 필요
    # if not is_participant.fetchone():
    #     raise HTTPException(status_code=403, detail="해당 채팅방의 접근 권한이 없습니다.")

    # 2. 메시지 조회
    query = text("""
        SELECT message_id, user_id, message_type, content, created_at
        FROM messages
        WHERE room_id = :room_id
        ORDER BY created_at DESC
        LIMIT :limit OFFSET :offset
    """)
    result = await db.execute(query, {"room_id": room_id, "limit": limit, "offset": offset})
    messages = result.fetchall()

    return {
        "status": "success",
        "messages": [
            {
                "message_id": row.message_id,
                "user_id": row.user_id,
                "message_type": row.message_type,
                "content": row.content,
                # 프런트엔드 출력 포맷에 맞춤
                "created_at": row.created_at.strftime("%Y-%m-%d %H:%M") if row.created_at else ""
            } for row in messages
        ]
    }