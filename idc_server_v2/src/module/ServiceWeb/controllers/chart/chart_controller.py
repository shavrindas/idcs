# 경로 : src/module/ServiceWeb/controllers/chart/chart_controller.py
from fastapi import APIRouter, Depends, Query, HTTPException
from typing import Optional, Dict, Any, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from src.config.database import get_db
from datetime import datetime


router = APIRouter(prefix="/chart", tags=["ServiceWeb - Chart"])

SCALE_MAPPING = {
    "10s": "10 seconds",
    "1m": "1 minute",
    "5m": "5 minutes",
    "10m": "10 minutes",
    "15m": "15 minutes",
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

@router.get("/compare/{facility_id}/available-roles")
async def get_comparable_roles(facility_id: int, db: AsyncSession = Depends(get_db)):
    query = text("""
        SELECT pr.role_name, COUNT(DISTINCT pr.room_id) AS room_count,
               MAX(prm.display_name) AS display_name
        FROM point_role_table pr
        LEFT JOIN point_role_metadata prm ON pr.id = prm.role_id
        WHERE pr.facility_id = :facility_id AND pr.is_current = TRUE
          AND pr.role_name NOT ILIKE 'bool\\_%' ESCAPE '\\'
        GROUP BY pr.role_name
        HAVING COUNT(DISTINCT pr.room_id) > 1
        ORDER BY pr.role_name
    """)
    rows = await db.execute(query, {"facility_id": facility_id})
    roles = [
        {
            "role_name": row.role_name,
            "display_name": row.display_name or row.role_name,
            "room_count": row.room_count,
        }
        for row in rows.fetchall()
    ]
    return {"status": "success", "data": {"roles": roles}}

@router.get("/compare/{facility_id}")
async def get_compare_data(
    facility_id: int,
    role_name: str = Query(...),
    scale: str = Query("1m"),
    time_range: str = Query("1d"),
    db: AsyncSession = Depends(get_db)
):
    if scale not in SCALE_MAPPING or time_range not in TIME_RANGE_MAPPING:
        raise HTTPException(status_code=400, detail="유효하지 않은 파라미터입니다.")

    bucket_interval = SCALE_MAPPING[scale]
    range_interval = TIME_RANGE_MAPPING[time_range]

    roles_query = text("""
        SELECT pr.id AS role_id, pr.room_id, fr.name AS room_name
        FROM point_role_table pr
        JOIN facilities_room_table fr ON fr.id = pr.room_id
        WHERE pr.facility_id = :facility_id AND pr.role_name = :role_name AND pr.is_current = TRUE
        ORDER BY fr.name
    """)
    role_rows = (await db.execute(roles_query, {"facility_id": facility_id, "role_name": role_name})).fetchall()
    if not role_rows:
        return {"status": "success", "data": {"datasets": []}, "message": "비교할 호실 데이터가 없습니다."}

    target_roles = [row.role_id for row in role_rows]
    room_by_role = {row.role_id: {"room_id": row.room_id, "room_name": row.room_name} for row in role_rows}

    r_name_lower = role_name.lower()
    if "temp_" in r_name_lower:
        table_name, agg_columns, data_key_mapping = "temperature_numerical_logs", "AVG(temp_mean) AS mean, MIN(temp_min) AS min, MAX(temp_max) AS max", {"mean": "mean", "min": "min", "max": "max"}
    elif "gear_" in r_name_lower:
        table_name, agg_columns, data_key_mapping = "gear_numerical_logs", "AVG(gear_mean) AS mean, MIN(gear_min) AS min, MAX(gear_max) AS max", {"mean": "mean", "min": "min", "max": "max"}
    elif "static_" in r_name_lower:
        table_name, agg_columns, data_key_mapping = "equipment_static_logs", "AVG(setnum) AS mean", {"mean": "mean"}
    elif "bool_" in r_name_lower:
        table_name, agg_columns, data_key_mapping = "bool_logs", "BOOL_OR(status_value) AS status", {"status": "status"}
    else:
        return {"status": "success", "data": {"datasets": []}, "message": "지원되지 않는 데이터 타입입니다."}

    max_time_query = text(f"SELECT MAX(timestamp) FROM {table_name} WHERE role_id = ANY(:role_ids)")
    latest_time = (await db.execute(max_time_query, {"role_ids": target_roles})).scalar()
    if not latest_time:
        return {"status": "success", "data": {"datasets": []}, "message": "기록된 로그가 없습니다."}

    datasets_map: Dict[int, Any] = {
        r_id: {
            "role_id": r_id,
            "room_id": room_by_role[r_id]["room_id"],
            "room_name": room_by_role[r_id]["room_name"],
            "role_name": role_name,
            "data": [],
        } for r_id in target_roles
    }

    query = text(f"""
        SELECT role_id, time_bucket('{bucket_interval}', timestamp) AS bucket, {agg_columns}
        FROM {table_name}
        WHERE role_id = ANY(:role_ids)
          AND timestamp >= (CAST(:latest_time AS timestamptz) - INTERVAL '{range_interval}')
          AND timestamp <= CAST(:latest_time AS timestamptz)
        GROUP BY role_id, bucket ORDER BY bucket ASC
    """)
    rows = await db.execute(query, {"role_ids": target_roles, "latest_time": latest_time})
    for r in rows.fetchall():
        r_dict = dict(r._mapping)
        point = {"timestamp": r_dict["bucket"].isoformat()}
        for db_key, out_key in data_key_mapping.items(): point[out_key] = r_dict[db_key]
        datasets_map[r_dict["role_id"]]["data"].append(point)

    return {
        "status": "success",
        "meta": {"facility_id": facility_id, "role_name": role_name, "scale": scale, "time_range": time_range, "reference_time": latest_time.isoformat()},
        "data": {"datasets": list(datasets_map.values())}
    }

@router.get("/{facility_id}/{room_id}")
async def get_chart_data(
    facility_id: int,
    room_id: int,
    scale: str = Query("1m"),
    time_range: Optional[str] = Query(None),
    start_time: Optional[str] = Query(None),
    end_time: Optional[str] = Query(None),
    group_id: Optional[int] = Query(None),
    role_ids: str = Query(...),
    db: AsyncSession = Depends(get_db)
):
    if scale not in SCALE_MAPPING:
        raise HTTPException(status_code=400, detail="유효하지 않은 scale 파라미터입니다.")
    
    bucket_interval = SCALE_MAPPING[scale]
    target_roles = [int(r.strip()) for r in role_ids.split(",") if r.strip()]

    role_query = text("""
        SELECT pr.id, pr.role_name, pr.target_value, pr.target_low_limit, pr.target_high_limit,
               COALESCE(prm.display_name, pr.role_name) as display_name,
               prm.data_type
        FROM point_role_table pr
        LEFT JOIN point_role_metadata prm ON pr.id = prm.role_id
        WHERE pr.id = ANY(:role_ids) AND pr.is_current = TRUE
    """)
    role_result = await db.execute(role_query, {"role_ids": target_roles})
    roles_info = {row.id: dict(row._mapping) for row in role_result.fetchall()}

    if not roles_info:
        return {"status": "success", "data": {"datasets": [], "posts": [], "alarms": [], "hidden_posts": []}}

    temp_roles, gear_roles, static_roles, bool_roles = [], [], [], []
    for r_id, r_info in roles_info.items():
        r_name = r_info["role_name"].lower()
        dtype = (r_info.get("data_type") or "").upper()
        if dtype == "BOOL" or "bool_" in r_name: bool_roles.append(r_id)
        elif dtype == "GEAR" or "gear_" in r_name: gear_roles.append(r_id)
        elif dtype == "STATIC" or "static_" in r_name: static_roles.append(r_id)
        else: temp_roles.append(r_id)

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

    if start_time and end_time:
        # '2026-10-03T15:16:00.000Z' -> '+00:00' 치환 후 datetime 객체로 파싱
        start_dt = datetime.fromisoformat(start_time.replace("Z", "+00:00"))
        end_dt = datetime.fromisoformat(end_time.replace("Z", "+00:00"))
        time_filter_sql = "timestamp >= :start_time AND timestamp <= :end_time"
        time_params = {"start_time": start_dt, "end_time": end_dt}
    else:
        r_interval = TIME_RANGE_MAPPING.get(time_range or "1d", "1 day")
        max_time_query = text("SELECT MAX(timestamp) FROM temperature_numerical_logs WHERE role_id = ANY(:role_ids)")
        latest_time = (await db.execute(max_time_query, {"role_ids": temp_roles if temp_roles else target_roles})).scalar()
        if not latest_time:
            return {"status": "success", "data": {"datasets": [], "posts": [], "alarms": [], "hidden_posts": []}}
        time_filter_sql = f"timestamp >= (CAST(:latest_time AS timestamptz) - INTERVAL '{r_interval}') AND timestamp <= CAST(:latest_time AS timestamptz)"
        time_params = {"latest_time": latest_time}

    async def fetch_and_map(table_name: str, agg_columns: str, type_roles: List[int], data_key_mapping: dict):
        if not type_roles: return
        query = text(f"""
            SELECT role_id, time_bucket('{bucket_interval}', timestamp) AS bucket, {agg_columns}
            FROM {table_name}
            WHERE role_id = ANY(:role_ids) AND {time_filter_sql}
            GROUP BY role_id, bucket ORDER BY bucket ASC
        """)
        rows = await db.execute(query, {"role_ids": type_roles, **time_params})
        for r in rows.fetchall():
            r_dict = dict(r._mapping)
            point = {"timestamp": r_dict["bucket"].isoformat()}
            for db_key, out_key in data_key_mapping.items(): point[out_key] = r_dict[db_key]
            datasets_map[r_dict["role_id"]]["data"].append(point)

    await fetch_and_map("temperature_numerical_logs", "AVG(temp_mean) AS mean, MIN(temp_min) AS min, MAX(temp_max) AS max", temp_roles, {"mean": "mean", "min": "min", "max": "max"})
    await fetch_and_map("gear_numerical_logs", "AVG(gear_mean) AS mean, MIN(gear_min) AS min, MAX(gear_max) AS max", gear_roles, {"mean": "mean", "min": "min", "max": "max"})
    await fetch_and_map("equipment_static_logs", "AVG(setnum) AS mean", static_roles, {"mean": "mean"})
    await fetch_and_map("bool_logs", "BOOL_OR(status_value) AS status", bool_roles, {"status": "status"})

    # 알람 조회
    alarm_query = text(f"""
        SELECT alarm_id, role_id, alarm_name, severity, timestamp
        FROM alarms
        WHERE role_id = ANY(:role_ids) AND {time_filter_sql}
        ORDER BY timestamp ASC
    """)
    alarm_rows = await db.execute(alarm_query, {"role_ids": target_roles, **time_params})
    alarms = [
        {"alarm_id": r.alarm_id, "role_id": r.role_id, "alarm_name": r.alarm_name, "severity": r.severity, "timestamp": r.timestamp.isoformat()}
        for r in alarm_rows.fetchall()
    ]

    # 소요기록(Posts) 및 블랙리스트 조회
    posts, hidden_posts = [], []
    try:
        post_query = text("""
            SELECT p.post_id as id, p.title, p.content, p.start_date, p.end_date
            FROM posts p
            JOIN boards b ON p.board_id = b.board_id
            WHERE b.facility_id = :facility_id AND p.start_date IS NOT NULL AND p.end_date IS NOT NULL
        """)
        all_posts = [dict(r._mapping) for r in (await db.execute(post_query, {"facility_id": facility_id})).fetchall()]
        
        blacklisted_ids = set()
        if group_id:
            bl_query = text("SELECT post_id FROM chart_group_post_blacklist WHERE group_id = :group_id")
            bl_rows = await db.execute(bl_query, {"group_id": group_id})
            blacklisted_ids = {r.post_id for r in bl_rows.fetchall()}

        for p in all_posts:
            p["start_date"] = p["start_date"].isoformat() if hasattr(p["start_date"], "isoformat") else str(p["start_date"])
            p["end_date"] = p["end_date"].isoformat() if hasattr(p["end_date"], "isoformat") else str(p["end_date"])
            if p["id"] in blacklisted_ids:
                hidden_posts.append(p)
            else:
                posts.append(p)
    except Exception:
        pass

    return {
        "status": "success",
        "data": {
            "datasets": list(datasets_map.values()),
            "alarms": alarms,
            "posts": posts,
            "hidden_posts": hidden_posts
        }
    }