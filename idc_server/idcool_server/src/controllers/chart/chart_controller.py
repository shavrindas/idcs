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
    data_type: str = Query(..., description="조회할 데이터 타입: temp, gear, static, bool"),
    scale: str = Query("1m", description="데이터 해상도 (예: 10s, 1m, 5m, 1h)"),
    time_range: str = Query("1d", description="조회 기간 (예: 1h, 1d, 7d)"),
    role_ids: Optional[str] = Query(None, description="조회할 PointRole ID 목록 (콤마로 구분)"),
    db: AsyncSession = Depends(get_db)
):
    """
    선택된 호실과 데이터 타입에 맞는 시계열 데이터를 주어진 해상도에 맞춰 집계하여 반환합니다.
    """
    if scale not in SCALE_MAPPING:
        raise HTTPException(status_code=400, detail="유효하지 않은 scale 값입니다.")
    if time_range not in TIME_RANGE_MAPPING:
        raise HTTPException(status_code=400, detail="유효하지 않은 time_range 값입니다.")
    
    bucket_interval = SCALE_MAPPING[scale]
    range_interval = TIME_RANGE_MAPPING[time_range]
    
    target_roles = [int(r.strip()) for r in role_ids.split(",")] if role_ids else []

    # 1. 대상 데이터 타입에 따른 테이블 및 컬럼 매핑
    table_name = ""
    agg_columns = ""
    if data_type == "temp":
        table_name = "temperature_numerical_logs"
        agg_columns = "AVG(temp_mean) AS mean, MIN(temp_min) AS min, MAX(temp_max) AS max"
    elif data_type == "gear":
        table_name = "gear_numerical_logs"
        agg_columns = "AVG(gear_mean) AS mean, MIN(gear_min) AS min, MAX(gear_max) AS max"
    elif data_type == "static":
        table_name = "equipment_static_logs"
        agg_columns = "AVG(setnum) AS mean"
    elif data_type == "bool":
        table_name = "bool_logs"
        # Bool의 경우 해당 버킷 내에서 한 번이라도 True가 있었으면 True로 간주(혹은 비율 집계 가능)
        agg_columns = "BOOL_OR(status_value) AS status"
    else:
        raise HTTPException(status_code=400, detail="지원하지 않는 data_type 입니다.")

    # 2. 호실 내 해당 데이터 타입의 Role 정보 조회 (target_value, target_limit 등 포함)
    role_query = text("""
        SELECT id, role_name, target_value, target_low_limit, target_high_limit
        FROM point_role_table
        WHERE facility_id = :facility_id AND room_id = :room_id AND is_current = TRUE
    """)
    role_result = await db.execute(role_query, {"facility_id": facility_id, "room_id": room_id})
    roles_info = {row.id: dict(row._mapping) for row in role_result.fetchall()}

    if target_roles:
        roles_info = {k: v for k, v in roles_info.items() if k in target_roles}

    if not roles_info:
        return {"status": "success", "data": {"datasets": []}, "message": "조회할 Role 데이터가 없습니다."}

    valid_role_ids = list(roles_info.keys())

    # 3. 테스트 데이터 기준점(최신 시간) 찾기 로직 
    # (2025년 생성 데이터 테스트를 위해 NOW() 대신 테이블의 최신 시간을 기준으로 역산)
    max_time_query = text(f"SELECT MAX(timestamp) FROM {table_name} WHERE role_id = ANY(:role_ids)")
    max_time_result = await db.execute(max_time_query, {"role_ids": valid_role_ids})
    latest_time = max_time_result.scalar()

    if not latest_time:
        return {"status": "success", "data": {"datasets": []}, "message": "기록된 로그가 없습니다."}


    # 4. time_bucket 및 Interval 쿼리 연산 순서 및 명시적 타입 지정
    # :latest_time::timestamptz 구문 대신, PostgreSQL 함수(CAST)를 사용해 바인딩 연산 순서를 명확히 지정합니다.
    chart_query = text(f"""
        SELECT 
            role_id,
            time_bucket('{bucket_interval}', timestamp) AS bucket,
            {agg_columns}
        FROM {table_name}
        WHERE role_id = ANY(:role_ids) 
          AND timestamp >= (CAST(:latest_time AS timestamptz) - INTERVAL '{range_interval}')
          AND timestamp <= CAST(:latest_time AS timestamptz)
        GROUP BY role_id, bucket
        ORDER BY bucket ASC
    """)
    
    result = await db.execute(chart_query, {
        "role_ids": valid_role_ids,
        "latest_time": latest_time
    })
    rows = result.fetchall()
    print(f"DEBUG LOG: 조회된 데이터 총 행(Row) 수 = {len(rows)}개")

    # 5. 프론트엔드 (fl_chart) 소비를 위한 데이터 가공 로직
    datasets_map: Dict[int, Any] = {
        role_id: {
            "role_id": role_id,
            "role_name": roles_info[role_id]["role_name"],
            "target_value": roles_info[role_id]["target_value"],
            "target_low_limit": roles_info[role_id]["target_low_limit"],
            "target_high_limit": roles_info[role_id]["target_high_limit"],
            "data": []
        }
        for role_id in valid_role_ids
    }

    for row in rows:
        r_dict = dict(row._mapping)
        r_id = r_dict["role_id"]
        
        # timestamp를 ISO 포맷 문자열로 변환
        point = {"timestamp": r_dict["bucket"].isoformat()}
        
        if data_type in ["temp", "gear"]:
            point.update({"mean": r_dict["mean"], "min": r_dict["min"], "max": r_dict["max"]})
        elif data_type == "static":
            point.update({"mean": r_dict["mean"]})
        elif data_type == "bool":
            point.update({"status": r_dict["status"]})
            
        datasets_map[r_id]["data"].append(point)

    return {
        "status": "success",
        "meta": {
            "facility_id": facility_id,
            "room_id": room_id,
            "scale": scale,
            "time_range": time_range,
            "data_type": data_type,
            "reference_time": latest_time.isoformat()
        },
        "data": {
            "datasets": list(datasets_map.values())
        }
    }