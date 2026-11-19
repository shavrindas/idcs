# ===============================================================
# 경로 : src/module/ServiceApp/controllers/chat_controller.py
# 명세 : 메신저 채팅방 관리 및 웹소켓 통신 컨트롤러
# ===============================================================
import json
import os
import uuid
from datetime import datetime
from io import BytesIO
from typing import List, Dict, Optional
from PIL import Image
from pydantic import BaseModel
from fastapi import APIRouter, Depends, HTTPException, Request, UploadFile, File, status, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from src.config.database import get_db
from src.module.Core.models.User import UserRole, User
from src.module.Core.models.Chat import ChatParticipant, Message, MessageType, ChatRoomType, ChatRoom, MessagePin, MessageFav
from sqlalchemy.future import select

router = APIRouter(prefix="/chat", tags=["Chat"])

# 채팅 첨부 이미지. 게시판(board_controller)과 같은 정책 — 너무 큰 원본을
# 그대로 저장하면 느려지니 1920px 기준으로 줄인다.
UPLOAD_ROOT = "uploads/chat"
MAX_IMAGE_BYTES = 10 * 1024 * 1024
MAX_IMAGE_SIDE = 1920

# --- [Pydantic Schemas] ---
class GroupChatCreateReq(BaseModel):
    room_name: str
    user_ids: List[int]

class EditMessageReq(BaseModel):
    content: str

# --- [웹소켓 매니저] ---
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
    """[Page 1: Box #2] 참여 중인 채팅방 목록 조회 (정렬 및 타 시설 필터링 적용)"""
    user_query = text("SELECT role FROM user_table WHERE id = :user_id")
    user = (await db.execute(user_query, {"user_id": user_id})).fetchone()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    
    is_admin = user.role in [UserRole.ADMIN.value, UserRole.DEVELOPER.value]

    # 다른 시설의 공식 채팅방(FACILITY) 제외 & 상대방 권한/시설 소속 여부 파악
    query = text("""
        SELECT cr.room_id, cr.room_name, cr.type, cr.facility_id, cp.unread_count,
               (SELECT content FROM messages m WHERE m.room_id = cr.room_id ORDER BY created_at DESC LIMIT 1) as last_message,
               (SELECT created_at FROM messages m WHERE m.room_id = cr.room_id ORDER BY created_at DESC LIMIT 1) as last_message_time,
               (
                   SELECT u.role 
                   FROM chatparticipants cp2 
                   JOIN user_table u ON cp2.user_id = u.id 
                   WHERE cp2.room_id = cr.room_id AND cp2.user_id != :user_id
                   LIMIT 1
               ) as other_user_role,
               (
                   SELECT COUNT(*)
                   FROM chatparticipants cp2
                   JOIN facility_users fu ON cp2.user_id = fu.user_id
                   WHERE cp2.room_id = cr.room_id AND cp2.user_id != :user_id AND fu.facility_id = :facility_id
               ) as other_user_in_facility,
               (
                   SELECT COUNT(*) FROM messages_fav mf WHERE mf.room_id = cr.room_id AND mf.user_id = :user_id
               ) as is_favorite
        FROM chatrooms cr
        JOIN chatparticipants cp ON cr.room_id = cp.room_id
        WHERE cp.user_id = :user_id
          AND (cr.type != 'FACILITY' OR cr.facility_id = :facility_id)
    """)
    result = await db.execute(query, {"user_id": user_id, "facility_id": facility_id})
    rooms = result.fetchall()

    processed_rooms = []
    for r in rooms:
        priority = 99
        if r.type == 'FACILITY':
            priority = 1
        elif r.type == 'DIRECT':
            if is_admin:
                # 관리자 정렬: 2. 관리자vs관리자, 3. 현재 시설 유저, 6. 기타 유저
                if r.other_user_role in ['ADMIN', 'DEVELOPER']: priority = 2
                elif r.other_user_in_facility > 0: priority = 3
                else: priority = 6
            else:
                priority = 2 # 유저에게 관리자 1:1은 시설방 다음으로 중요
        elif r.type == 'GROUP':
            priority = 5 # (4는 즐겨찾기 용도로 비워둠)

        is_favorite = r.is_favorite > 0
        # 즐겨찾기한 방은 4순위로 끌어올린다 — 단, 이미 1~3순위(시설방/관리자
        # 방)보다 더 중요하게 취급되던 방을 즐겨찾기 때문에 밀어내지는 않는다.
        if is_favorite and priority > 4:
            priority = 4

        room_name_display = r.room_name
        if r.type == 'DIRECT' and not room_name_display:
            room_name_display = "1:1 채팅방"

        processed_rooms.append({
            "room_id": r.room_id,
            "room_name": room_name_display,
            "type": r.type,
            "last_message": r.last_message or "메시지가 없습니다.",
            "unread_count": r.unread_count,
            "sort_priority": priority,
            "is_favorite": is_favorite,
            "last_message_time": str(r.last_message_time) if r.last_message_time else ""
        })

    # 정렬: 1순위(우선순위 오름차순), 2순위(최신 메시지 내림차순)
    processed_rooms.sort(key=lambda x: x["last_message_time"], reverse=True)
    processed_rooms.sort(key=lambda x: x["sort_priority"])

    return {"status": "success", "rooms": processed_rooms, "is_admin": is_admin}

@router.post("/group", status_code=status.HTTP_201_CREATED)
async def create_group_chat(req: GroupChatCreateReq, user_id: int, db: AsyncSession = Depends(get_db)):
    """[관리자 전용] 단체 채팅방 생성"""
    new_room = ChatRoom(room_name=req.room_name, type=ChatRoomType.GROUP)
    db.add(new_room)
    await db.commit()
    await db.refresh(new_room)

    participants = [ChatParticipant(room_id=new_room.room_id, user_id=user_id)]
    for uid in req.user_ids:
        if uid != user_id:
            participants.append(ChatParticipant(room_id=new_room.room_id, user_id=uid))
    
    db.add_all(participants)
    await db.commit()
    return {"status": "success", "message": "단체 채팅방이 생성되었습니다.", "room_id": new_room.room_id}

@router.delete("/room/{room_id}")
async def leave_or_delete_room(room_id: int, user_id: int, action: str = "delete", db: AsyncSession = Depends(get_db)):
    """채팅방 삭제 보호 적용 (관리자라도 FACILITY, DIRECT 삭제 불가)"""
    user_res = await db.execute(select(User).where(User.id == user_id))
    user = user_res.scalars().first()
    is_admin = user.role in [UserRole.ADMIN, UserRole.DEVELOPER]

    room_res = await db.execute(select(ChatRoom).where(ChatRoom.room_id == room_id))
    room = room_res.scalars().first()
    if not room: raise HTTPException(status_code=404, detail="방이 없습니다.")

    if action == "delete":
        if not is_admin: raise HTTPException(status_code=403, detail="삭제 권한이 없습니다.")
        if room.type in [ChatRoomType.FACILITY, ChatRoomType.DIRECT]:
            raise HTTPException(status_code=400, detail=f"[{room.type.value}] 방은 시스템 정책상 삭제할 수 없습니다.")
        
        await db.delete(room)
        await db.commit()
        return {"status": "success", "message": "단체 채팅방이 삭제되었습니다."}
    
    elif action == "hide":
        part = (await db.execute(select(ChatParticipant).where(ChatParticipant.room_id == room_id, ChatParticipant.user_id == user_id))).scalars().first()
        if part: await db.delete(part)
        await db.commit()
        return {"status": "success", "message": "채팅방에서 나갔습니다."}

@router.get("/room/{room_id}/pinned")
async def get_pinned_messages(room_id: int, db: AsyncSession = Depends(get_db)):
    """상단 고정 배너용 — 이 방에서 고정된 메시지 전체 (최신 고정순)."""
    query = text("""
        SELECT m.message_id, m.user_id, m.message_type, m.content, m.created_at
        FROM messages_pin p
        JOIN messages m ON p.message_id = m.message_id
        WHERE p.room_id = :room_id
        ORDER BY p.created_at DESC
    """)
    result = await db.execute(query, {"room_id": room_id})
    rows = result.fetchall()
    return {
        "status": "success",
        "pinned": [{
            "message_id": r.message_id, "user_id": r.user_id,
            "message_type": r.message_type.value if hasattr(r.message_type, 'value') else r.message_type,
            "content": r.content,
            "created_at": r.created_at.strftime("%Y-%m-%d %H:%M") if r.created_at else "",
        } for r in rows]
    }

@router.post("/room/{room_id}/pin/{message_id}")
async def toggle_pin_message(room_id: int, message_id: int, user_id: int, db: AsyncSession = Depends(get_db)):
    """메시지 고정 토글 (관리자는 타인 메시지 고정 해제 가능)"""
    # 1. 고정 상태 확인
    pin_res = await db.execute(select(MessagePin).where(MessagePin.message_id == message_id))
    pin = pin_res.scalars().first()

    # 2. 유저 권한 확인
    user_res = await db.execute(select(User).where(User.id == user_id))
    user = user_res.scalars().first()
    is_admin = user.role in [UserRole.ADMIN, UserRole.DEVELOPER]

    if pin:
        # 고정 해제 (관리자 무조건 가능)
        await db.delete(pin)
        await db.commit()
        return {"status": "success", "message": "메시지 고정이 해제되었습니다."}
    else:
        # 새 고정. room_id 와 user_id 는 NOT NULL 컬럼이라 빠뜨리면
        # IntegrityError 로 500 이 난다 — 고정이 "눌러도 안 됨"으로 보이던 원인.
        new_pin = MessagePin(room_id=room_id, message_id=message_id, user_id=user_id)
        db.add(new_pin)
        await db.commit()
        return {"status": "success", "message": "메시지가 고정되었습니다."}

@router.post("/room/{room_id}/favorite")
async def toggle_favorite_room(room_id: int, user_id: int, db: AsyncSession = Depends(get_db)):
    """채팅방 즐겨찾기 토글"""
    fav_res = await db.execute(select(MessageFav).where(MessageFav.room_id == room_id, MessageFav.user_id == user_id))
    fav = fav_res.scalars().first()

    if fav:
        await db.delete(fav)
        await db.commit()
        return {"status": "success", "is_favorite": False, "message": "즐겨찾기가 해제되었습니다."}
    else:
        new_fav = MessageFav(room_id=room_id, user_id=user_id)
        db.add(new_fav)
        await db.commit()
        return {"status": "success", "is_favorite": True, "message": "즐겨찾기에 추가되었습니다."}

@router.put("/message/{message_id}")
async def edit_message(message_id: int, req: EditMessageReq, user_id: int, db: AsyncSession = Depends(get_db)):
    """메시지 내용 수정 (본인 글만)"""
    msg_res = await db.execute(select(Message).where(Message.message_id == message_id))
    msg = msg_res.scalars().first()
    if not msg:
        raise HTTPException(status_code=404, detail="메시지를 찾을 수 없습니다.")
    if msg.user_id != user_id:
        raise HTTPException(status_code=403, detail="본인이 작성한 메시지만 수정할 수 있습니다.")

    msg.content = req.content
    await db.commit()
    return {"status": "success", "message": "메시지가 수정되었습니다."}

@router.delete("/message/{message_id}")
async def delete_message(message_id: int, user_id: int, db: AsyncSession = Depends(get_db)):
    """메시지 삭제 (본인 글, 또는 관리자는 누구든)"""
    msg_res = await db.execute(select(Message).where(Message.message_id == message_id))
    msg = msg_res.scalars().first()
    if not msg:
        raise HTTPException(status_code=404, detail="메시지를 찾을 수 없습니다.")

    if msg.user_id != user_id:
        user_res = await db.execute(select(User).where(User.id == user_id))
        user = user_res.scalars().first()
        is_admin = user and user.role in [UserRole.ADMIN, UserRole.DEVELOPER]
        if not is_admin:
            raise HTTPException(status_code=403, detail="본인이 작성한 메시지만 삭제할 수 있습니다.")

    await db.delete(msg)
    await db.commit()
    return {"status": "success", "message": "메시지가 삭제되었습니다."}

@router.post("/room/{room_id}/image/upload")
async def upload_chat_image(room_id: int, request: Request, file: UploadFile = File(...)):
    """채팅 이미지 업로드. 저장 후 절대 URL 을 돌려주면, 그 URL 을 IMAGE 메시지의
    content 로 웹소켓에 실어 보낸다 (board_controller 의 이미지 업로드와 같은 방식)."""
    contents = await file.read()
    if len(contents) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=400, detail="이미지 용량이 너무 큽니다 (최대 10MB).")

    try:
        image = Image.open(BytesIO(contents))
        image.load()
    except Exception:
        raise HTTPException(status_code=400, detail="이미지 파일을 열 수 없습니다.")

    if image.width > MAX_IMAGE_SIDE or image.height > MAX_IMAGE_SIDE:
        ratio = min(MAX_IMAGE_SIDE / image.width, MAX_IMAGE_SIDE / image.height)
        image = image.resize((int(image.width * ratio), int(image.height * ratio)), Image.LANCZOS)

    ext = (file.filename.rsplit(".", 1)[-1] if file.filename and "." in file.filename else "jpg").lower()
    if image.mode in ("RGBA", "P") and ext in ("jpg", "jpeg"):
        image = image.convert("RGB")

    today = datetime.now()
    save_dir = os.path.join(UPLOAD_ROOT, f"{today:%Y}", f"{today:%m}", f"{today:%d}")
    os.makedirs(save_dir, exist_ok=True)
    filename = f"{uuid.uuid4().hex}.{ext}"
    save_path = os.path.join(save_dir, filename)
    image.save(save_path)

    relative_url = f"/{save_path.replace(os.sep, '/')}"
    image_url = str(request.base_url).rstrip("/") + relative_url
    return {"status": "success", "image_url": image_url}

@router.get("/room/{room_id}/participants")
async def get_chat_participants(room_id: int, db: AsyncSession = Depends(get_db)):
    query = text("""
        SELECT u.id, u.name, u.role 
        FROM chatparticipants cp
        JOIN user_table u ON cp.user_id = u.id
        WHERE cp.room_id = :room_id
    """)
    result = await db.execute(query, {"room_id": room_id})
    return {"status": "success", "participants": [{"id": r.id, "name": r.name, "role": r.role} for r in result.fetchall()]}

@router.put("/room/{room_id}/read")
async def update_last_read(room_id: int, user_id: int, db: AsyncSession = Depends(get_db)):
    query = text("""
        UPDATE chatparticipants 
        SET unread_count = 0, last_read_message_id = (SELECT COALESCE(MAX(message_id), 0) FROM messages WHERE room_id = :room_id)
        WHERE room_id = :room_id AND user_id = :user_id
    """)
    await db.execute(query, {"room_id": room_id, "user_id": user_id})
    await db.commit()
    return {"status": "success"}

@router.get("/room/{room_id}/messages")
async def get_chat_messages(room_id: int, user_id: int, limit: int = 50, offset: int = 0, keyword: Optional[str] = None, db: AsyncSession = Depends(get_db)):
    """과거 메시지 로드 (답장 원문, 고정 여부 포함)"""
    where_clause = "WHERE m.room_id = :room_id"
    params = {"room_id": room_id, "limit": limit, "offset": offset}
    
    if keyword and keyword.strip():
        where_clause += " AND m.content ILIKE :keyword"
        params["keyword"] = f"%{keyword.strip()}%"

    query = text(f"""
        SELECT m.message_id, m.user_id, m.message_type, m.content, m.created_at,
               pm.content as parent_content,
               (SELECT COUNT(*) FROM messages_pin p WHERE p.message_id = m.message_id) as is_pinned
        FROM messages m
        LEFT JOIN messages pm ON m.parent_message_id = pm.message_id
        {where_clause}
        ORDER BY m.created_at DESC
        LIMIT :limit OFFSET :offset
    """)
    result = await db.execute(query, params)
    messages = result.fetchall()

    return {
        "status": "success",
        "messages": [{
            "message_id": r.message_id, "user_id": r.user_id,
            "message_type": r.message_type.value if hasattr(r.message_type, 'value') else r.message_type,
            "content": r.content,
            "created_at": r.created_at.strftime("%Y-%m-%d %H:%M") if r.created_at else "",
            "parent_content": r.parent_content,
            "is_pinned": r.is_pinned > 0
        } for r in messages]
    }

@router.websocket("/ws/{room_id}/{user_id}")
async def chat_websocket(websocket: WebSocket, room_id: int, user_id: int, db: AsyncSession = Depends(get_db)):
    await manager.connect(websocket, room_id)
    try:
        while True:
            data = await websocket.receive_text()
            payload = json.loads(data)
            
            msg_type = MessageType.IMAGE if payload.get("type") == "IMAGE" else MessageType.TEXT
            parent_id = payload.get("parent_message_id") # 답장 시 활용

            new_msg = Message(
                room_id=room_id, user_id=user_id, message_type=msg_type, 
                content=payload.get("content", ""), parent_message_id=parent_id
            )
            db.add(new_msg)
            await db.commit()
            await db.refresh(new_msg)
            
            update_unread = text("UPDATE chatparticipants SET unread_count = unread_count + 1 WHERE room_id = :room_id AND user_id != :user_id")
            await db.execute(update_unread, {"room_id": room_id, "user_id": user_id})
            await db.commit()

            parent_content = None
            if parent_id:
                parent_res = await db.execute(select(Message.content).where(Message.message_id == parent_id))
                parent_content = parent_res.scalar()

            broadcast_msg = {
                "type": "chat", "message_id": new_msg.message_id, "user_id": user_id,
                "message_type": msg_type.value, "content": new_msg.content,
                "created_at": new_msg.created_at.strftime("%Y-%m-%d %H:%M") if new_msg.created_at else "Just now",
                "parent_content": parent_content,
                "is_pinned": False
            }
            await manager.broadcast_to_room(room_id, broadcast_msg)
    except WebSocketDisconnect:
        manager.disconnect(websocket, room_id)