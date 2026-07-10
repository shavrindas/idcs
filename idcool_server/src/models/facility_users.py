from pydantic import BaseModel
from datetime import datetime
from config.db import get_db_connection  # 작성하신 db.py에서 가져옴
import psycopg2.extras

class facility_users(BaseModel):
    id: int
    facility_id: int
    user_id: int
    created_at: datetime

def facility_users_get_by_user(user_id: int):
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cursor:
            try:
                # 3. RETURNING 구문을 포함한 INSERT 쿼리 작성
                query = """
                    SELECT 
                        fu.id,
                        fu.user_id, 
                        fu.facility_id,
                        fu.created_at
                    FROM facility_users fu
                    INNER JOIN user_table u ON fu.user_id = u.id
                    WHERE fu.user_id = %s 
                    ORDER BY m.created_at DESC;
                """

                # 4. 쿼리 실행
                cursor.execute(query, (user_id,))

                # 5. RETURNING으로 반환된 단일 행 결과
                rows = cursor.fetchall()

                reslist = []

                if not rows:
                    return None
                
                for row in rows:
                    reslist.append(
                        facility_users(
                            id=row[0],
                            facility_id=row[1],
                            user_id=row[2],
                            created_at=row[3]
                        )
                    )

                return reslist

            except Exception as e:
                # 에러 발생 시 get_db_connection 내부에서 자동으로 rollback 처리됩니다.
                print(f"DB 작업 중 오류 발생: {e}")
                return None