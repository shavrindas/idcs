# ===============================================================
# 경로 : src/controllers/chart/chart_controller.py
# 명세 : 차트 시각화를 위한 시계열 데이터 조회 API (TimescaleDB 연동)
# ===============================================================
from fastapi import APIRouter, Depends, Query, HTTPException
from typing import Optional, Dict, Any, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from config.db import get_db

router = APIRouter(prefix="/chart", tags=["Chart"])

# 프론트엔드 파라미터를 PostgreSQL Interval 문자열로 변환하는 매핑 딕셔너리
SCALE_MAPPING = {
    "10s": "10 seconds",
    "1m": "1 minute",
    "5m": "5 minutes",
    "10m": "10 minutes",
    "1h": "1 hour"
}

TIME_RANGE_MAPPING = {
    "1h": "1 hour",
    "12h": "12 hours",
    "1d": "1 day",
    "7d": "7 days",
    "15d": "15 days",
    "30d": "30 days"
}

@router.get("/{facility_id}/{room_id}")
async def get_chart_data(
    facility_id: int,
    room_id: int,
    scale: str = Query("1m", description="데이터 해상도"),
    time_range: str = Query("1d", description="조회 기간"),
    role_ids: str = Query(..., description="조회할 PointRole ID 목록 (콤마로 구분)"),
    db: AsyncSession = Depends(get_db)
):
    if scale not in SCALE_MAPPING or time_range not in TIME_RANGE_MAPPING:
        raise HTTPException(status_code=400, detail="유효하지 않은 파라미터입니다.")
    
    bucket_interval = SCALE_MAPPING[scale]
    range_interval = TIME_RANGE_MAPPING[time_range]
    target_roles = [int(r.strip()) for r in role_ids.split(",")]

    # 1. PointRole 메타데이터 조회 (타입 구분을 위해 role_name 활용)
    # [주석] chart_group_table 의 구조와 그룹핑은 타입을 가리지 않습니다.
    # 포인트롤 자체가 곧 타입 정보를 가지므로(role_name), 백엔드에서 이를 분석해 각각의 하이퍼테이블을 조회합니다.
    role_query = text("""
        SELECT id, role_name, target_value, target_low_limit, target_high_limit
        FROM point_role_table
        WHERE id = ANY(:role_ids) AND is_current = TRUE
    """)
    role_result = await db.execute(role_query, {"role_ids": target_roles})
    roles_info = {row.id: dict(row._mapping) for row in role_result.fetchall()}

    if not roles_info:
        return {"status": "success", "data": {"datasets": []}, "message": "유효한 Role 데이터가 없습니다."}

    # 역할별 쿼리 대상 분류
    temp_roles, gear_roles, static_roles, bool_roles = [], [], [], []
    for r_id, r_info in roles_info.items():
        r_name = r_info["role_name"].lower()
        if "temp_" in r_name: temp_roles.append(r_id)
        elif "gear_" in r_name: gear_roles.append(r_id)
        elif "static_" in r_name: static_roles.append(r_id)
        elif "bool_" in r_name: bool_roles.append(r_id)

    # 2. 통합 타임라인을 위한 기준 시간(가장 최근 데이터 시간) 확보
    # 전체 쿼리를 단순화하기 위해 temperature 테이블 기준으로 최근 시간을 잡음 (실 환경에선 전체 테이블 MAX 비교 권장)
    max_time_query = text("SELECT MAX(timestamp) FROM temperature_numerical_logs WHERE role_id = ANY(:role_ids)")
    latest_time = (await db.execute(max_time_query, {"role_ids": temp_roles if temp_roles else target_roles})).scalar()

    if not latest_time:
        return {"status": "success", "data": {"datasets": []}, "message": "기록된 로그가 없습니다."}

    # 3. 타입별 데이터 집계 및 병합 헬퍼 함수
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
              AND timestamp >= (CAST(:latest_time AS timestamptz) - INTERVAL '{range_interval}')
              AND timestamp <= CAST(:latest_time AS timestamptz)
            GROUP BY role_id, bucket ORDER BY bucket ASC
        """)
        rows = await db.execute(query, {"role_ids": type_roles, "latest_time": latest_time})
        for r in rows.fetchall():
            r_dict = dict(r._mapping)
            point = {"timestamp": r_dict["bucket"].isoformat()}
            for db_key, out_key in data_key_mapping.items(): point[out_key] = r_dict[db_key]
            datasets_map[r_dict["role_id"]]["data"].append(point)

    # 4. 각 하이퍼테이블 병렬/순차 조회
    await fetch_and_map("temperature_numerical_logs", "AVG(temp_mean) AS mean, MIN(temp_min) AS min, MAX(temp_max) AS max", temp_roles, {"mean": "mean", "min": "min", "max": "max"})
    await fetch_and_map("gear_numerical_logs", "AVG(gear_mean) AS mean, MIN(gear_min) AS min, MAX(gear_max) AS max", gear_roles, {"mean": "mean", "min": "min", "max": "max"})
    await fetch_and_map("equipment_static_logs", "AVG(setnum) AS mean", static_roles, {"mean": "mean"})
    await fetch_and_map("bool_logs", "BOOL_OR(status_value) AS status", bool_roles, {"status": "status"})

    return {
        "status": "success",
        "meta": {"facility_id": facility_id, "room_id": room_id, "scale": scale, "time_range": time_range, "reference_time": latest_time.isoformat()},
        "data": {"datasets": list(datasets_map.values())}
    }