# ===============================================================
# 경로 : src/controllers/alarm/alarm.py
# 명세 : 알람 관련 API 엔드포인트 정의
# ===============================================================

from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from fastapi import APIRouter, Depends, HTTPException
from config.db import get_db
from src.models.User import UserFcmToken
from src.models.Facility import  FacilityUser, Facility, FacilityRoom
from src.models.Monitoring import PointRole, Alarm

router = APIRouter(prefix="/alarms", tags=["Alarms"])

class RegistTokenRequest(BaseModel):
    fcm_token: str
    user_id: int

@router.post('/register')
async def registToken(user_in: RegistTokenRequest, db: AsyncSession = Depends(get_db)):
    """Box #1: FCM 토큰 등록 (비동기 처리)"""
    
    # 1. 중복 등록 확인
    mapping_result = await db.execute(
        select(UserFcmToken).where(UserFcmToken.fcm_token == user_in.fcm_token)
    )
    existing_token = mapping_result.scalars().first()

    # 이미 동일한 토큰이 등록된 경우
    if existing_token:
        # 소유 유저가 바뀌었을 가능성이 있으므로 user_id 업데이트 후 저장
        if existing_token.user_id != user_in.user_id:
            existing_token.user_id = user_in.user_id
            await db.commit()
            return {"message": "기존 토큰의 사용자 정보가 갱신되었습니다.", "user_id": user_in.user_id}
        
        return {"message": "이미 등록된 토큰입니다.", "user_id": user_in.user_id}

    new_token = UserFcmToken(
        fcm_token=user_in.fcm_token, 
        user_id=user_in.user_id
    )
    
    db.add(new_token)
    await db.commit()

    return {"message": "토큰이 성공적으로 등록되었습니다.", "user_id": new_token.user_id}



@router.get("/{user_id}")
async def get_alarms_for_user(user_id: int, db: AsyncSession = Depends(get_db)):
    stmt = (
        select(
            Alarm, 
            PointRole.facility_id, 
            Facility.name.label("facility_name"), 
            FacilityRoom.id.label("room_id"), 
            FacilityRoom.name.label("room_name")
        )
        .join(PointRole, Alarm.role_id == PointRole.id)
        .join(FacilityUser, FacilityUser.facility_id == PointRole.facility_id)
        .join(Facility, Facility.id == FacilityUser.facility_id)
        .join(FacilityRoom, PointRole.room_id == FacilityRoom.id)
        .where(
            FacilityUser.user_id == user_id,
            PointRole.is_current == True
        )
        .order_by(Alarm.timestamp.desc())
    )

    result = await db.execute(stmt)
    rows = result.all()

    alarms_with_facility = []
    for alarm, facility_id, facility_name, room_id, room_name in rows:
        alarm_dict = {
            column.name: getattr(alarm, column.name)
            for column in alarm.__table__.columns
        }
        alarm_dict.update({
            'facility_id': facility_id,
            'facility_name': facility_name,
            'room_id': room_id,
            'room_name': room_name
        })
        alarms_with_facility.append(alarm_dict)

    return {'alarms': alarms_with_facility}


@router.get("/facility/{facility_id}")
async def get_alarms_for_facility(facility_id: int, db: AsyncSession = Depends(get_db)):
    stmt = (
        select(
            Alarm, 
            PointRole.facility_id, 
            Facility.name.label("facility_name"), 
            FacilityRoom.id.label("room_id"), 
            FacilityRoom.name.label("room_name")
        )
        .join(PointRole, Alarm.role_id == PointRole.id)
        .join(Facility, Facility.id == PointRole.facility_id)
        .join(FacilityRoom, PointRole.room_id == FacilityRoom.id)
        .where(
            PointRole.facility_id == facility_id,
            PointRole.is_current == True
        )
        .order_by(Alarm.timestamp.desc())
    )

    result = await db.execute(stmt)
    rows = result.all()

    alarms_with_facility = []
    for alarm, fac_id, facility_name, room_id, room_name in rows:
        alarm_dict = {
            column.name: getattr(alarm, column.name)
            for column in alarm.__table__.columns
        }
        alarm_dict.update({
            'facility_id': fac_id,
            'facility_name': facility_name,
            'room_id': room_id,
            'room_name': room_name
        })
        alarms_with_facility.append(alarm_dict)

    return {'alarms': alarms_with_facility}