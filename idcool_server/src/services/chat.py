import src.models.chatrooms as md
import src.models.chatparticipants as cp

def chatadd(user_id: int, room_name: str, room_type: str):

    data = md.chatroomadd(room_name, room_type)

    cp.chatpartadd(user_id, data.room_id)
    
    # `with` 블록을 빠져나오면 자동으로 commit 및 커넥션 반납(putconn)이 완료됩니다.
    return {
        "status": "success",
        "message": "채팅방이 성공적으로 생성되었습니다.",
        "id": data.room_id
    }

def chatlist(user_id: str):
    data = md.chatrooms_get_by_user(user_id)
    
    return data