# ===============================================================
# 경로 : src/controllers/chart/chart_controller.py (수정본)
# ===============================================================
from fastapi import APIRouter, Depends, Query, HTTPException
from typing import Optional, Dict, Any, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from datetime import datetime
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
    db: AsyncSession = Depends(get_db)
):
    if scale not in SCALE_MAPPING:
        raise HTTPException(status_code=400, detail="유효하지 않은 스케일입니다.")
    
    bucket_interval = SCALE_MAPPING[scale]
    target_roles = [int(r.strip()) for r in role_ids.split(",")]

    role_query = text("""
        SELECT id, role_name, target_value, target_low_limit, target_high_limit
        FROM point_role_table
        WHERE id = ANY(:role_ids) AND is_current = TRUE
    """)
    role_result = await db.execute(role_query, {"role_ids": target_roles})
    roles_info = {row.id: dict(row._mapping) for row in role_result.fetchall()}

    if not roles_info:
        return {"status": "success", "data": {"datasets": []}, "message": "유효한 Role 데이터가 없습니다."}

    temp_roles, gear_roles, static_roles, bool_roles = [], [], [], []
    for r_id, r_info in roles_info.items():
        r_name = r_info["role_name"].lower()
        if "temp_" in r_name: temp_roles.append(r_id)
        elif "gear_" in r_name: gear_roles.append(r_id)
        elif "static_" in r_name: static_roles.append(r_id)
        elif "bool_" in r_name: bool_roles.append(r_id)

    # 💡 조회 기간 강제 보정 (값이 안 들어왔을 경우 최근 1일 기준으로 설정)
    if not end_time:
        max_time_query = text("SELECT MAX(timestamp) FROM temperature_numerical_logs WHERE role_id = ANY(:role_ids)")
        end_time = (await db.execute(max_time_query, {"role_ids": temp_roles if temp_roles else target_roles})).scalar()
        if not end_time:
            return {"status": "success", "data": {"datasets": []}, "message": "기록된 로그가 없습니다."}

    if not start_time:
        # datetime.timedelta는 파이썬 내장 라이브러리 활용
        from datetime import timedelta
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

    # 💡 start_time, end_time을 쿼리에 적용
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

    return {
        "status": "success",
        "meta": {"scale": scale, "start_time": start_time.isoformat(), "end_time": end_time.isoformat()},
        "data": {"datasets": list(datasets_map.values())}
    }