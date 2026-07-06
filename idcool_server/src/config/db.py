# config/db.py
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# 제공해주신 DB 연결 정보 기반 설정
DB_CONFIG = {
    "dbname": "idcool_database_v01",
    "user": "dev",
    "password": "devkey1",
    "host": "127.0.0.1",
    "port": "5433"
}

# SQLAlchemy 연결 문자열 생성
SQLALCHEMY_DATABASE_URL = f"postgresql://{DB_CONFIG['user']}:{DB_CONFIG['password']}@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['dbname']}"

# 엔진 생성
engine = create_engine(SQLALCHEMY_DATABASE_URL)

# 세션 로컬 설정
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# ORM 모델을 위한 베이스 클래스
Base = declarative_base()

# 의존성 주입을 위한 DB 세션 함수
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()