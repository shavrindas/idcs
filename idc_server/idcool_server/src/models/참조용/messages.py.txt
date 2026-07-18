from pydantic import BaseModel
from datetime import datetime
from idcool_server.config.db import get_db_connection  # 작성하신 db.py에서 가져옴
import psycopg2.extras

class messages(BaseModel):
    message_id: int
    room_id: int
    user_id: int
    message_type: str
    content: str
    created_at: datetime
    parent_message_id: int | None = None
    
class message_with_user(BaseModel):
    message_id: int
    room_id: int
    user_id: int
    user_name: str
    message_type: str
    content: str
    created_at: datetime
    parent_message_id: int | None = None

def messages_add(room_id: int, user_id: int, message_type: str, content: str, parent_message_id: int | None = None):
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cursor:
            try:
                # 3. RETURNING 구문을 포함한 INSERT 쿼리 작성
                query = """
                    INSERT INTO messages (room_id, user_id, message_type, content, parent_message_id)
                    VALUES (%s, %s, %s, %s, %s)
                    RETURNING *;
                """

                # 4. 쿼리 실행
                cursor.execute(query, (room_id, user_id, message_type, content, parent_message_id))

                # 5. RETURNING으로 반환된 단일 행 결과
                result = cursor.fetchone()

                if not result:
                    return None

                res = messages(**dict(result))

                return res

            except Exception as e:
                # 에러 발생 시 get_db_connection 내부에서 자동으로 rollback 처리됩니다.
                print(f"DB 작업 중 오류 발생: {e}")
                return None

def message_get_by_room(room_id: int):
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cursor:
            try:
                # 3. RETURNING 구문을 포함한 INSERT 쿼리 작성
                query = """
                    SELECT 
                        m.message_id AS message_id,
                        m.room_id, 
                        m.user_id, 
                        u.name AS user_name, -- 💡 유저 테이블에서 이름 가져오기
                        m.message_type, 
                        m.content, 
                        m.created_at, 
                        m.parent_message_id
                    FROM messages m
                    INNER JOIN user_table u ON m.user_id = u.id
                    WHERE m.room_id = %s 
                    ORDER BY m.created_at DESC;
                """

                # 4. 쿼리 실행
                cursor.execute(query, (room_id,))

                # 5. RETURNING으로 반환된 단일 행 결과
                rows = cursor.fetchall()

                reslist = []

                if not rows:
                    return None
                
                for row in rows:
                    reslist.append(
                        message_with_user(
                            message_id=row[0],
                            room_id=row[1],
                            user_id=row[2],
                            user_name=row[3],
                            message_type=row[4],
                            content=row[5],
                            created_at=row[6],
                            parent_message_id=row[7]
                        )
                    )

                return reslist

            except Exception as e:
                # 에러 발생 시 get_db_connection 내부에서 자동으로 rollback 처리됩니다.
                print(f"DB 작업 중 오류 발생: {e}")
                return None