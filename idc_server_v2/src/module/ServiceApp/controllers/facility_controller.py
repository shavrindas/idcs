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
from src.module.Core.models.Monitoring import PointRole

router = APIRouter(prefix="/facilities", tags=["ServiceApp - Facility"])

class RegisterFacilityReq(BaseModel):
    access_code: str

@router.get("/{user_id}")
async def get_user_facilities(user_id: int, db: AsyncSession = Depends(get_db)):
    """유저가 소속된 시설 목록 조회 (관리자는 전체 조회)"""
    
    # 1. 유저 권한 확인
    user = (await db.execute(select(User).where(User.id == user_id))).scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

    # 2. 권한에 따른 조회 쿼리 분기
    if user.role in [UserRole.ADMIN, UserRole.DEVELOPER]:
        # 관리자는 매핑 관계없이 활성화된 모든 시설 조회
        stmt = select(Facility).where(Facility.is_active == True)
    else:
        # 일반 유저는 자신에게 매핑된 시설만 조회
        stmt = (
            select(Facility)
            .join(FacilityUser, Facility.id == FacilityUser.facility_id)
            .where(FacilityUser.user_id == user_id, Facility.is_active == True)
        )
        
    result = await db.execute(stmt)
    facilities = result.scalars().all()
    
    return {
        "facilities": [
            {"id": f.id, "name": f.name, "start_date": f.start_date, "end_date": f.end_date}
            for f in facilities
        ]
    }

@router.get("/{room_id}/room_roles")
async def get_facility_roles(room_id: int, db: AsyncSession = Depends(get_db)):
    '''해당 호실의 포인트 롤 목록 확인'''
    result = await db.execute(select(PointRole).where(PointRole.room_id == room_id))
    if not result:
        raise HTTPException(status_code=404, detail="호실에 배정된 역할을 찾을 수 없습니다.")

    roles = result.scalars().all()

    return {
        "roles": [
            {"id": r.id, "facility_id": r.facility_id, "role_name": r.role_name}
            for r in roles
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

@router.delete("/{user_id}/unlink/{facility_id}")
async def unlink_facility(user_id: int, facility_id: int, db: AsyncSession = Depends(get_db)):
    """시설 연결 해제"""
    result = await db.execute(
        select(FacilityUser).where(FacilityUser.user_id == user_id, FacilityUser.facility_id == facility_id)
    )
    mapping = result.scalars().first()
    
    if not mapping:
        raise HTTPException(status_code=404, detail="해당 시설에 등록되어 있지 않습니다.")
        
    await db.delete(mapping)
    await db.commit()
    return {"message": "시설 등록이 해제되었습니다."}

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

        if role == UserRole.ADMIN:
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