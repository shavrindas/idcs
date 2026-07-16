# ===============================================================
# 경로 : src/app_debug_list.py
# 명세 : 디버그용 라우터 모듈
# ===============================================================
from fastapi import APIRouter, Depends
from config.db import get_db
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
# ===============================================================

router = APIRouter()

# ===============================================================
# ─── DB 연결 테스트용 라우트 추가 ───
# ===============================================================

@router.get("/db-test")
async def test_db_connection(db: AsyncSession = Depends(get_db)):
    try:
        # PostgreSQL 서버의 현재 시간을 구하는 쿼리 실행
        result = await db.execute(text("SELECT NOW();"))
        db_time = result.scalar()
        return {
            "status": "success",
            "message": "211.55.127.239 DB에 성공적으로 연결되었습니다.",
            "db_current_time": db_time
        }
    except Exception as e:
        return {
            "status": "error",
            "message": "DB 연결 실패",
            "details": str(e)
        }


