from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
from fastapi import WebSocket, WebSocketDisconnect
from starlette.websockets import WebSocketState
from src.module.CServer.controllers.sys_auth_controller import stream_bridge
import json
import asyncio

from src.config.database import get_db
from src.module.Core.models.Facility import Facility, FacilityUser, FacilityRoom
from src.module.Core.models.User import User, UserRole
from sqlalchemy import text
from src.module.Core.models.Chat import ChatRoom, ChatParticipant, ChatRoomType
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/facilities", tags=["ServiceApp - Facility"])

class RegisterFacilityReq(BaseModel):
    access_code: str

class InviteUserReq(BaseModel):
    user_code: str

@router.get("/{user_id}")
async def get_user_facilities(user_id: int, db: AsyncSession = Depends(get_db)):
    """유저가 소속된 시설 목록 조회 (앱 셸 권한 검증용)"""
    user = (await db.execute(select(User).where(User.id == user_id))).scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

    if user.role == UserRole.DEVELOPER:
        stmt = select(Facility).where(Facility.is_active == True)
    else:
        stmt = (
            select(Facility)
            .join(FacilityUser, Facility.id == FacilityUser.facility_id)
            .where(FacilityUser.user_id == user_id, Facility.is_active == True)
        )
        
    result = await db.execute(stmt)
    facilities = result.scalars().all()
    
    return {
        "facilities": [
            {
                "id": f.id, 
                "name": f.name, 
                "start_date": f.start_date, 
                "end_date": f.end_date,
                # [수정] 앱 셸에서 user_admin 여부를 알 수 있도록 ID 포함
                "user_admin_id": getattr(f, 'user_admin_id', None) 
            }
            for f in facilities
        ]
    }


@router.post("/{user_id}/register")
async def register_facility(user_id: int, req: RegisterFacilityReq, db: AsyncSession = Depends(get_db)):
    """접근 코드를 통한 시설 등록"""
    result = await db.execute(select(Facility).where(Facility.access_code == req.access_code))
    facility = result.scalars().first()
    
    if not facility or not facility.is_active:
        raise HTTPException(status_code=404, detail="유효하지 않은 접근 코드입니다.")
        
    exist_check = await db.execute(
        select(FacilityUser).where(FacilityUser.user_id == user_id, FacilityUser.facility_id == facility.id)
    )
    if exist_check.scalars().first():
        raise HTTPException(status_code=400, detail="이미 등록된 시설입니다.")
        
    new_mapping = FacilityUser(facility_id=facility.id, user_id=user_id)
    db.add(new_mapping)
    await db.commit()
    
    return {"message": f"'{facility.name}' 시설이 등록되었습니다."}

# @router.delete("/{user_id}/unlink/{facility_id}")
# async def unlink_facility(user_id: int, facility_id: int, db: AsyncSession = Depends(get_db)):
#     """시설 연결 해제"""
#     result = await db.execute(
#         select(FacilityUser).where(FacilityUser.user_id == user_id, FacilityUser.facility_id == facility_id)
#     )
#     mapping = result.scalars().first()    
#     if not mapping:
#         raise HTTPException(status_code=404, detail="해당 시설에 등록되어 있지 않습니다.")        
#     await db.delete(mapping)
#     await db.commit()
#     return {"message": "시설 등록이 해제되었습니다."}

@router.delete("/{user_id}/unlink/{facility_id}")
async def unlink_facility(user_id: int, facility_id: int, db: AsyncSession = Depends(get_db)):
    """시설 연결 해제 및 채팅방 자동 퇴장"""
    # 1. 시설 매핑 해제
    result = await db.execute(
        select(FacilityUser).where(FacilityUser.user_id == user_id, FacilityUser.facility_id == facility_id)
    )
    mapping = result.scalars().first()
    
    if not mapping:
        raise HTTPException(status_code=404, detail="해당 시설에 등록되어 있지 않습니다.")
        
    await db.delete(mapping)

    # 2. [추가] 해당 시설의 공식 채팅방(FACILITY)에서 참가자(ChatParticipant) 삭제
    chat_room = (await db.execute(
        select(ChatRoom).where(ChatRoom.facility_id == facility_id, ChatRoom.type == ChatRoomType.FACILITY)
    )).scalars().first()

    if chat_room:
        part_result = await db.execute(
            select(ChatParticipant).where(
                ChatParticipant.room_id == chat_room.room_id, 
                ChatParticipant.user_id == user_id
            )
        )
        participant = part_result.scalars().first()
        if participant:
            await db.delete(participant)

    await db.commit()
    return {"message": "시설 등록이 해제되었으며 채팅방에서 퇴장 처리되었습니다."}



@router.get("/rooms/{facility_id}")
async def get_facility_rooms(facility_id: int, db: AsyncSession = Depends(get_db)):
    """시설 내 호실 목록 조회"""
    result = await db.execute(select(FacilityRoom).where(FacilityRoom.facility_id == facility_id))
    rooms = result.scalars().all()
    return {
        "rooms": [
            {
                "id": r.id, 
                "facility_id": r.facility_id, 
                "name": r.name, 
                "status": r.status.value if hasattr(r.status, 'value') else r.status
            } for r in rooms
        ]
    }

@router.websocket("/data/get/{facility_id}")
async def app_facility_monitoring_ws(websocket: WebSocket, facility_id: int):
    await websocket.accept()
    if facility_id not in stream_bridge.client_Listeners:
        stream_bridge.client_Listeners[facility_id] = set()
    stream_bridge.client_Listeners[facility_id].add(websocket)

    # 접속 즉시 마지막 캐싱된 상태가 있다면 1회 전송
    if facility_id in stream_bridge.latest_data:
        await websocket.send_text(json.dumps(stream_bridge.latest_data[facility_id]))

    try:
        while True:
            # 앱에서 보낸 원격 제어 명령(WR)을 해당 시설 FServer로 전달
            cmd_text = await websocket.receive_text()
            await stream_bridge.send_command_to_fserver(facility_id, cmd_text)
    except WebSocketDisconnect:
        stream_bridge.client_Listeners[facility_id].discard(websocket)

'''개괄 모니터링 브로드캐스팅 용'''
@router.websocket("/data/outget/{user_id}")
async def app_facility_monitoring_ws(websocket: WebSocket, user_id: int):
    facility_list = []
    # 유저에게 연결된 퍼실리티 리스트 추출
    async for db in get_db():
        stmt = select(User.role).where(User.id == user_id)
        res = await db.execute(stmt)
        role = res.scalars().first()

        # Only DEVELOPER gets every facility; ADMIN is scoped to its own company.
        if role == UserRole.DEVELOPER:
            stmt = select(Facility.id).distinct()
        else:
            stmt = select(FacilityUser.facility_id).where(FacilityUser.user_id == user_id).distinct()

        res2 = await db.execute(stmt)
        facility_list = res2.scalars().all()

    await websocket.accept()

    try:
        while True:
            for f_id in facility_list:
                if f_id in stream_bridge.latest_data:
                    filtered_datas = {}
                    
                    if isinstance(stream_bridge.latest_data[f_id].get("datas"), dict):
                        for key, val in stream_bridge.latest_data[f_id]["datas"].items():
                            # control_runsw 를 더했다. 호실 목록('내 시설' 안)이
                            # 운전 상태를 이 값으로 그리는데, 개괄 화면은 같은
                            # 카드를 쓰면서 이 값만 못 받아 '콤프' 칸이 비어 있었다.
                            if any(keyword in key for keyword in ["temp_pv", "temp_sv", "temp_comp", "deforest_def", "control_runsw", "emergency_emg", "emergency_cint", "emergency_high"]):
                                filtered_datas[key] = val
                                
                    if filtered_datas:
                        await websocket.send_text(json.dumps({"facility_id": f_id, "datas": filtered_datas}))

            #연결상태 점검용
            try:
                await asyncio.wait_for(websocket.receive_text(), timeout=0.1)
            except asyncio.TimeoutError:
                pass
            
            await asyncio.sleep(1)
            
    except WebSocketDisconnect:
        print(f"[CServer] 개괄 모니터링 유저({user_id}) 연결 단절됨 (WebSocketDisconnect)")



@router.get("/{facility_id}/employees")
async def get_facility_employees(facility_id: int, user_id: int, db: AsyncSession = Depends(get_db)):
    """[앱 전용] 특정 시설의 소속 직원 목록 조회"""
    actor = (await db.execute(select(User).where(User.id == user_id))).scalars().first()
    if not actor:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

    # [방어 로직] Enum 비교 버그 원천 차단
    role_str = str(actor.role).upper()
    is_admin = "ADMIN" in role_str or "DEVELOPER" in role_str

    if not is_admin:
        exist = (await db.execute(select(FacilityUser).where(FacilityUser.user_id == user_id, FacilityUser.facility_id == facility_id))).scalars().first()
        if not exist:
            raise HTTPException(status_code=403, detail="해당 시설의 직원 목록을 볼 권한이 없습니다.")

    facility = (await db.execute(select(Facility).where(Facility.id == facility_id))).scalars().first()
    user_admin_id = getattr(facility, 'user_admin_id', None)

    # 쿼리: ADMIN과 DEVELOPER는 직원 목록에 뜨지 않도록 제외
    query = text("""
        SELECT u.id, u.name, u.email, u.role
        FROM facility_users fu
        JOIN user_table u ON fu.user_id = u.id
        WHERE fu.facility_id = :fid
          AND u.role NOT IN ('ADMIN', 'DEVELOPER')
    """)
    
    try:
        result = await db.execute(query, {"fid": facility_id})
        employees = result.fetchall()
    except Exception as e:
        print(f"직원 쿼리 실패: {e}")
        raise HTTPException(status_code=500, detail="DB 쿼리 중 오류가 발생했습니다.")

    # row._mapping 을 통해 DB 조회 결과를 안전하게 딕셔너리로 변환 (500 에러 차단)
    return {
        "status": "success",
        "employees": [
            {
                "id": row._mapping["id"],
                "name": row._mapping["name"],
                "email": row._mapping["email"],
                "is_user_admin": (row._mapping["id"] == user_admin_id),
                "is_system_admin": False
            } for row in employees
        ]
    }

@router.post("/{facility_id}/invite-by-code")
async def invite_user_by_code(facility_id: int, req: InviteUserReq, user_id: int, db: AsyncSession = Depends(get_db)):
    """[앱 전용] 유저 코드를 이용한 시설 직원 즉시 등록 및 공식 채팅방 초대"""
    actor = (await db.execute(select(User).where(User.id == user_id))).scalars().first()
    facility = (await db.execute(select(Facility).where(Facility.id == facility_id))).scalars().first()
    
    if not actor or not facility:
        raise HTTPException(status_code=404, detail="사용자 또는 시설을 찾을 수 없습니다.")

    role_str = str(actor.role).upper()
    is_admin = "ADMIN" in role_str or "DEVELOPER" in role_str
    is_user_admin = (getattr(facility, 'user_admin_id', None) == user_id)
    
    if not is_admin and not is_user_admin:
        raise HTTPException(status_code=403, detail="직원을 초대할 권한이 없습니다.")

    target_user = (await db.execute(select(User).where(User.user_code == req.user_code))).scalars().first()
    if not target_user:
        raise HTTPException(status_code=404, detail="해당 유저 코드를 가진 사용자를 찾을 수 없습니다.")

    exist = (await db.execute(select(FacilityUser).where(FacilityUser.facility_id == facility_id, FacilityUser.user_id == target_user.id))).scalars().first()
    if exist:
        raise HTTPException(status_code=400, detail="이미 해당 시설에 등록된 직원입니다.")

    # 시설-유저 매핑 추가 (즉시 등록)
    db.add(FacilityUser(facility_id=facility_id, user_id=target_user.id))

    # 공식 채팅방(FACILITY) 자동 참여
    chat_room = (await db.execute(select(ChatRoom).where(ChatRoom.facility_id == facility_id, ChatRoom.type == ChatRoomType.FACILITY))).scalars().first()
    if chat_room:
        db.add(ChatParticipant(room_id=chat_room.room_id, user_id=target_user.id))

    await db.commit()
    return {"status": "success", "message": f"'{target_user.name}' 직원이 초대되었습니다."}

@router.delete("/{facility_id}/remove-employee/{target_user_id}")
async def remove_employee(facility_id: int, target_user_id: int, user_id: int, db: AsyncSession = Depends(get_db)):
    """[앱 전용] 직원을 시설에서 퇴출 (채팅방 자동 퇴장 포함)"""
    actor = (await db.execute(select(User).where(User.id == user_id))).scalars().first()
    facility = (await db.execute(select(Facility).where(Facility.id == facility_id))).scalars().first()
    
    if not actor or not facility:
        raise HTTPException(status_code=404, detail="사용자 또는 시설을 찾을 수 없습니다.")

    role_str = str(actor.role).upper()
    is_admin = "ADMIN" in role_str or "DEVELOPER" in role_str
    is_user_admin = (getattr(facility, 'user_admin_id', None) == user_id)
    
    # 자기 자신은 나갈 수 있음, 타인은 관리 권한 필요
    if user_id != target_user_id and not is_admin and not is_user_admin:
        raise HTTPException(status_code=403, detail="직원을 퇴출시킬 권한이 없습니다.")
    
    if getattr(facility, 'user_admin_id', None) == target_user_id:
        facility.user_admin_id = None

    mapping = (await db.execute(select(FacilityUser).where(FacilityUser.facility_id == facility_id, FacilityUser.user_id == target_user_id))).scalars().first()
    if not mapping:
        raise HTTPException(status_code=404, detail="해당 직원이 시설에 존재하지 않습니다.")
        
    await db.delete(mapping)

    # 공식 채팅방 자동 퇴장
    chat_room = (await db.execute(select(ChatRoom).where(ChatRoom.facility_id == facility_id, ChatRoom.type == ChatRoomType.FACILITY))).scalars().first()
    if chat_room:
        participant = (await db.execute(select(ChatParticipant).where(ChatParticipant.room_id == chat_room.room_id, ChatParticipant.user_id == target_user_id))).scalars().first()
        if participant:
            await db.delete(participant)

    await db.commit()
    return {"status": "success", "message": "직원이 시설에서 제외되었습니다."}