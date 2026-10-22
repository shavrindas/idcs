# ===============================================================
# 경로 : src/module/ServiceWeb/controllers/facility/scope.py
# 명세 : 웹 사용자가 볼 수 있는 시설 범위 계산
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
    Facility ids this user may see in the web console.

    Returns None for DEVELOPER (system operators see every facility).
    ADMIN is a company-side administrator, so like USER it is limited to the
    facilities it is linked to through facility_users — otherwise an admin of
    one company would see every other company's warehouses.
    """
    user = await get_user_or_404(db, user_id)
    if user.role == UserRole.DEVELOPER:
        return None
    rows = await db.execute(select(FacilityUser.facility_id).where(FacilityUser.user_id == user_id))
    return set(rows.scalars().all())
