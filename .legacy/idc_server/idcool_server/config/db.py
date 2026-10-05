# ===============================================================
# 경로 : src/config/db.py
# 명세 : 데이터베이스 연결 및 세션 관리 설정
# ===============================================================
import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base
# ===============================================================

# [Database configuration]
DB_CONFIG = {
    "dbname": "idcool_database_v01",
    "user": "dev",
    "password": "devkey1",
    "host": "idcool-database-v01",
    "port": "5432"
}

# ===============================================================

SQLALCHEMY_DATABASE_URL = f"postgresql+asyncpg://{DB_CONFIG['user']}:{DB_CONFIG['password']}@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['dbname']}"

DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    SQLALCHEMY_DATABASE_URL
)

# 비동기 엔진 생성
engine = create_async_engine(DATABASE_URL, echo=True)

# 세션 팩토리 생성
AsyncSessionLocal = sessionmaker(
    bind=engine, 
    class_=AsyncSession, 
    expire_on_commit=False
)

Base = declarative_base()

# FastAPI 의존성 주입을 위한 DB 세션 함수
async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()