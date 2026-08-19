# src/controllers/chart/chart_controller.py

from fastapi import APIRouter, Depends, Query, HTTPException
from typing import Optional, Dict, Any, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from datetime import datetime, timedelta
from config.db import get_db

router = APIRouter(prefix="/chart", tags=["Chart"])

SCALE_MAPPING = {
    "10s": "10 seconds",
    "1m": "1 minute",
    "5m": "5 minutes",
    "10m": "10 minutes",  
    "15m": "15 minutes",  
    "1h": "1 hour"
}


@router.get("/{facility_id}/{room_id}")
async def get_chart_data(
    facility_id: int,
    room_id: int,
    scale: str = Query("1m", description="데이터 해상도"),
    start_time: Optional[datetime] = Query(None, description="조회 시작 시간"),
    end_time: Optional[datetime] = Query(None, description="조회 종료 시간"),
    role_ids: str = Query(..., description="조회할 PointRole ID 목록"),
    group_id: Optional[int] = Query(None, description="현재 활성화된 차트 그룹 ID (블랙리스트 조회용)"),
    db: AsyncSession = Depends(get_db)
):
    
    if scale not in SCALE_MAPPING:
        raise HTTPException(status_code=400, detail="유효하지 않은 스케일입니다.")
    
    bucket_interval = SCALE_MAPPING[scale]
    target_roles = [int(r.strip()) for r in role_ids.split(",")]

    role_query = text("""
        SELECT pr.id, pr.role_name, pr.target_value, pr.target_low_limit, pr.target_high_limit, prm.data_type
        FROM point_role_table pr
        LEFT JOIN point_role_metadata prm ON pr.id = prm.role_id
        WHERE pr.id = ANY(:role_ids) AND pr.is_current = TRUE
    """)
    role_result = await db.execute(role_query, {"role_ids": target_roles})
    roles_info = {row.id: dict(row._mapping) for row in role_result.fetchall()}

    if not roles_info:
        return {"status": "success", "data": {"datasets": [], "alarms": [], "posts": [], "hidden_posts": []}, "message": "유효한 Role 데이터가 없습니다."}

    temp_roles, gear_roles, static_roles, bool_roles = [], [], [], []
    for r_id, r_info in roles_info.items():
        dtype = r_info.get("data_type")
        
        # 메타데이터가 아직 할당되지 않은 예전 롤에 대한 방어 로직 (이름 기반 Fallback)
        if not dtype:
            r_name = r_info["role_name"].lower()
            if "temp_" in r_name: temp_roles.append(r_id)
            elif "gear_" in r_name: gear_roles.append(r_id)
            elif "static_" in r_name: static_roles.append(r_id)
            elif "bool_" in r_name: bool_roles.append(r_id)
            continue
            
        if dtype == 'BOOL':
            bool_roles.append(r_id)
        elif dtype == 'STATIC':
            static_roles.append(r_id)
        elif dtype == 'GEAR':
            gear_roles.append(r_id) # 쿼리는 gear 테이블에서 수행 (결과는 메인차트로 감)
        else: # TEMP 및 기본
            temp_roles.append(r_id)

    if not end_time:
        max_time_query = text("SELECT MAX(timestamp) FROM temperature_numerical_logs WHERE role_id = ANY(:role_ids)")
        end_time = (await db.execute(max_time_query, {"role_ids": temp_roles if temp_roles else target_roles})).scalar()
        if not end_time:
            return {"status": "success", "data": {"datasets": [], "alarms": [], "posts": [], "hidden_posts": []}, "message": "기록된 로그가 없습니다."}

    if not start_time:
        start_time = end_time - timedelta(days=1)

    datasets_map: Dict[int, Any] = {
        r_id: {
            "role_id": r_id, "role_name": roles_info[r_id]["role_name"],
            "target_value": roles_info[r_id]["target_value"],
            "target_low_limit": roles_info[r_id]["target_low_limit"],
            "target_high_limit": roles_info[r_id]["target_high_limit"],
            "data": []
        } for r_id in roles_info.keys()
    }

    async def fetch_and_map(table_name: str, agg_columns: str, type_roles: List[int], data_key_mapping: dict):
        if not type_roles: return
        query = text(f"""
            SELECT role_id, time_bucket('{bucket_interval}', timestamp) AS bucket, {agg_columns}
            FROM {table_name}
            WHERE role_id = ANY(:role_ids)
              AND timestamp >= :start_time
              AND timestamp <= :end_time
            GROUP BY role_id, bucket ORDER BY bucket ASC
        """)
        rows = await db.execute(query, {"role_ids": type_roles, "start_time": start_time, "end_time": end_time})
        for r in rows.fetchall():
            r_dict = dict(r._mapping)
            point = {"timestamp": r_dict["bucket"].isoformat()}
            for db_key, out_key in data_key_mapping.items(): point[out_key] = r_dict[db_key]
            datasets_map[r_dict["role_id"]]["data"].append(point)

    await fetch_and_map("temperature_numerical_logs", "AVG(temp_mean) AS mean, MIN(temp_min) AS min, MAX(temp_max) AS max", temp_roles, {"mean": "mean", "min": "min", "max": "max"})
    await fetch_and_map("gear_numerical_logs", "AVG(gear_mean) AS mean, MIN(gear_min) AS min, MAX(gear_max) AS max", gear_roles, {"mean": "mean", "min": "min", "max": "max"})
    await fetch_and_map("equipment_static_logs", "AVG(setnum) AS mean", static_roles, {"mean": "mean"})
    await fetch_and_map("bool_logs", "BOOL_OR(status_value) AS status", bool_roles, {"status": "status"})

    # 💡 [신규 추가] 알람(Alarm) 데이터 조회
    alarm_query = text("""
        SELECT alarm_id, role_id, alarm_name, severity, timestamp, is_triggered, end_time
        FROM alarms
        WHERE role_id = ANY(:role_ids)
          AND timestamp >= :start_time
          AND timestamp <= :end_time
        ORDER BY timestamp ASC
    """)
    alarm_rows = await db.execute(alarm_query, {"role_ids": target_roles, "start_time": start_time, "end_time": end_time})
    alarms_list = []
    for row in alarm_rows.fetchall():
        alarm_dict = dict(row._mapping)
        if alarm_dict.get("timestamp"):
            alarm_dict["timestamp"] = alarm_dict["timestamp"].isoformat()
        if alarm_dict.get("end_time"):
            alarm_dict["end_time"] = alarm_dict["end_time"].isoformat()
        alarms_list.append(alarm_dict)

    # 1. 시설에 해당하는 포스트 중 기간이 설정되어 있고 차트 조회 범위와 겹치는 항목 조회
    post_query = text("""
        SELECT p.post_id as id, p.title, p.content, p.start_date, p.end_date
        FROM posts p
        JOIN boards b ON p.board_id = b.board_id
        WHERE b.facility_id = :facility_id
          AND p.start_date IS NOT NULL 
          AND p.end_date IS NOT NULL
          /* 💡 [수정됨] DATE 타입을 TIMESTAMP WITH TIME ZONE으로 캐스팅하여 타입 충돌 방어 */
          AND CAST(p.start_date AS TIMESTAMP WITH TIME ZONE) <= :end_time
          AND (CAST(p.end_date AS TIMESTAMP WITH TIME ZONE) + INTERVAL '1 day') > :start_time
    """)
    post_rows = await db.execute(post_query, {"facility_id": facility_id, "start_time": start_time, "end_time": end_time})
    all_posts = [dict(r._mapping) for r in post_rows.fetchall()]
    
    # 2. 현재 차트 그룹의 숨겨진 포스트 ID 목록 조회
    hidden_post_ids = set()
    if group_id:
        hidden_query = text("SELECT post_id FROM post_hidden_chart_groups WHERE group_id = :group_id")
        hidden_rows = await db.execute(hidden_query, {"group_id": group_id})
        hidden_post_ids = {r[0] for r in hidden_rows.fetchall()}

    visible_posts = []
    hidden_posts = []
    for p in all_posts:
        p_dict = dict(p)
        if p_dict.get("start_date"): p_dict["start_date"] = p_dict["start_date"].isoformat()
        if p_dict.get("end_date"): p_dict["end_date"] = p_dict["end_date"].isoformat()
        
        if p_dict["id"] in hidden_post_ids:
            hidden_posts.append(p_dict)
        else:
            visible_posts.append(p_dict)

    # 💡 최종 통합 응답 반환
    return {
        "status": "success",
        "meta": {"scale": scale, "start_time": start_time.isoformat(), "end_time": end_time.isoformat()},
        "data": {
            "datasets": list(datasets_map.values()),
            "alarms": alarms_list,
            "posts": visible_posts,
            "hidden_posts": hidden_posts
        }
    }