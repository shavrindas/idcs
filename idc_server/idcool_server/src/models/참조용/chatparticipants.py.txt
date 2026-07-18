from pydantic import BaseModel
from datetime import datetime
from fastapi import HTTPException
from idcool_server.config.db import get_db_connection  # 작성하신 db.py에서 가져옴
import psycopg2.extras

class chatparticipants(BaseModel):
    participant_id: int
    room_id: int
    user_id: int
    joined_at: datetime
    last_read_message_id: int
    unread_count: int

def chatpartadd(user_id: int, room_id: int):
    if not user_id or not room_id:
        return None

    # 1. 컨텍스트 매니저를 통해 커넥션 풀에서 연결을 빌려옴
    with get_db_connection() as conn:
        # 2. 커서(Cursor) 생성 (딕셔너리 형태로 결과를 받기 위해 DictCursor 사용 권장)
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cursor:
            try:
                # 3. RETURNING 구문을 포함한 INSERT 쿼리 작성
                query = """
                    INSERT INTO chatparticipants (user_id, room_id)
                    VALUES (%s, %s)
                    RETURNING *;
                """
                
                # 4. 쿼리 실행
                cursor.execute(query, (user_id, room_id))
                
                # 5. RETURNING으로 반환된 단일 행 결과
                result = cursor.fetchone()

                if not result:
                    return None
                
                res = chatparticipants(**dict(result))

                return res
                
            except Exception as e:
                # 에러 발생 시 get_db_connection 내부에서 자동으로 rollback 처리됩니다.
                print(f"DB 작업 중 오류 발생: {e}")
                return None
            

def chatpartadds(user_ids: list[int], room_id: int):
    if not user_ids or not room_id:
        return None

    data_to_insert = [(user_id, room_id) for user_id in user_ids]


    # 1. 컨텍스트 매니저를 통해 커넥션 풀에서 연결을 빌려옴
    with get_db_connection() as conn:
        # 2. 커서(Cursor) 생성 (딕셔너리 형태로 결과를 받기 위해 DictCursor 사용 권장)
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cursor:
            try:
                # 3. RETURNING 구문을 포함한 INSERT 쿼리 작성
                query = """
                    INSERT INTO chatparticipants (user_id, room_id)
                    VALUES %s;
                """
                
                # 4. 쿼리 실행
                psycopg2.extras.execute_values(cursor, query, data_to_insert)

                return "Success"
                
            except Exception as e:
                # 에러 발생 시 get_db_connection 내부에서 자동으로 rollback 처리됩니다.
                print(f"DB 작업 중 오류 발생: {e}")
                return None