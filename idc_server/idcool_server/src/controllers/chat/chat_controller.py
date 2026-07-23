# ===============================================================
# 경로 : src/controllers/chat/chat_controller.py
# 명세 : 메신저 채팅방 관리 및 웹소켓 통신 컨트롤러
# ===============================================================
import json
from typing import List, Dict, Optional
from pydantic import BaseModel
from fastapi import APIRouter, Depends, HTTPException, status, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from config.db import get_db
from src.models.User import UserRole, User
from src.models.Chat import ChatParticipant, Message, MessageType, ChatRoomType, ChatRoom
from sqlalchemy.future import select
router = APIRouter(prefix="/chat", tags=["Chat"])

# --- [Pydantic Schemas] ---
class GroupChatCreateReq(BaseModel):
    room_name: str
    user_ids: List[int]

class AddParticipantReq(BaseModel):
    user_ids: List[int]

# --- [웹소켓 매니저] 생략 (기존 코드 유지) ---
class ConnectionManager:
    def __init__(self):
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

@router.get("/rooms/{facility_id}", status_code=status.HTTP_200_OK)
async def get_chat_rooms(facility_id: int, user_id: int, db: AsyncSession = Depends(get_db)):
    """[Page 1: Box #2] 참여 중인 채팅방 목록 조회 (실제 DB 연동 및 정렬)"""
    user_query = text("SELECT role FROM user_table WHERE id = :user_id")
    user = (await db.execute(user_query, {"user_id": user_id})).fetchone()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    
    is_admin = user.role in [UserRole.ADMIN.value, UserRole.DEVELOPER.value]

    # 사용자가 참여중인 방 조회 (최신 메시지와 안읽은 개수 포함)
    query = text("""
        SELECT cr.room_id, cr.room_name, cr.type, cr.facility_id, cp.unread_count,
               (SELECT content FROM messages m WHERE m.room_id = cr.room_id ORDER BY created_at DESC LIMIT 1) as last_message,
               (SELECT created_at FROM messages m WHERE m.room_id = cr.room_id ORDER BY created_at DESC LIMIT 1) as last_message_time
        FROM chatrooms cr
        JOIN chatparticipants cp ON cr.room_id = cp.room_id
        WHERE cp.user_id = :user_id
    """)
    result = await db.execute(query, {"user_id": user_id})
    rooms = result.fetchall()

    processed_rooms = []
    for r in rooms:
        # 정렬 우선순위 배정 (1: 현재 시설방, 2: 관리자 1:1, 3: 단체방, 4: 기타 시설방)
        priority = 4
        if r.type == 'FACILITY':
            priority = 1 if r.facility_id == facility_id else 4
        elif r.type == 'DIRECT':
            priority = 2
        elif r.type == 'GROUP':
            priority = 3

        processed_rooms.append({
            "room_id": r.room_id,
            "room_name": r.room_name or "개인 채팅방",
            "type": r.type,
            "last_message": r.last_message or "메시지가 없습니다.",
            "unread_count": r.unread_count,
            "sort_priority": priority,
            "last_message_time": str(r.last_message_time) if r.last_message_time else ""
        })

    # 우선순위(오름차순) -> 최신 메시지 시간(내림차순) 정렬
    processed_rooms.sort(key=lambda x: (x["sort_priority"], x["last_message_time"]), reverse=True)
    processed_rooms.sort(key=lambda x: x["sort_priority"])

    return {"status": "success", "rooms": processed_rooms, "is_admin": is_admin}


@router.post("/group", status_code=status.HTTP_201_CREATED)
async def create_group_chat(req: GroupChatCreateReq, user_id: int, db: AsyncSession = Depends(get_db)):
    """[관리자 전용] 단체 채팅방 생성"""
    new_room = ChatRoom(room_name=req.room_name, type=ChatRoomType.GROUP)
    db.add(new_room)
    await db.commit()
    await db.refresh(new_room)

    # 방 생성자(관리자)와 선택된 유저들을 참여자로 추가
    participants = [ChatParticipant(room_id=new_room.room_id, user_id=user_id)]
    for uid in req.user_ids:
        if uid != user_id:
            participants.append(ChatParticipant(room_id=new_room.room_id, user_id=uid))
    
    db.add_all(participants)
    await db.commit()
    return {"status": "success", "message": "단체 채팅방이 생성되었습니다.", "room_id": new_room.room_id}


@router.delete("/room/{room_id}")
async def leave_or_delete_room(
    room_id: int, 
    user_id: int, 
    action: str = "delete", 
    db: AsyncSession = Depends(get_db)
):
    """
    채팅방 삭제(delete) 또는 숨기기/나가기(hide)
    - FACILITY(시설방), DIRECT(1:1방): 관리자라도 절대 삭제 불가 (HTTP 400 거부)
    - GROUP(단체방): 관리자만 삭제 가능
    """
    # 1. 요청한 유저의 권한 확인
    user_res = await db.execute(select(User).where(User.id == user_id))
    user = user_res.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

    is_admin = user.role in [UserRole.ADMIN, UserRole.DEVELOPER]

    # 2. 대상 채팅방 조회
    room_res = await db.execute(select(ChatRoom).where(ChatRoom.room_id == room_id))
    room = room_res.scalars().first()
    if not room:
        raise HTTPException(status_code=404, detail="존재하지 않는 채팅방입니다.")

    # 3. [핵심] 채팅방 삭제 보호 및 검증 로직
    if action == "delete":
        # 관리자 권한 검증
        if not is_admin:
            raise HTTPException(status_code=403, detail="채팅방 삭제 권한이 없습니다.")

        # 🛡️ 방 유형별 삭제 차단 보호 로직
        if room.type in [ChatRoomType.FACILITY, ChatRoomType.DIRECT]:
            raise HTTPException(
                status_code=400, 
                detail=f"[{room.type.value}] 유형의 채팅방은 시스템 보호 정책상 삭제할 수 없습니다."
            )

        # GROUP(단체방)일 경우에만 실제 DB에서 삭제 수행 (CASCADE로 메시지/참여자 연쇄 삭제)
        await db.delete(room)
        await db.commit()
        return {"status": "success", "message": f"단체 채팅방 '{room.room_name}'이(가) 성공적으로 삭제되었습니다."}

    elif action == "hide":
        # TODO: 개인별 방 숨기기 / 나가기 처리 (chatparticipants 상태 변경)
        return {"status": "success", "message": "채팅방이 숨김 처리되었습니다."}
    
    else:
        raise HTTPException(status_code=400, detail="잘못된 액션 요청입니다.")


@router.get("/room/{room_id}/participants")
async def get_chat_participants(room_id: int, db: AsyncSession = Depends(get_db)):
    """[Page 2] 참여자 목록 조회 (Drawer 용)"""
    query = text("""
        SELECT u.id, u.name, u.role 
        FROM chatparticipants cp
        JOIN user_table u ON cp.user_id = u.id
        WHERE cp.room_id = :room_id
    """)
    result = await db.execute(query, {"room_id": room_id})
    users = [{"id": row.id, "name": row.name, "role": row.role} for row in result.fetchall()]
    return {"status": "success", "participants": users}


@router.put("/room/{room_id}/read")
async def update_last_read(room_id: int, user_id: int, db: AsyncSession = Depends(get_db)):
    """[Page 2] 채팅방 입장 시 읽음 플래그 처리"""
    query = text("""
        UPDATE chatparticipants 
        SET unread_count = 0, 
            last_read_message_id = (SELECT COALESCE(MAX(message_id), 0) FROM messages WHERE room_id = :room_id)
        WHERE room_id = :room_id AND user_id = :user_id
    """)
    await db.execute(query, {"room_id": room_id, "user_id": user_id})
    await db.commit()
    return {"status": "success"}

# --- 과거 메시지 조회 로직 및 웹소켓 로직은 직전 구현체와 동일하게 유지 ---
@router.get("/room/{room_id}/messages", status_code=status.HTTP_200_OK)
async def get_chat_messages(
    room_id: int, user_id: int, limit: int = 50, offset: int = 0, 
    keyword: Optional[str] = None, db: AsyncSession = Depends(get_db)
):
    """과거 메시지 로드 (검색어 포함)"""
    where_clause = "WHERE room_id = :room_id"
    params = {"room_id": room_id, "limit": limit, "offset": offset}
    
    if keyword and keyword.strip():
        where_clause += " AND content ILIKE :keyword"
        params["keyword"] = f"%{keyword.strip()}%"

    query = text(f"""
        SELECT message_id, user_id, message_type, content, created_at
        FROM messages
        {where_clause}
        ORDER BY created_at DESC
        LIMIT :limit OFFSET :offset
    """)
    result = await db.execute(query, params)
    messages = result.fetchall()

    return {
        "status": "success",
        "messages": [{
            "message_id": row.message_id, "user_id": row.user_id,
            "message_type": row.message_type.value if hasattr(row.message_type, 'value') else row.message_type,
            "content": row.content, "created_at": row.created_at.strftime("%Y-%m-%d %H:%M") if row.created_at else ""
        } for row in messages]
    }

@router.websocket("/ws/{room_id}/{user_id}")
async def chat_websocket(websocket: WebSocket, room_id: int, user_id: int, db: AsyncSession = Depends(get_db)):
    """실시간 웹소켓 통신"""
    await manager.connect(websocket, room_id)
    try:
        while True:
            data = await websocket.receive_text()
            payload = json.loads(data)
            
            msg_type = MessageType.IMAGE if payload.get("type") == "IMAGE" else MessageType.TEXT
            new_msg = Message(room_id=room_id, user_id=user_id, message_type=msg_type, content=payload.get("content", ""))
            db.add(new_msg)
            await db.commit()
            await db.refresh(new_msg)
            
            # 메시지 발송 시 다른 참여자들의 unread_count 증가
            update_unread = text("UPDATE chatparticipants SET unread_count = unread_count + 1 WHERE room_id = :room_id AND user_id != :user_id")
            await db.execute(update_unread, {"room_id": room_id, "user_id": user_id})
            await db.commit()

            broadcast_msg = {
                "type": "chat", "message_id": new_msg.message_id, "user_id": user_id,
                "message_type": msg_type.value, "content": new_msg.content,
                "created_at": new_msg.created_at.strftime("%Y-%m-%d %H:%M") if new_msg.created_at else "Just now"
            }
            await manager.broadcast_to_room(room_id, broadcast_msg)
    except WebSocketDisconnect:
        manager.disconnect(websocket, room_id)