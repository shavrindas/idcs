from pydantic import BaseModel
from datetime import datetime
from config.db import get_db_connection
import psycopg2.extras

class user_table(BaseModel):
    id: int
    email: str
    password: str
    name: str
    role: str
    phone_number: str
    created_at: datetime
    updated_at: datetime

def users_find_all():
    with get_db_connection() as conn:
        # 2. 커서(Cursor) 생성 (딕셔너리 형태로 결과를 받기 위해 DictCursor 사용 권장)
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cursor:
            try:
                # 3. RETURNING 구문을 포함한 INSERT 쿼리 작성
                query = """
                    SELECT * FROM user_table;
                """
                
                # 4. 쿼리 실행
                cursor.execute(query)
                
                rows = cursor.fetchall()

                reslist = []

                if not rows:
                    return None
                
                for row in rows:
                    reslist.append(
                        user_table(
                            id=row[0],
                            email=row[1],
                            password=row[2],
                            name=row[3],
                            role=row[4],
                            phone_number=row[5],
                            created_at=row[6],
                            updated_at=row[7]
                        )
                    )

                return reslist
                
            except Exception as e:
                # 에러 발생 시 get_db_connection 내부에서 자동으로 rollback 처리됩니다.
                print(f"DB 작업 중 오류 발생: {e}")
                return

def user_find_by_name(name: str):
    if not name:
        return

    # 1. 컨텍스트 매니저를 통해 커넥션 풀에서 연결을 빌려옴
    with get_db_connection() as conn:
        # 2. 커서(Cursor) 생성 (딕셔너리 형태로 결과를 받기 위해 DictCursor 사용 권장)
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cursor:
            try:
                # 3. RETURNING 구문을 포함한 INSERT 쿼리 작성
                query = """
                    SELECT * FROM user_table
                    WHERE name = %s;
                """
                
                # 4. 쿼리 실행
                cursor.execute(query, (name,))
                
                # 5. RETURNING으로 반환된 단일 행 결과
                result = cursor.fetchone()

                res = user_table(**dict(result))

                return res
                
            except Exception as e:
                # 에러 발생 시 get_db_connection 내부에서 자동으로 rollback 처리됩니다.
                print(f"DB 작업 중 오류 발생: {e}")
                return
            
def user_find_by_id(name: str):
    if not name:
        return

    # 1. 컨텍스트 매니저를 통해 커넥션 풀에서 연결을 빌려옴
    with get_db_connection() as conn:
        # 2. 커서(Cursor) 생성 (딕셔너리 형태로 결과를 받기 위해 DictCursor 사용 권장)
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cursor:
            try:
                # 3. RETURNING 구문을 포함한 INSERT 쿼리 작성
                query = """
                    SELECT * FROM user_table
                    WHERE id = %s;
                """
                
                # 4. 쿼리 실행
                cursor.execute(query, (name,))
                
                # 5. RETURNING으로 반환된 단일 행 결과
                result = cursor.fetchone()

                res = user_table(**dict(result))

                return res
                
            except Exception as e:
                # 에러 발생 시 get_db_connection 내부에서 자동으로 rollback 처리됩니다.
                print(f"DB 작업 중 오류 발생: {e}")
                return

def users_find_same_facility(facility_id: int):
    if not facility_id:
        return

    # 1. 컨텍스트 매니저를 통해 커넥션 풀에서 연결을 빌려옴
    with get_db_connection() as conn:
        # 2. 커서(Cursor) 생성 (딕셔너리 형태로 결과를 받기 위해 DictCursor 사용 권장)
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cursor:
            try:
                # 3. RETURNING 구문을 포함한 INSERT 쿼리 작성
                query = """
                    SELECT us.* FROM user_table us
                    INNER JOIN facility_users fu ON us.id = fu.user_id
                    WHERE fu.facility_id = %s;
                """
                
                # 4. 쿼리 실행
                cursor.execute(query, (facility_id,))
                
                rows = cursor.fetchall()

                reslist = []

                if not rows:
                    return None
                
                for row in rows:
                    reslist.append(
                        user_table(
                            id=row[0],
                            email=row[1],
                            password=row[2],
                            name=row[3],
                            role=row[4],
                            phone_number=row[5],
                            created_at=row[6],
                            updated_at=row[7]
                        )
                    )

                return reslist
                
            except Exception as e:
                # 에러 발생 시 get_db_connection 내부에서 자동으로 rollback 처리됩니다.
                print(f"DB 작업 중 오류 발생: {e}")
                return
            

