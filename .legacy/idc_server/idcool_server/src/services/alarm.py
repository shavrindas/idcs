
from typing import Dict, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import or_
from fastapi import Depends
from config.db import get_db
from src.models.User import UserFcmToken, User, UserRole
from src.models.Facility import FacilityUser, Facility
from src.models.Monitoring import PointRole, Alarm
import time
from datetime import datetime, timedelta, timezone
import src.firebase as msg
import src.services.alarmnamemap as AMM

#캐시 시간
CACHE_TTL = 300

role_cache: dict[int, list] = {}

def invalidate_role_cache(facility_id: int):
    role_cache.pop(f"{facility_id}_list", None)
    role_cache.pop(f"{facility_id}_dict", None)


# 2단계: 기존 리스트 형태의 함수 (캐시 키에 _list 추가)
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
            #print(f"[DB 갱신] Facility {facility_id} PointRole 캐시 업데이트 완료")
            break
        
    roles = role_cache[facility_id]["roles"]
    return roles


# 3단계: 딕셔너리 형태의 함수 (캐시 키에 _dict 추가)
async def scan_roles_asc_name(facility_id: int, db: AsyncSession = Depends(get_db)):
    now = time.time()
    cache_key = f"{facility_id}_dict" # 🟢 키 분리
    cache_entry = role_cache.get(cache_key)
    
    if (not cache_entry or 
        (now - cache_entry["updated_at"] > CACHE_TTL)):
        
        async for db in get_db():
            role_result = await db.execute(
                select(PointRole).where(PointRole.facility_id == facility_id)
            )
            
        raw_roles = role_result.scalars().all()
        
        sorted_roles = sorted(
            raw_roles, 
            key=lambda x: f"{x.room_id}.{x.role_name}"
        )
        
        roles_dict = {
            f"{role.room_id}.{role.role_name}": role 
            for role in sorted_roles
        }
        
        role_cache[cache_key] = {
            "roles": roles_dict,
            "updated_at": now
        }
        
    roles = role_cache[cache_key]["roles"]
    return roles

async def check_roles(facility_id: int, data_dict: Dict[str, str], roles):
    tokens: List[str] = []
    # 단순 센서키 대신 (센서키, matching_role) 튜플을 저장
    triggered_alarms: List[tuple] = []
    facility_name: str = f"시설 #{facility_id}" # 기본값 설정

    async for db in get_db():
        candidate_alarms = []
        # 1. 알람 대상 조건 검사 및 발생 대상 선별
        for role in roles:
            for k, v in data_dict.items():
                if role.role_name in k and str(role.room_id) in k:
                    val = float(v)
                    low_limit = float(role.target_low_limit) if role.target_low_limit not in (None, "", "null") else float('-inf')
                    high_limit = float(role.target_high_limit) if role.target_high_limit not in (None, "", "null") else float('inf')

                    is_out_of_bounds = val <= low_limit or val >= high_limit
                    
                    if is_out_of_bounds:
                        candidate_alarms.append((k, role))

        # 2. 이상이 발생한 항목이 있을 때만 단 1번의 DB 쿼리로 기존 알람들 조회 (In-Memory 매핑)
        if candidate_alarms:
            # 검사할 알람명 목록 추출
            candidate_names = [AMM.Maped.get(k, k) for k, _ in candidate_alarms]

            # IN 쿼리로 한 번에 조회
            stmt = select(Alarm).where(Alarm.alarm_name.in_(candidate_names))
            result = await db.execute(stmt)
    
            # {alarm_name: Alarm 객체} 형태의 딕셔너리로 변환
            existing_alarms = {a.alarm_name: a for a in result.scalars().all()}

            now_utc = datetime.now(timezone.utc)

            # 3. end_time이 지나지 않은(진행 중인) 알람 필터링
            for k, role in candidate_alarms:
                am_name = AMM.Maped.get(k, k)
                mapping = existing_alarms.get(am_name)

                # 이미 활성화되어 진행 중인 알람이면 제외
                if mapping and mapping.end_time and (mapping.end_time >= now_utc):
                    continue

                # 신규 발생 대상에 추가
                triggered_alarms.append((k, role))

        # 2. 발생 대상이 있을 경우: DB에 Alarm 기록 저장 & FCM 토큰 조회
        # 관리자는 조건과 관계 없이 가능하게 해야 함
        if triggered_alarms:
            facility_stmt = select(Facility.name).where(Facility.id == facility_id)
            facility_res = await db.execute(facility_stmt)
            fetched_name = facility_res.scalar_one_or_none()
            if fetched_name:
                facility_name = fetched_name

            now_time = datetime.now(timezone.utc)
            
            # 2-1. DB에 신규 Alarm 인스턴스 기록
            for k, role in triggered_alarms:
                am_name = AMM.Maped.get(k, k)
                
                new_alarm = Alarm(
                    role_id=role.id,                         # matching PointRole의 PK ID
                    alarm_name=am_name,                      # 알람명
                    severity=getattr(role, 'severity', 'a'), # role에 설정된 severity 사용 (기본값 'a')
                    timestamp=now_time,                      # 발생 시간
                    is_triggered=True,                       # 알람 발동 상태
                    reset_timeout_interval=timedelta(hours=24), # 기본 리셋 타임아웃
                    end_time=now_time + timedelta(hours=24)  # end_time 기본 24시간 지정 예시
                )
                db.add(new_alarm)
            
            # DB 변경사항 적용
            await db.commit()

            # 2-2. FCM 토큰 1회 조회 (JOIN)
            stmt_token = (
                select(UserFcmToken.fcm_token)
                .join(User, User.id == UserFcmToken.user_id)
                .outerjoin(FacilityUser, FacilityUser.user_id == UserFcmToken.user_id)
                .where(
                    or_(
                        FacilityUser.facility_id == facility_id,
                        User.role == UserRole.ADMIN,
                    )           
                )
                .distinct()
            )
            res_token = await db.execute(stmt_token)
            tokens = list(res_token.scalars().all())

        break # get_db() 생성기 1회 수행 후 탈출

    # 3. FCM 푸시 알림 전송
    if tokens and triggered_alarms:
        print("알람 발생 : ", [k for k, _ in triggered_alarms])
        for k, _ in triggered_alarms:
            mapped_name = AMM.Maped.get(k)
            if mapped_name:
                await msg.send_multicast_fcm(tokens, facility_name + "이상 발생", mapped_name)
            else:
                await msg.send_multicast_fcm(tokens, facility_name + "이상 발생", f"{k}")