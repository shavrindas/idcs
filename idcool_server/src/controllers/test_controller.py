# controllers/test_controller.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
# 수정: 앞에 src. 을 붙입니다.
from src.config.db import get_db

router = APIRouter()

@router.get("/db-test")
def test_db_connection(db: Session = Depends(get_db)):
    try:
        # 간단한 SQL 실행으로 연결 확인
        result = db.execute(text("SELECT 1")).scalar()
        
        # 실제 user_table 데이터 개수 확인 (테이블 존재 여부 확인용)
        user_count = db.execute(text("SELECT COUNT(*) FROM user_table")).scalar()
        
        return {
            "status": "success",
            "db_connection": "connected",
            "test_query_result": result,
            "user_table_count": user_count
        }
    except Exception as e:
        return {
            "status": "error",
            "message": str(e)
        }