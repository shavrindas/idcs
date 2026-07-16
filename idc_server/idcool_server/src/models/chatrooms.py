from pydantic import BaseModel
from datetime import datetime
from fastapi import HTTPException
from idcool_server.config.db import get_db_connection  # 작성하신 db.py에서 가져옴
import psycopg2.extras

class chatrooms(BaseModel):
    room_id: int
    room_name: str
    type: str
    created_at: datetime

def chatroomadd(room_name: str, room_type: str):
    if not room_name or not room_type:
        return None

    # 1. 컨텍스트 매니저를 통해 커넥션 풀에서 연결을 빌려옴
    with get_db_connection() as conn:
        # 2. 커서(Cursor) 생성 (딕셔너리 형태로 결과를 받기 위해 DictCursor 사용 권장)
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cursor:
            try:
                # 3. RETURNING 구문을 포함한 INSERT 쿼리 작성
                query = """
                    INSERT INTO chatrooms (room_name, type)
                    VALUES (%s, %s)
                    RETURNING *;
                """
                
                # 4. 쿼리 실행
                cursor.execute(query, (room_name, room_type))
                
                # 5. RETURNING으로 반환된 단일 행 결과
                result = cursor.fetchone()

                if not result:
                    return None
                
                res = chatrooms(**dict(result))

                return res
                
            except Exception as e:
                # 에러 발생 시 get_db_connection 내부에서 자동으로 rollback 처리됩니다.
                print(f"DB 작업 중 오류 발생: {e}")
                return None

def chatrooms_get_by_user(user_id: int):
    if not user_id:
        return None

    # 1. 컨텍스트 매니저를 통해 커넥션 풀에서 연결을 빌려옴
    with get_db_connection() as conn:
        # 2. 커서(Cursor) 생성 (딕셔너리 형태로 결과를 받기 위해 DictCursor 사용 권장)
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cursor:
            try:
                # 3. RETURNING 구문을 포함한 INSERT 쿼리 작성
                query = """
                    SELECT cr.* FROM chatrooms cr
                    INNER JOIN chatparticipants cp ON cr.room_id = cp.room_id
                    WHERE cp.user_id = %s;
                """
                
                # 4. 쿼리 실행
                cursor.execute(query, (user_id,))
                
                #
                rows = cursor.fetchall()

                reslist = []

                if not rows:
                    return None
                
                for row in rows:
                    reslist.append(
                        chatrooms(
                            room_id=row[0],
                            room_name=row[1],
                            type=row[2],
                            created_at=row[3]
                        )
                    )

                return reslist
                
            except Exception as e:
                # 에러 발생 시 get_db_connection 내부에서 자동으로 rollback 처리됩니다.
                print(f"DB 작업 중 오류 발생: {e}")
                return None