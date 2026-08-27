# 웹용도 
# 경로 : src/controllers/facility/facility_management_controller.py
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from config.db import get_db
from datetime import datetime, date, timezone

router = APIRouter(prefix="/facility-manager", tags=["Facility Manager"])

# ─── 날짜/시간 파싱 헬퍼 함수 ───
def parse_dt(dt_str: Optional[str]) -> Optional[datetime]:
    if not dt_str or not dt_str.strip():
        return None
    try:
        # ISO 포맷 ('2026-08-28T08:23', '2026-08-28T08:23:00' 등) 파싱
        dt = datetime.fromisoformat(dt_str.strip())
        if dt.tzinfo is None:
            # 타임존이 없을 경우 UTC로 지정
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except Exception:
        return None

def parse_date(d_str: Optional[str]) -> Optional[date]:
    if not d_str or not d_str.strip():
        return None
    try:
        return date.fromisoformat(d_str.strip())
    except Exception:
        return None

class FacilityCreateReq(BaseModel):
    name: str
    access_code: str
    start_date: Optional[str] = None
    end_date: Optional[str] = None

class FacilityUpdateReq(BaseModel):
    name: Optional[str] = None
    access_code: Optional[str] = None
    start_date: Optional[str] = None
    end_date: Optional[str] = None

class RoomCreateReq(BaseModel):
    name: str
    status: Optional[str] = "OPERATING"
    operation_start_date: Optional[str] = None
    operation_end_date: Optional[str] = None

class RoomUpdateReq(BaseModel):
    name: Optional[str] = None
    status: Optional[str] = None
    operation_start_date: Optional[str] = None
    operation_end_date: Optional[str] = None

class PointRoleCreateReq(BaseModel):
    role_name: str
    display_name: Optional[str] = None
    short_name: Optional[str] = None
    data_type: Optional[str] = "TEMP" # TEMP, GEAR, BOOL, STATIC
    target_value: Optional[str] = None
    target_low_limit: Optional[str] = None
    target_high_limit: Optional[str] = None
    valid_from: Optional[str] = None
    valid_to: Optional[str] = None

class PointRoleUpdateReq(BaseModel):
    display_name: Optional[str] = None
    short_name: Optional[str] = None
    data_type: Optional[str] = None
    target_value: Optional[str] = None
    target_low_limit: Optional[str] = None
    target_high_limit: Optional[str] = None
    valid_from: Optional[str] = None
    valid_to: Optional[str] = None

# ─── 시설 관리 ───
@router.get("/facilities")
async def get_all_facilities(db: AsyncSession = Depends(get_db)):
    sync_query = text("UPDATE facilities_table SET is_active = (end_date IS NULL OR end_date >= CURRENT_DATE)")
    await db.execute(sync_query)
    await db.commit()

    query = text("""
        SELECT id, name, access_code, is_active, start_date, end_date
        FROM facilities_table ORDER BY id ASC
    """)
    result = await db.execute(query)
    return {"status": "success", "facilities": [dict(r._mapping) for r in result.fetchall()]}

@router.post("/facility", status_code=status.HTTP_201_CREATED)
async def create_facility(req: FacilityCreateReq, db: AsyncSession = Depends(get_db)):
    try:
        s_date = parse_date(req.start_date)
        e_date = parse_date(req.end_date)
        is_act = (e_date is None or e_date >= date.today())

        fac_query = text("""
            INSERT INTO facilities_table (name, access_code, is_active, start_date, end_date)
            VALUES (:name, :access_code, :is_active, :start_date, :end_date) 
            RETURNING id, name
        """)
        fac_res = await db.execute(fac_query, {
            "name": req.name, "access_code": req.access_code,
            "is_active": is_act, "start_date": s_date, "end_date": e_date
        })
        fac_id = fac_res.fetchone().id

        # 000호(공용) 자동 생성
        await db.execute(text("""
            INSERT INTO facilities_room_table (facility_id, name, status)
            VALUES (:facility_id, :name, 'OPERATING')
        """), {"facility_id": fac_id, "name": f"{req.name}-000호(공용)"})

        # 게시판 자동 생성
        await db.execute(text("""
            INSERT INTO boards (facility_id, facility_name)
            VALUES (:facility_id, :name)
        """), {"facility_id": fac_id, "name": f"{req.name} 메인 게시판"})

        # 공식 채팅방 생성
        chat_res = await db.execute(text("""
            INSERT INTO chatrooms (facility_id, room_name, type)
            VALUES (:facility_id, :room_name, 'FACILITY') RETURNING room_id
        """), {"facility_id": fac_id, "room_name": f"{req.name} 공식 채팅방"})
        room_id = chat_res.scalar()

        # 관리자 계정 자동 참여
        await db.execute(text("""
            INSERT INTO chatparticipants (room_id, user_id)
            SELECT :room_id, id FROM user_table WHERE role IN ('ADMIN', 'DEVELOPER')
        """), {"room_id": room_id})

        await db.commit()
        return {"status": "success", "facility_id": fac_id, "message": "시설 및 연동 리소스가 자동 생성되었습니다."}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=400, detail=str(e))

@router.put("/facility/{facility_id}")
async def update_facility(facility_id: int, req: FacilityUpdateReq, db: AsyncSession = Depends(get_db)):
    s_date = parse_date(req.start_date)
    e_date = parse_date(req.end_date)
    is_act = (e_date is None or e_date >= date.today())

    query = text("""
        UPDATE facilities_table
        SET name = COALESCE(:name, name),
            access_code = COALESCE(:access_code, access_code),
            start_date = :start_date,
            end_date = :end_date,
            is_active = :is_active
        WHERE id = :facility_id
    """)
    await db.execute(query, {
        "facility_id": facility_id, "name": req.name, "access_code": req.access_code,
        "start_date": s_date, "end_date": e_date, "is_active": is_act
    })
    await db.commit()
    return {"status": "success", "message": "시설 정보가 수정되었습니다."}

@router.get("/facility/{facility_id}/users")
async def get_facility_users(facility_id: int, db: AsyncSession = Depends(get_db)):
    query = text("""
        SELECT u.id, u.email, u.name, u.role, u.phone_number, fu.created_at as joined_at
        FROM facility_users fu
        JOIN user_table u ON fu.user_id = u.id
        WHERE fu.facility_id = :facility_id AND u.role = 'USER'
        ORDER BY u.id ASC
    """)
    res = await db.execute(query, {"facility_id": facility_id})
    return {"status": "success", "users": [dict(r._mapping) for r in res.fetchall()]}

# ─── 호실 관리 ───
@router.post("/facility/{facility_id}/room", status_code=status.HTTP_201_CREATED)
async def create_room(facility_id: int, req: RoomCreateReq, db: AsyncSession = Depends(get_db)):
    s_date = parse_date(req.operation_start_date)
    e_date = parse_date(req.operation_end_date)

    query = text("""
        INSERT INTO facilities_room_table (facility_id, name, status, operation_start_date, operation_end_date)
        VALUES (:facility_id, :name, CAST(:status AS room_status_type), :start_date, :end_date)
        RETURNING id
    """)
    res = await db.execute(query, {
        "facility_id": facility_id, "name": req.name, "status": req.status,
        "start_date": s_date, "end_date": e_date
    })
    new_room_id = res.scalar()
    await db.commit()
    return {"status": "success", "room_id": new_room_id, "message": "호실이 추가되었습니다."}

@router.put("/room/{room_id}")
async def update_room(room_id: int, req: RoomUpdateReq, db: AsyncSession = Depends(get_db)):
    s_date = parse_date(req.operation_start_date)
    e_date = parse_date(req.operation_end_date)

    query = text("""
        UPDATE facilities_room_table
        SET name = COALESCE(:name, name),
            status = COALESCE(CAST(:status AS room_status_type), status),
            operation_start_date = :start_date,
            operation_end_date = :end_date
        WHERE id = :room_id
    """)
    await db.execute(query, {
        "room_id": room_id, "name": req.name, "status": req.status,
        "start_date": s_date, "end_date": e_date
    })
    await db.commit()
    return {"status": "success", "message": "호실 정보가 수정되었습니다."}

@router.delete("/room/{room_id}")
async def delete_room(room_id: int, db: AsyncSession = Depends(get_db)):
    check_query = text("SELECT name FROM facilities_room_table WHERE id = :room_id")
    res = await db.execute(check_query, {"room_id": room_id})
    room = res.fetchone()
    if not room:
        raise HTTPException(status_code=404, detail="호실을 찾을 수 없습니다.")
    if "000호" in room.name or "공용" in room.name:
        raise HTTPException(status_code=400, detail="공용 호실(000호)은 단독으로 삭제할 수 없습니다. (시설 삭제 시에만 자동 삭제)")

    await db.execute(text("DELETE FROM facilities_room_table WHERE id = :room_id"), {"room_id": room_id})
    await db.commit()
    return {"status": "success", "message": "호실이 삭제되었습니다."}

# ─── 포인트 롤 관리 (DataError 해결) ───
@router.get("/room/{room_id}/roles")
async def get_roles_by_room(room_id: int, db: AsyncSession = Depends(get_db)):
    sync_roles_query = text("""
        UPDATE point_role_table 
        SET is_current = (valid_to IS NULL OR valid_to >= CURRENT_TIMESTAMP)
        WHERE room_id = :room_id
    """)
    await db.execute(sync_roles_query, {"room_id": room_id})
    await db.commit()

    query = text("""
        SELECT 
            pr.id AS role_id, pr.facility_id, pr.room_id, pr.role_name,
            pr.target_value, pr.target_low_limit, pr.target_high_limit,
            pr.valid_from, pr.valid_to, pr.is_current,
            prm.display_name, prm.short_name, prm.data_type
        FROM point_role_table pr
        LEFT JOIN point_role_metadata prm ON pr.id = prm.role_id
        WHERE pr.room_id = :room_id
        ORDER BY pr.id ASC
    """)
    res = await db.execute(query, {"room_id": room_id})
    return {"status": "success", "roles": [dict(r._mapping) for r in res.fetchall()]}

@router.post("/facility/{facility_id}/room/{room_id}/role", status_code=status.HTTP_201_CREATED)
async def create_point_role(facility_id: int, room_id: int, req: PointRoleCreateReq, db: AsyncSession = Depends(get_db)):
    try:
        # 1. 날짜/시간 파싱 (Python datetime 객체 생성)
        v_from = parse_dt(req.valid_from) or datetime.now(timezone.utc)
        v_to = parse_dt(req.valid_to)
        now_utc = datetime.now(timezone.utc)
        is_cur = (v_to is None or v_to >= now_utc)

        # 2. 포인트롤 생성
        role_query = text("""
            INSERT INTO point_role_table (
                facility_id, room_id, role_name, target_value, target_low_limit, target_high_limit,
                valid_from, valid_to, is_current
            ) VALUES (
                :facility_id, :room_id, :role_name, :target_value, :target_low_limit, :target_high_limit,
                :valid_from, :valid_to, :is_current
            ) RETURNING id
        """)
        res = await db.execute(role_query, {
            "facility_id": facility_id, "room_id": room_id, "role_name": req.role_name.strip(),
            "target_value": req.target_value, "target_low_limit": req.target_low_limit, "target_high_limit": req.target_high_limit,
            "valid_from": v_from, "valid_to": v_to, "is_current": is_cur
        })
        new_role_id = res.scalar()

        # 3. 메타데이터 생성
        meta_query = text("""
            INSERT INTO point_role_metadata (role_id, display_name, short_name, data_type)
            VALUES (:role_id, NULLIF(:display_name, ''), NULLIF(:short_name, ''), CAST(:data_type AS point_data_type))
        """)
        await db.execute(meta_query, {
            "role_id": new_role_id,
            "display_name": req.display_name.strip() if req.display_name else None,
            "short_name": req.short_name.strip() if req.short_name else None,
            "data_type": req.data_type
        })

        await db.commit()
        return {"status": "success", "role_id": new_role_id, "message": "포인트 롤이 추가되었습니다."}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=400, detail=str(e))

@router.put("/role/{role_id}")
async def update_point_role(role_id: int, req: PointRoleUpdateReq, db: AsyncSession = Depends(get_db)):
    try:
        v_from = parse_dt(req.valid_from)
        v_to = parse_dt(req.valid_to)
        now_utc = datetime.now(timezone.utc)
        is_cur = (v_to is None or v_to >= now_utc)

        # 1. 포인트롤 테이블 갱신
        role_update_query = text("""
            UPDATE point_role_table
            SET target_value = COALESCE(:target_value, target_value),
                target_low_limit = COALESCE(:target_low_limit, target_low_limit),
                target_high_limit = COALESCE(:target_high_limit, target_high_limit),
                valid_from = COALESCE(:valid_from, valid_from),
                valid_to = :valid_to,
                is_current = :is_current
            WHERE id = :role_id
        """)
        await db.execute(role_update_query, {
            "role_id": role_id, "target_value": req.target_value,
            "target_low_limit": req.target_low_limit, "target_high_limit": req.target_high_limit,
            "valid_from": v_from, "valid_to": v_to, "is_current": is_cur
        })

        # 2. 메타데이터 테이블 Upsert
        meta_upsert_query = text("""
            INSERT INTO point_role_metadata (role_id, display_name, short_name, data_type, updated_at)
            VALUES (:role_id, NULLIF(:display_name, ''), NULLIF(:short_name, ''), CAST(:data_type AS point_data_type), CURRENT_TIMESTAMP)
            ON CONFLICT (role_id) DO UPDATE SET
                display_name = EXCLUDED.display_name,
                short_name = EXCLUDED.short_name,
                data_type = EXCLUDED.data_type,
                updated_at = CURRENT_TIMESTAMP
        """)
        await db.execute(meta_upsert_query, {
            "role_id": role_id,
            "display_name": req.display_name.strip() if req.display_name else None,
            "short_name": req.short_name.strip() if req.short_name else None,
            "data_type": req.data_type
        })

        await db.commit()
        return {"status": "success", "message": "포인트 롤 정보가 수정되었습니다."}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=400, detail=str(e))

@router.delete("/role/{role_id}")
async def delete_point_role(role_id: int, db: AsyncSession = Depends(get_db)):
    await db.execute(text("DELETE FROM point_role_table WHERE id = :role_id"), {"role_id": role_id})
    await db.commit()
    return {"status": "success", "message": "포인트 롤이 삭제되었습니다."}