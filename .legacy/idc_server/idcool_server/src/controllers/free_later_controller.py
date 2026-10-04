# ===============================================================
# 경로 : src/controllers/free_later_controller.py
# 명세 : 클라이언트 테스트를 위한 임시 권한 및 시설 정보 주입 컨트롤러 (향후 삭제 및 기능 이전 요구)
# ===============================================================
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from config.db import get_db

router = APIRouter(prefix="/api/test-auth", tags=["Test Auth"])



@router.get("/my-context/{user_id}")
async def get_my_context(user_id: int, db: AsyncSession = Depends(get_db)):
    # 1. 유저 정보 조회
    user_query = text("SELECT id, email, name, role FROM user_table WHERE id = :user_id")
    user_result = await db.execute(user_query, {"user_id": user_id})
    user = user_result.fetchone()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # 2. 시설 정보 조회 로직
    # 관리자(ADMIN, DEVELOPER)는 모든 시설에 접근 가능
    if user.role in ['ADMIN', 'DEVELOPER']:
        facility_query = text("SELECT id, name FROM facilities_table WHERE is_active = TRUE")
        facility_result = await db.execute(facility_query)
    else:
        # 일반 유저(USER)는 facility_users 매핑 테이블에 존재하는 시설만 접근 가능
        facility_query = text("""
            SELECT f.id, f.name 
            FROM facilities_table f
            JOIN facility_users fu ON f.id = fu.facility_id
            WHERE fu.user_id = :user_id AND f.is_active = TRUE
        """)
        facility_result = await db.execute(facility_query, {"user_id": user_id})
        
    facilities = [{"facility_id": row.id, "facility_name": row.name} for row in facility_result.fetchall()]

    return {
        "status": "success",
        "user": {
            "id": user.id,
            "email": user.email,
            "name": user.name,
            "role": user.role
        },
        "accessible_facilities": facilities,
        # 임시로 클라이언트가 기본으로 선택할 첫 번째 시설 ID 반환 (없으면 None)
        "default_facility_id": facilities[0]["facility_id"] if facilities else None
    }