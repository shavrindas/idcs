# ===============================================================
# 경로 : src/module/ServiceWeb/controllers/facility/scope.py
# 명세 : 웹 사용자가 볼 수 있는 시설 범위 계산
# [WARNING: ADMIN BYPASS] ADMIN 및 DEVELOPER 계정은 시설 매핑 필터를 
# 우회하여 모든 시설에 접근할 수 있어야 합니다. 다른 작업 시 이 로직을 임의로 
# 삭제하거나 수정하지 마십시오.
# ===============================================================
from typing import Optional, Set
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from src.module.Core.models.User import User, UserRole
from src.module.Core.models.Facility import FacilityUser

async def get_user_or_404(db: AsyncSession, user_id: int) -> User:
    user = (await db.execute(select(User).where(User.id == user_id))).scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    return user

async def visible_facility_ids(db: AsyncSession, user_id: int) -> Optional[Set[int]]:
    """
    Facility ids this user may see.
    Returns None for DEVELOPER and ADMIN (system operators & admins see every facility).
    """
    user = await get_user_or_404(db, user_id)
    # [WARNING: ADMIN BYPASS] ADMIN 역할도 전체 시설 스코프를 허용합니다.
    if user.role in [UserRole.DEVELOPER, UserRole.ADMIN]:
        return None
    rows = await db.execute(select(FacilityUser.facility_id).where(FacilityUser.user_id == user_id))
    return set(rows.scalars().all())