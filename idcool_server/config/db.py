# config/db.py
from config.config import settings  # config.py에서 환경변수 로드
import psycopg2
from psycopg2.pool import SimpleConnectionPool
import sys

db_params = {
    "host": settings.DB_HOST,
    "database": settings.DB_NAME,
    "user": settings.DB_USER,
    "password": settings.DB_PASSWORD,
    "port": settings.DB_PORT
}

def create_pool():
    try:
        # 최소 1개, 최대 10개의 연결을 유지하는 풀 생성
        pool = SimpleConnectionPool(minconn=1, maxconn=10, **db_params)
        print("🚀 데이터베이스 커넥션 풀이 성공적으로 생성되었습니다.")
        return pool
    except psycopg2.OperationalError as e:
        print(f"❌ 데이터베이스 연결 실패. {e}")
        sys.exit(1)

# 이제 db 변수에는 단일 연결이 아니라 '풀(Pool)'이 담깁니다.
db_pool = create_pool()

# 서비스나 라우터에서 안전하게 연결을 꺼내고 반납할 수 있게 해주는 헬퍼 함수(컨텍스트 매니저)
from contextlib import contextmanager

@contextmanager
def get_db_connection():
    # 풀에서 연결 하나를 빌려옴
    connection = db_pool.getconn()
    try:
        yield connection
        connection.commit()  # 정상 종료 시 자동 커밋
    except Exception:
        connection.rollback()  # 에러 발생 시 자동 롤백
        raise
    finally:
        # 사용이 끝나면 반드시 풀에 다시 반납 (연결을 완전히 닫는 게 아님!)
        db_pool.putconn(connection)