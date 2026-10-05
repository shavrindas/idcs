# ===============================================================
# 경로 : src/controllers/facility/facility_controller.py
# 명세 : 시설 관련 API 엔드포인트 정의
# ===============================================================
from operator import or_

from pydantic import BaseModel
from typing import List, Optional, Dict
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from fastapi import APIRouter, Depends, HTTPException, status, WebSocket, WebSocketDisconnect
from config.db import get_db
from src.models.User import User, UserRole
from src.models.Facility import Facility, FacilityUser, FacilityRoom
from src.models.Monitoring import PointRole, RemoteControlLog, BoolLog, TemperatureNumericalLog, EquipmentStaticLog
from src.models.Chat import ChatRoom, ChatParticipant
import src.services.alarm as alarm_services
import json
import re
from datetime import datetime, timezone

router = APIRouter(prefix="/facilities", tags=["Facilities"])

class RegisterFacilityRequest(BaseModel):
    access_code: str

@router.get("/{user_id}", status_code=status.HTTP_200_OK)
async def get_user_facilities(user_id: int, db: AsyncSession = Depends(get_db)):
    """메인 색인 페이지 Box #2 및 시설 등록 페이지 Box #3용 시설 목록 조회"""
    # 1. 유저 권한 확인
    user_result = await db.execute(select(User).where(User.id == user_id))
    user = user_result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

    # 2. 권한별 시설 목록 반환
    if user.role in [UserRole.ADMIN, UserRole.DEVELOPER]:
        # 관리자/개발자: 모든 활성 시설 조회
        facilities_result = await db.execute(select(Facility).where(Facility.is_active == True))
        facilities = facilities_result.scalars().all()
    else:
        # 일반 유저: 매핑 테이블(facility_users)에 등록된 시설만 조회 (JOIN 대체 로직)
        mapping_result = await db.execute(select(FacilityUser.facility_id).where(FacilityUser.user_id == user_id))
        facility_ids = mapping_result.scalars().all()
        
        if not facility_ids:
            return {"facilities": []}
            
        facilities_result = await db.execute(select(Facility).where(Facility.id.in_(facility_ids), Facility.is_active == True))
        facilities = facilities_result.scalars().all()

    return {
        "facilities": [
            {"id": f.id, "name": f.name, "access_code": f.access_code} 
            for f in facilities
        ]
    }

@router.post("/{user_id}/register", status_code=status.HTTP_200_OK)
async def register_facility(user_id: int, req: RegisterFacilityRequest, db: AsyncSession = Depends(get_db)):
    """Box #2: 시설 접근 코드로 시설 등록"""
    # 1. 접근 코드로 시설 찾기
    fac_result = await db.execute(select(Facility).where(Facility.access_code == req.access_code, Facility.is_active == True))
    facility = fac_result.scalars().first()
    
    if not facility:
        raise HTTPException(status_code=404, detail="유효하지 않거나 비활성화된 접근 코드입니다.")

    # 2. 중복 등록 확인
    mapping_result = await db.execute(
        select(FacilityUser).where(FacilityUser.facility_id == facility.id, FacilityUser.user_id == user_id)
    )
    if mapping_result.scalars().first():
        raise HTTPException(status_code=400, detail="이미 등록된 시설입니다.")

    # 3. 매핑 추가
    new_mapping = FacilityUser(facility_id=facility.id, user_id=user_id)
    db.add(new_mapping)
    await db.commit()

    # 4. 해당하는 채팅방 가져오기
    #chatroom_result = await db.excute(select(ChatRoom).where(ChatRoom.facility_id == facility.id))

    # 5. 유저 채팅방 입장
    

    new_mapping = ChatRoom(facility_id=facility.id, user_id=user_id)
    db.add(new_mapping)
    await db.commit()


    return {"message": "시설이 성공적으로 등록되었습니다.", "facility_name": facility.name}

@router.delete("/{user_id}/unlink/{facility_id}", status_code=status.HTTP_200_OK)
async def unlink_facility(user_id: int, facility_id: int, db: AsyncSession = Depends(get_db)):
    """Box #3: 시설 연동 해제"""
    mapping_result = await db.execute(
        select(FacilityUser).where(FacilityUser.facility_id == facility_id, FacilityUser.user_id == user_id)
    )
    mapping = mapping_result.scalars().first()
    
    if not mapping:
        raise HTTPException(status_code=404, detail="해당 시설에 등록되어 있지 않습니다.")

    await db.delete(mapping)
    await db.commit()
    return {"message": "시설 연동이 해제되었습니다."}

#특정 시설의 방 목록 조회하기
@router.get("/rooms/{facility_id}")
async def get_facility_rooms(facility_id: int, db: AsyncSession = Depends(get_db)):
    room_result = await db.execute(
        select(FacilityRoom).where(FacilityRoom.facility_id == facility_id)
    )
    rooms = room_result.scalars().all()

    return {
        "rooms": [
            {"id": r.id, "name": r.name}
            for r in rooms
        ]
    }

#서버-시설 간 연결 관리 및 브로드캐스팅
set_sockets: Dict[int, WebSocket] = {}
get_sockets: Dict[int, List[WebSocket]] = {}
allget_sockets: Dict[int, List[WebSocket]] = {}

#서버-시설 간 연결 관리 및 브로드캐스팅
@router.websocket("/data/set/{facility_id}")
async def set_facility_data(websocket: WebSocket, facility_id: int):
    if facility_id in set_sockets:
        await websocket.accept()
        await websocket.close(
            code=status.WS_1008_POLICY_VIOLATION, 
            reason="This facility is already sending data from another device."
        )
        return

    await websocket.accept()
    set_sockets[facility_id] = websocket

    print(f"[장비 연결 성공] Facility {facility_id} 데이터 수신 시작")

    try:
        while True:
            data = await websocket.receive_text()
            #print(data)

            data_dict = json.loads(data)

            if "time" in data_dict:
                bool_logs = []
                real_logs = []
                static_logs = []
                roles = await alarm_services.scan_roles_asc_name(facility_id)
                #print(roles)
                #print(f"현재시간: {datetime.strptime(data_dict["time"], "%Y-%m-%d %H:%M:%S")}")

                dt_object = datetime.strptime(data_dict["time"], "%Y-%m-%d %H:%M:%S")

                for datakey, labled_dict in data_dict.items():
                    try:
                        json_dict = json.loads(labled_dict) if isinstance(labled_dict, str) else labled_dict
                    except json.JSONDecodeError:
                        continue

                    for label, values in json_dict.items():
                        if label in roles:
                            role_obj = roles[label]

                            #print(f"✅ 매칭 성공! 라벨: {label} | 롤 정보: {values}")

                            if datakey == "bool":
                                bool_logs.append(BoolLog(
                                    role_id=role_obj.id,
                                    timestamp=dt_object,
                                    status_value=values.get("last_value")
                                ))
                            elif datakey == "real":
                                real_logs.append(TemperatureNumericalLog(
                                    role_id = role_obj.id,
                                    timestamp = dt_object,
                                    temp_min = values.get("val_min"),
                                    temp_max = values.get("val_max"),
                                    temp_mean = values.get("val_mean"),
                                    temp_stdev = values.get("val_std"),
                                    sample_count = values.get("count")
                                ))
                            elif datakey == "real_static":
                                static_logs.append(EquipmentStaticLog(
                                    role_id=role_obj.id,
                                    timestamp=dt_object,
                                    setnum=values.get("last_value")
                                ))
                        else:
                            pass
                
                async for db in get_db():
                    iscommit = False
                    if bool_logs:
                        db.add_all(bool_logs)
                        iscommit = True
                    if real_logs:
                        db.add_all(real_logs)
                        iscommit = True
                    if static_logs:
                        db.add_all(static_logs)
                        iscommit = True
                    if iscommit:
                        await db.commit()
                    
                    break

            # --- [2. 모니터링 & 브로드캐스팅 로직] ---
            if "datas" in data_dict:
                # 역할 스캔 및 알람 확인
                roles = await alarm_services.scan_roles(facility_id)
                await alarm_services.check_roles(facility_id, data_dict["datas"], roles)

                # 상세 모니터링 출력 (원본 데이터 전체 전송)
                if facility_id in get_sockets:
                    for client in get_sockets[facility_id][:]:
                        try:
                            await client.send_text(data)
                        except Exception:
                            if client in get_sockets[facility_id]:
                                get_sockets[facility_id].remove(client)
                
                # 💡 개괄 모니터링 전용 데이터 필터링 로직
                raw_datas = data_dict["datas"]
                filtered_datas = {}

                # 특정 키워드가 포함된 키만 선별 (예: "25.temp_pv" -> "temp_pv" 포함 여부 확인)
                if isinstance(raw_datas, dict):
                    for key, val in raw_datas.items():
                        if any(keyword in key for keyword in ["temp_pv"]):
                            filtered_datas[key] = val

                # 💡 필터링된 결과가 존재할 때만 브로드캐스트용 JSON 구성
                if filtered_datas:
                    filtered_payload = json.dumps({
                        "facility_id": facility_id,  # 개괄 모니터링 식별용 ID
                        "datas": filtered_datas
                    })

                    async for db in get_db():
                        # 💡 해당 시설에 매핑된 유저 OR 역할(role)이 ADMIN인 모든 유저 조회
                        stmt = (
                            select(User.id)
                            .outerjoin(FacilityUser, User.id == FacilityUser.user_id)
                            .where(
                                or_(
                                    FacilityUser.facility_id == facility_id,
                                    User.role == UserRole.ADMIN
                                )
                            )
                            .distinct()  # 중복 ID 방지
                        )
                        result = await db.execute(stmt)
                        target_user_ids = result.scalars().all()

                        for user_id in target_user_ids:
                            if user_id in allget_sockets:
                                for client in allget_sockets[user_id][:]:
                                    try:
                                        await client.send_text(filtered_payload)
                                    except Exception:
                                        if client in allget_sockets[user_id]:
                                            allget_sockets[user_id].remove(client)
                        break

            if "status" in data_dict.keys():
                if "SUCCESS" in data_dict["status"]:
                    datas = re.split(r"[.]", data_dict["request_id"])
                    print(datas)

                    async for db in get_db():
                        stmt = select(PointRole.id).where(PointRole.role_name == datas[1]).where(PointRole.room_id == int(datas[0]))

                        result = await db.execute(stmt)

                        role_id = result.scalars().first()

                        if not role_id:
                            print(f"⚠️ [로그 저장 실패] 매칭되는 PointRole을 찾을 수 없습니다. (room_id: {datas[0]}, role_name: {datas[1]})")
                            # 필요하다면 여기서 에러 응답을 리턴하거나 로직을 중단합니다.
                            break

                        now_time = datetime.now(timezone.utc)

                        new_log = RemoteControlLog(
                            role_id = role_id,
                            control_value=data_dict["request_val"],
                            timestamp=now_time
                        )

                        db.add(new_log)
                        await db.commit()

                        break
                        

    except WebSocketDisconnect:
        print(f"[장비 연결 종료] Facility {facility_id} 수신 중지")
        if facility_id in set_sockets and set_sockets[facility_id] == websocket:
            del set_sockets[facility_id]

#서버-앱 간 연결 관리
@router.websocket("/data/get/{facility_id}")
async def get_facility_data(websocket: WebSocket, facility_id: int):
    print("접속 시도", facility_id)
    await websocket.accept()
    
    if facility_id not in get_sockets:
        get_sockets[facility_id] = []
    get_sockets[facility_id].append(websocket)
    print(f"[앱 연결 성공] Facility {facility_id} 모니터링 시작 (현재 접속자: {len(get_sockets[facility_id])}명)")

    try:
        while True:
            recv = await websocket.receive_text()

            if recv:
                await set_sockets[facility_id].send_text(recv)
            
    except WebSocketDisconnect:
        print(f"[앱 연결 종료] Facility {facility_id} 모니터링 중지")
        if facility_id in get_sockets and websocket in get_sockets[facility_id]:
            get_sockets[facility_id].remove(websocket)
            if not get_sockets[facility_id]:
                del get_sockets[facility_id]

#개괄 모니터링 관리
@router.websocket("/data/allget/{user_id}")
async def allget_facility_data(websocket: WebSocket, user_id: int):
    print("접속 시도", user_id)
    await websocket.accept()
    
    if user_id not in allget_sockets:
        allget_sockets[user_id] = []
    allget_sockets[user_id].append(websocket)
    print(f"[앱 연결 성공] Facility {user_id} 개괄 모니터링 시작 (현재 접속자: {len(allget_sockets[user_id])}명)")

    try:
        while True:
            recv = await websocket.receive_text()

            if recv:
                await set_sockets[user_id].send_text(recv)
            
    except WebSocketDisconnect:
        print(f"[앱 연결 종료] Facility {user_id} 모니터링 중지")
        if user_id in allget_sockets and websocket in allget_sockets[user_id]:
            allget_sockets[user_id].remove(websocket)
            if not allget_sockets[user_id]:
                del allget_sockets[user_id]