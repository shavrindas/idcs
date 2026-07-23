
from typing import Dict
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from fastapi import Depends
from config.db import get_db
from src.models.User import UserFcmToken
from src.models.Facility import FacilityUser, PointRole
import time
import src.firebase as msg

#캐시 시간
CACHE_TTL = 300

role_cache: dict[int, list] = {}
alarm_downed: Dict[int, list[int]] = {}

def invalidate_role_cache(facility_id: int):
    role_cache.pop(facility_id, None)

def init(facility_id: int):
    alarm_downed[facility_id] = []

def destroy(facility_id: int):
    if facility_id in alarm_downed:
        del alarm_downed[facility_id]


async def scan_roles(facility_id: int, db: AsyncSession = Depends(get_db)):
    now = time.time()
    cache_entry = role_cache.get(facility_id)
    if not cache_entry or (now - cache_entry["updated_at"] > CACHE_TTL):
        async for db in get_db():
            role_result = await db.execute(
                select(PointRole).where(PointRole.facility_id == facility_id)
            )
            role_cache[facility_id] = {
                "roles": role_result.scalars().all(),
                "updated_at": now
            }
            print(f"[DB 갱신] Facility {facility_id} PointRole 캐시 업데이트 완료")
            break
        
    roles = role_cache[facility_id]["roles"]
    return roles

async def check_roles(facility_id: int, data_dict: Dict[str, str], roles):
    tokens:list[str] = []
    armlist: list[str] = []
    new_alarm_triggered = False

    # 1. 반복문 내에서는 알람 대상 조건 검사 및 상태 업데이트만 진행
    for role in roles:
        for k, v in data_dict.items():
            if role.role_name in k:
                val = float(v)
                is_out_of_bounds = val <= float(role.target_low_limit) or val >= float(role.target_high_limit)
                
                if is_out_of_bounds:
                    if k not in alarm_downed[facility_id]:
                        alarm_downed[facility_id].append(k)
                        armlist.append(k)
                        new_alarm_triggered = True  # 신규 알람 발생 플래그
                else:
                    if k in alarm_downed[facility_id]:
                        alarm_downed[facility_id].remove(k)
    
    # 2. 신규 알람이 발생했을 때만 DB에서 FCM 토큰을 '단 1회' 조회 (JOIN 활용)
    if new_alarm_triggered:
        # db: AsyncSession 매개변수로 받아온 세션 객체를 그대로 사용한다고 가정
                
        async for db in get_db():
            result = await db.execute(
                select(UserFcmToken.fcm_token)
                    .join(FacilityUser, FacilityUser.user_id == UserFcmToken.user_id)
                    .where(FacilityUser.facility_id == facility_id)
                    .distinct())
            break
    
        tokens = list(result.scalars().all())

    # 3. 토큰이 존재할 때만 푸시 전송
    if tokens:
        await msg.send_multicast_fcm(tokens, "알람", "\n".join(armlist) + "\n이상 발생")