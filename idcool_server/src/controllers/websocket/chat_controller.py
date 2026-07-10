from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from typing import Dict, List
import src.services.chat as cd
import src.services.chatroom as cr
import json

router = APIRouter()

@router.post("/ms/chat/list/")
async def chatlist(data: dict):
    return cd.chatlist(data.get("user"))

@router.post("/ms/chat/add/")
async def chatadd(data: dict):
    status = cd.chatadd(data.get("user"), data.get("room_name"), data.get("type"))
    return status

socket: Dict[int, WebSocket] = {}

@router.post("/ms/facility/users")
async def get_facility_users(user_id: int):
    return cr.get_facility_users(user_id)

@router.get("/ms/chat/{room_id}/messages")
async def get_message(room_id: int):
    return cr.messages_get(room_id)

@router.websocket("/ms/chat/{room_id}")
async def websocket_endpoint(
    websocket: WebSocket, 
    room_id: int,
    # 필요하다면 의존성 주입을 통해 비즈니스 로직 서비스 가져오기
):
    # 클라이언트 연결 수락 (Handshake)
    await websocket.accept()

    if room_id not in socket:
        socket[room_id] = []
    socket[room_id].append(websocket)
    
    try:
        while True:
            # 연결 루프
            data = await websocket.receive_text()

            msg = cr.messages_add(room_id, data)



            if room_id in socket:
                for connection in socket[room_id]:
                    try:
                        res_dict = msg['res'].model_dump()
                        res_dict['user_name'] = msg["sender"]
                        await connection.send_text(json.dumps(res_dict, default=str))
                    except Exception as e:
                        pass
            
    except WebSocketDisconnect:
        # 연결 종료 처리
        if room_id in socket:
            print("connection close")
            socket[room_id].remove(websocket)
            if not socket:
                del socket[room_id]

@router.post("/ms/chat/userinv/")
async def add_users_to_room(data: dict):
    room_id = data.get("room_id")
    user_ids = data.get("users_id")

    return cr.invite_user_to_room(user_ids, room_id)