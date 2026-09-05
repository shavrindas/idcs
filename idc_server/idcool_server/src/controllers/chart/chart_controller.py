from fastapi import APIRouter, Depends, Query, HTTPException
from typing import Optional, Dict, Any, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from datetime import datetime
from config.db import get_db

router = APIRouter(prefix="/chart", tags=["Chart"])

SCALE_MAPPING = {
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
    start_time: Optional[str] = Query(None, description="조회 시작 ISO 일시"),
    end_time: Optional[str] = Query(None, description="조회 종료 ISO 일시"),
    role_ids: str = Query(..., description="조회할 PointRole ID 목록 (콤마 구분)"),
    db: AsyncSession = Depends(get_db)
):
    if scale not in SCALE_MAPPING:
        raise HTTPException(status_code=400, detail="유효하지 않은 scale 파라미터입니다.")
    
    bucket_interval = SCALE_MAPPING[scale]
    target_roles = [int(r.strip()) for r in role_ids.split(",") if r.strip().isdigit()]

    if not target_roles:
        return {"status": "success", "data": {"datasets": []}}

    # 1. PointRole 메타데이터 조회
    role_query = text("""
        SELECT pr.id, pr.role_name, pr.target_value, pr.target_low_limit, pr.target_high_limit,
               prm.display_name, prm.short_name, prm.data_type
        FROM point_role_table pr
        LEFT JOIN point_role_metadata prm ON pr.id = prm.role_id
        WHERE pr.id = ANY(:role_ids)
    """)
    role_result = await db.execute(role_query, {"role_ids": target_roles})
    roles_info = {row.id: dict(row._mapping) for row in role_result.fetchall()}

    if not roles_info:
        return {"status": "success", "data": {"datasets": []}, "message": "유효한 Role 데이터가 없습니다."}

    # 역할별 타입 분류 (메타데이터 data_type 우선, 없으면 role_name 기준)
    temp_roles, gear_roles, static_roles, bool_roles = [], [], [], []
    for r_id, r_info in roles_info.items():
        dtype = (r_info.get("data_type") or "").upper()
        r_name = r_info["role_name"].lower()

        if dtype == "TEMP" or "temp_" in r_name: temp_roles.append(r_id)
        elif dtype == "GEAR" or "gear_" in r_name: gear_roles.append(r_id)
        elif dtype == "STATIC" or "static_" in r_name: static_roles.append(r_id)
        elif dtype == "BOOL" or "bool_" in r_name: bool_roles.append(r_id)
        else: temp_roles.append(r_id)

    # 2. 조회 기간 설정 (프론트가 넘긴 ISO 시간 우선 사용)
    where_time = ""
    params: Dict[str, Any] = {"role_ids": target_roles}
    if start_time and end_time:
        where_time = "AND timestamp >= :start_time AND timestamp <= :end_time"
        params["start_time"] = datetime.fromisoformat(start_time.replace("Z", "+00:00"))
        params["end_time"] = datetime.fromisoformat(end_time.replace("Z", "+00:00"))
    else:
        # 시간 파라미터가 없을 경우 최근 24시간
        where_time = "AND timestamp >= (NOW() - INTERVAL '1 day') AND timestamp <= NOW()"

    # 3. 데이터셋 기본 맵 구조 구성
    datasets_map: Dict[int, Any] = {
        r_id: {
            "role_id": r_id,
            "role_name": roles_info[r_id]["role_name"],
            "display_name": roles_info[r_id]["display_name"],
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
            WHERE role_id = ANY(:type_roles) {where_time}
            GROUP BY role_id, bucket 
            ORDER BY bucket ASC
        """)
        exec_params = {**params, "type_roles": type_roles}
        rows = await db.execute(query, exec_params)
        for r in rows.fetchall():
            r_dict = dict(r._mapping)
            point = {"timestamp": r_dict["bucket"].isoformat()}
            for db_key, out_key in data_key_mapping.items(): 
                point[out_key] = r_dict[db_key]
            datasets_map[r_dict["role_id"]]["data"].append(point)

    # 4. 각 하이퍼테이블 조회
    await fetch_and_map("temperature_numerical_logs", "AVG(temp_mean) AS mean, MIN(temp_min) AS min, MAX(temp_max) AS max", temp_roles, {"mean": "mean", "min": "min", "max": "max"})
    await fetch_and_map("gear_numerical_logs", "AVG(gear_mean) AS mean, MIN(gear_min) AS min, MAX(gear_max) AS max", gear_roles, {"mean": "mean", "min": "min", "max": "max"})
    await fetch_and_map("equipment_static_logs", "AVG(setnum) AS mean", static_roles, {"mean": "mean"})
    await fetch_and_map("bool_logs", "BOOL_OR(status_value) AS status", bool_roles, {"status": "status"})

    return {
        "status": "success",
        "data": {"datasets": list(datasets_map.values())}
    }