# 경로 : src/module/ServiceWeb/controllers/facility/facility_management_controller.py
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime
from src.config.database import get_db
from src.module.Core.models.User import UserRole
from src.module.ServiceWeb.controllers.facility.scope import visible_facility_ids, get_user_or_404

router = APIRouter(prefix="/facility-manager", tags=["ServiceWeb - Facility Manager"])

class FacilityCreateReq(BaseModel):
    name: str
    access_code: str
    start_date: Optional[str] = None
    end_date: Optional[str] = None

class FacilityUpdateReq(BaseModel):
    name: str
    access_code: str
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    is_active: Optional[bool] = True

class RoomCreateReq(BaseModel):
    name: str

class RoomUpdateReq(BaseModel):
    name: str
    status: str

class RoleUpsertReq(BaseModel):
    role_name: str
    display_name: Optional[str] = None
    short_name: Optional[str] = None
    data_type: Optional[str] = "TEMP"
    target_value: Optional[str] = None
    target_low_limit: Optional[str] = None
    target_high_limit: Optional[str] = None
    valid_from: Optional[str] = None
    valid_to: Optional[str] = None

def _parse_date(d_str: Optional[str]) -> Optional[date]:
    if not d_str or not d_str.strip(): return None
    return date.fromisoformat(d_str[:10])

def _parse_dt(dt_str: Optional[str]) -> Optional[datetime]:
    if not dt_str or not dt_str.strip(): return None
    return datetime.fromisoformat(dt_str)

@router.get("/facilities")
async def get_all_facilities_admin(user_id: int = Query(...), db: AsyncSession = Depends(get_db)):
    allowed = await visible_facility_ids(db, user_id)
    if allowed is None:
        q = text("SELECT id, name, access_code, is_active, start_date, end_date FROM facilities_table ORDER BY id ASC")
        rows = (await db.execute(q)).fetchall()
    else:
        q = text("""
            SELECT id, name, access_code, is_active, start_date, end_date FROM facilities_table
            WHERE id = ANY(:ids) ORDER BY id ASC
        """)
        rows = (await db.execute(q, {"ids": list(allowed)})).fetchall()
    return {"facilities": [dict(r._mapping) for r in rows]}

@router.post("/facility")
async def create_facility_admin(req: FacilityCreateReq, user_id: int = Query(...), db: AsyncSession = Depends(get_db)):
    creator = await get_user_or_404(db, user_id)
    q = text("""
        INSERT INTO facilities_table (name, access_code, is_active, start_date, end_date)
        VALUES (:name, :access_code, TRUE, :start_date, :end_date)
        RETURNING id
    """)
    res = await db.execute(q, {
        "name": req.name, "access_code": req.access_code,
        "start_date": _parse_date(req.start_date), "end_date": _parse_date(req.end_date)
    })
    new_fac_id = res.scalar()
    # 기본 공용 000호 및 게시판 생성
    await db.execute(text("INSERT INTO facilities_room_table (facility_id, name, status) VALUES (:fid, '000호 (공용)', 'OPERATING')"), {"fid": new_fac_id})
    await db.execute(text("INSERT INTO boards (facility_id, facility_name) VALUES (:fid, :fname)"), {"fid": new_fac_id, "fname": req.name})
    # A company admin must keep seeing the facility it just created.
    if creator.role != UserRole.DEVELOPER:
        await db.execute(text("INSERT INTO facility_users (facility_id, user_id) VALUES (:fid, :uid)"), {"fid": new_fac_id, "uid": user_id})
    await db.commit()
    return {"status": "success", "id": new_fac_id}

@router.put("/facility/{facility_id}")
async def update_facility_admin(facility_id: int, req: FacilityUpdateReq, db: AsyncSession = Depends(get_db)):
    q = text("""
        UPDATE facilities_table
        SET name = :name, access_code = :access_code, start_date = :start_date, end_date = :end_date
        WHERE id = :id
    """)
    await db.execute(q, {
        "id": facility_id, "name": req.name, "access_code": req.access_code,
        "start_date": _parse_date(req.start_date), "end_date": _parse_date(req.end_date)
    })
    await db.commit()
    return {"status": "success"}

@router.get("/facility/{facility_id}/users")
async def get_facility_users_admin(facility_id: int, db: AsyncSession = Depends(get_db)):
    q = text("""
        SELECT u.id, u.name, u.email, u.role
        FROM facility_users fu
        JOIN user_table u ON fu.user_id = u.id
        WHERE fu.facility_id = :fid
    """)
    rows = (await db.execute(q, {"fid": facility_id})).fetchall()
    return {"users": [dict(r._mapping) for r in rows]}

@router.post("/facility/{facility_id}/room")
async def create_room_admin(facility_id: int, req: RoomCreateReq, db: AsyncSession = Depends(get_db)):
    q = text("INSERT INTO facilities_room_table (facility_id, name, status) VALUES (:fid, :name, 'OPERATING') RETURNING id")
    res = await db.execute(q, {"fid": facility_id, "name": req.name})
    await db.commit()
    return {"status": "success", "id": res.scalar()}

@router.put("/room/{room_id}")
async def update_room_admin(room_id: int, req: RoomUpdateReq, db: AsyncSession = Depends(get_db)):
    q = text("UPDATE facilities_room_table SET name = :name, status = CAST(:status AS room_status_type) WHERE id = :rid")
    await db.execute(q, {"rid": room_id, "name": req.name, "status": req.status})
    await db.commit()
    return {"status": "success"}

@router.delete("/room/{room_id}")
async def delete_room_admin(room_id: int, db: AsyncSession = Depends(get_db)):
    await db.execute(text("DELETE FROM facilities_room_table WHERE id = :rid"), {"rid": room_id})
    await db.commit()
    return {"status": "success"}

@router.get("/room/{room_id}/roles")
async def get_roles_by_room_admin(room_id: int, db: AsyncSession = Depends(get_db)):
    q = text("""
        SELECT pr.id as role_id, pr.facility_id, pr.room_id, pr.role_name,
               pr.target_value, pr.target_low_limit, pr.target_high_limit,
               pr.valid_from, pr.valid_to, pr.is_current,
               prm.display_name, prm.short_name, prm.data_type
        FROM point_role_table pr
        LEFT JOIN point_role_metadata prm ON pr.id = prm.role_id
        WHERE pr.room_id = :rid
        ORDER BY pr.is_current DESC, pr.id ASC
    """)
    rows = (await db.execute(q, {"rid": room_id})).fetchall()
    return {"roles": [dict(r._mapping) for r in rows]}

@router.post("/facility/{facility_id}/room/{room_id}/role")
async def create_point_role_admin(facility_id: int, room_id: int, req: RoleUpsertReq, db: AsyncSession = Depends(get_db)):
    v_from = _parse_dt(req.valid_from) or datetime.now()
    v_to = _parse_dt(req.valid_to)
    is_curr = v_to is None or v_to > datetime.now(v_to.tzinfo)
    q = text("""
        INSERT INTO point_role_table (facility_id, room_id, role_name, target_value, target_low_limit, target_high_limit, valid_from, valid_to, is_current)
        VALUES (:fid, :rid, :rname, :tv, :tlow, :thigh, :vfrom, :vto, :is_curr)
        RETURNING id
    """)
    res = await db.execute(q, {
        "fid": facility_id, "rid": room_id, "rname": req.role_name,
        "tv": req.target_value or None, "tlow": req.target_low_limit or None, "thigh": req.target_high_limit or None,
        "vfrom": v_from, "vto": v_to, "is_curr": is_curr
    })
    new_role_id = res.scalar()
    await db.execute(text("""
        INSERT INTO point_role_metadata (role_id, display_name, short_name, data_type)
        VALUES (:rid, :dname, :sname, :dtype)
        ON CONFLICT (role_id) DO UPDATE SET display_name = EXCLUDED.display_name, short_name = EXCLUDED.short_name, data_type = EXCLUDED.data_type
    """), {"rid": new_role_id, "dname": req.display_name or None, "sname": req.short_name or None, "dtype": req.data_type or "TEMP"})
    await db.commit()
    return {"status": "success", "role_id": new_role_id}

@router.put("/role/{role_id}")
async def update_point_role_admin(role_id: int, req: RoleUpsertReq, db: AsyncSession = Depends(get_db)):
    v_from = _parse_dt(req.valid_from) or datetime.now()
    v_to = _parse_dt(req.valid_to)
    is_curr = v_to is None or v_to > datetime.now(v_to.tzinfo)
    await db.execute(text("""
        UPDATE point_role_table
        SET target_value = :tv, target_low_limit = :tlow, target_high_limit = :thigh,
            valid_from = :vfrom, valid_to = :vto, is_current = :is_curr
        WHERE id = :rid
    """), {
        "rid": role_id, "tv": req.target_value or None, "tlow": req.target_low_limit or None,
        "thigh": req.target_high_limit or None, "vfrom": v_from, "vto": v_to, "is_curr": is_curr
    })
    await db.execute(text("""
        INSERT INTO point_role_metadata (role_id, display_name, short_name, data_type)
        VALUES (:rid, :dname, :sname, :dtype)
        ON CONFLICT (role_id) DO UPDATE SET display_name = EXCLUDED.display_name, short_name = EXCLUDED.short_name, data_type = EXCLUDED.data_type
    """), {"rid": role_id, "dname": req.display_name or None, "sname": req.short_name or None, "dtype": req.data_type or "TEMP"})
    await db.commit()
    return {"status": "success"}

@router.delete("/role/{role_id}")
async def delete_point_role_admin(role_id: int, db: AsyncSession = Depends(get_db)):
    await db.execute(text("DELETE FROM point_role_table WHERE id = :rid"), {"rid": role_id})
    await db.commit()
    return {"status": "success"}