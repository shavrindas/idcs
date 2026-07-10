import json
import src.models.messages as md
import src.models.facility_users as fu
import src.models.user_table as ut
import src.models.chatparticipants as cp

def messages_add(room_id: int, data: str):
    data_dict = json.loads(data)

    user_id = data_dict.get("user_id")
    message_type = data_dict.get("msg_type")
    content = data_dict.get("content")
    parent_message_id = data_dict.get("parent_msg")

    msg = md.messages_add(room_id, user_id, message_type, content, parent_message_id)
    usr_name = ut.user_find_by_id(user_id).name
    
    # `with` 블록을 빠져나오면 자동으로 commit 및 커넥션 반납(putconn)이 완료됩니다.
    return {
        "status": "success",
        "message": "메시지가 성공적으로 생성되었습니다.",
        "res": msg,
        "sender": usr_name
    }

def messages_get(room_id: int):
    msgs = md.message_get_by_room(room_id)
    return msgs

def get_facility_users(user_id: int):
    facility_id = fu.facility_users_get_by_user(user_id)

    return ut.users_find_same_facility(facility_id)

def invite_user_to_room(user_id: list[int], room_id: int):
    cp.chatpartadds(user_id, room_id)
    
    # `with` 블록을 빠져나오면 자동으로 commit 및 커넥션 반납(putconn)이 완료됩니다.
    return {
        "status": "success",
        "message": "초대 성공",
        "id": user_id
    }