# ===============================================================
# 경로 : src/module/ServiceWeb/controllers/facility_controller.py
# 명세 : 시설 관련 API 엔드포인트 정의
# ===============================================================
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
from src.module.Core.models.User import User, UserRole
from src.config.database import get_db
from src.module.Core.models.Facility import Facility, FacilityUser, FacilityRoom
from src.module.ServiceWeb.controllers.facility.scope import visible_facility_ids

router = APIRouter(prefix="/facilities", tags=["ServiceApp - Facility"])

class RegisterFacilityReq(BaseModel):
    access_code: str

@router.get("/{user_id}")
async def get_user_facilities(user_id: int, db: AsyncSession = Depends(get_db)):
    """유저가 소속된 시설 목록 조회 (개발자만 전체 조회)"""

    # ADMIN is scoped to its own company's facilities; only DEVELOPER sees all.
    allowed = await visible_facility_ids(db, user_id)
    stmt = select(Facility).where(Facility.is_active == True).order_by(Facility.id.asc())
    if allowed is not None:
        stmt = stmt.where(Facility.id.in_(allowed))

    result = await db.execute(stmt)
    facilities = result.scalars().all()
    
    return {
        "facilities": [
            {"id": f.id, "name": f.name, "start_date": f.start_date, "end_date": f.end_date}
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