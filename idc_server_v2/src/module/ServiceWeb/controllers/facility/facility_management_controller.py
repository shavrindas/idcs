# 경로 : src/module/ServiceWeb/controllers/facility/facility_management_controller.py
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from sqlalchemy.future import select
from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime
from src.config.database import get_db

from src.module.ServiceWeb.controllers.facility.scope import visible_facility_ids, get_user_or_404
from src.module.Core.models.User import User, UserRole
from src.module.Core.models.Facility import Facility, FacilityUser
from src.module.Core.models.Chat import ChatRoom, ChatParticipant, ChatRoomType


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

class InviteUserReq(BaseModel):
    user_code: str


class InviteEmployeeReq(BaseModel):
    user_code: str

class SetUserAdminReq(BaseModel):
    user_admin_id: Optional[int] = None

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







@router.post("/{facility_id}/invite-by-code")
async def invite_user_by_code(facility_id: int, req: InviteUserReq, user_id: int, db: AsyncSession = Depends(get_db)):
    """[Admin / UserAdmin 전용] 유저 코드로 직원을 해당 시설에 즉시 등록 및 시설 채팅방 자동 초대"""
    # 1. 요청 주체 권한 확인 (Admin 이거나 해당 시설의 user_admin 인지)
    actor = (await db.execute(select(User).where(User.id == user_id))).scalars().first()
    facility = (await db.execute(select(Facility).where(Facility.id == facility_id))).scalars().first()
    if not actor or not facility:
        raise HTTPException(status_code=404, detail="사용자 또는 시설을 찾을 수 없습니다.")

    is_admin = actor.role in [UserRole.ADMIN, UserRole.DEVELOPER]
    is_user_admin = (facility.user_admin_id == user_id)
    if not is_admin and not is_user_admin:
        raise HTTPException(status_code=403, detail="직원을 초대할 권한이 없습니다.")

    # 2. 초대할 유저 조회
    target_user = (await db.execute(select(User).where(User.user_code == req.user_code))).scalars().first()
    if not target_user:
        raise HTTPException(status_code=404, detail="해당 유저 코드를 가진 사용자를 찾을 수 없습니다.")

    # 3. 이미 등록되어 있는지 확인
    exist = (await db.execute(
        select(FacilityUser).where(FacilityUser.facility_id == facility_id, FacilityUser.user_id == target_user.id)
    )).scalars().first()
    if exist:
        raise HTTPException(status_code=400, detail="이미 해당 시설에 등록된 직원입니다.")

    # 4. 시설-유저 매핑 추가 (즉시 등록)
    new_mapping = FacilityUser(facility_id=facility_id, user_id=target_user.id)
    db.add(new_mapping)

    # 5. [채팅 연동] 해당 시설의 공식 채팅방(FACILITY)에 자동 참여 처리
    chat_room = (await db.execute(
        select(ChatRoom).where(ChatRoom.facility_id == facility_id, ChatRoom.type == ChatRoomType.FACILITY)
    )).scalars().first()
    
    if chat_room:
        part_exist = (await db.execute(
            select(ChatParticipant).where(ChatParticipant.room_id == chat_room.room_id, ChatParticipant.user_id == target_user.id)
        )).scalars().first()
        if not part_exist:
            db.add(ChatParticipant(room_id=chat_room.room_id, user_id=target_user.id))

    await db.commit()
    return {"status": "success", "message": f"'{target_user.name}' 직원이 시설에 초대되었습니다."}




@router.get("/facility/{facility_id}/employees")
async def get_facility_employees_web(facility_id: int, user_id: int = Query(...), db: AsyncSession = Depends(get_db)):
    
    actor = await get_user_or_404(db, user_id)
    facility = (await db.execute(select(Facility).where(Facility.id == facility_id))).scalars().first()
    if not facility:
        raise HTTPException(status_code=404, detail="시설을 찾을 수 없습니다.")

    is_admin = actor.role in [UserRole.ADMIN, UserRole.DEVELOPER]
    is_user_admin = (facility.user_admin_id == user_id)
    
    if not is_admin and not is_user_admin:
        raise HTTPException(status_code=403, detail="권한이 없습니다.")

    q = text("""
        SELECT u.id, u.name, u.email, u.user_code, u.role
        FROM facility_users fu
        JOIN user_table u ON fu.user_id = u.id
        WHERE fu.facility_id = :fid
          AND u.role NOT IN ('ADMIN', 'DEVELOPER')
    """)
    rows = (await db.execute(q, {"fid": facility_id})).fetchall()
    
    return {
        "status": "success",
        "user_admin_id": facility.user_admin_id,
        "employees": [dict(r._mapping) for r in rows]
    }

@router.post("/facility/{facility_id}/employee")
async def invite_employee_web(facility_id: int, req: InviteEmployeeReq, user_id: int = Query(...), db: AsyncSession = Depends(get_db)):
    actor = await get_user_or_404(db, user_id)
    facility = (await db.execute(select(Facility).where(Facility.id == facility_id))).scalars().first()
    
    if not facility: raise HTTPException(status_code=404, detail="시설 없음")
    if actor.role not in [UserRole.ADMIN, UserRole.DEVELOPER] and facility.user_admin_id != user_id:
        raise HTTPException(status_code=403, detail="초대 권한이 없습니다.")

    target_user = (await db.execute(select(User).where(User.user_code == req.user_code))).scalars().first()
    if not target_user:
        raise HTTPException(status_code=404, detail="유효하지 않은 유저 코드입니다.")

    exist = (await db.execute(select(FacilityUser).where(FacilityUser.facility_id == facility_id, FacilityUser.user_id == target_user.id))).scalars().first()
    if exist:
        raise HTTPException(status_code=400, detail="이미 시설에 등록된 직원입니다.")

    # 매핑 및 채팅방 자동 등록
    db.add(FacilityUser(facility_id=facility_id, user_id=target_user.id))
    
    chat_room = (await db.execute(select(ChatRoom).where(ChatRoom.facility_id == facility_id, ChatRoom.type == ChatRoomType.FACILITY))).scalars().first()
    if chat_room:
        db.add(ChatParticipant(room_id=chat_room.room_id, user_id=target_user.id))

    await db.commit()
    return {"status": "success", "message": f"'{target_user.name}' 직원이 추가되었습니다."}


@router.delete("/facility/{facility_id}/employee/{target_user_id}")
async def remove_employee_web(facility_id: int, target_user_id: int, user_id: int = Query(...), db: AsyncSession = Depends(get_db)):
    actor = await get_user_or_404(db, user_id)
    facility = (await db.execute(select(Facility).where(Facility.id == facility_id))).scalars().first()
    
    if not facility: raise HTTPException(status_code=404, detail="시설 없음")
    if actor.role not in [UserRole.ADMIN, UserRole.DEVELOPER] and facility.user_admin_id != user_id:
        raise HTTPException(status_code=403, detail="해제 권한이 없습니다.")

    mapping = (await db.execute(select(FacilityUser).where(FacilityUser.facility_id == facility_id, FacilityUser.user_id == target_user_id))).scalars().first()
    if not mapping:
        raise HTTPException(status_code=404, detail="해당 직원이 없습니다.")

    # 수석 관리자를 해제할 경우 공석 처리
    if facility.user_admin_id == target_user_id:
        facility.user_admin_id = None

    await db.delete(mapping)

    chat_room = (await db.execute(select(ChatRoom).where(ChatRoom.facility_id == facility_id, ChatRoom.type == ChatRoomType.FACILITY))).scalars().first()
    if chat_room:
        part = (await db.execute(select(ChatParticipant).where(ChatParticipant.room_id == chat_room.room_id, ChatParticipant.user_id == target_user_id))).scalars().first()
        if part:
            await db.delete(part)

    await db.commit()
    return {"status": "success"}


@router.put("/facility/{facility_id}/user-admin")
async def set_user_admin_web(facility_id: int, req: SetUserAdminReq, user_id: int = Query(...), db: AsyncSession = Depends(get_db)):
    actor = await get_user_or_404(db, user_id)
    if actor.role not in [UserRole.ADMIN, UserRole.DEVELOPER]:
        raise HTTPException(status_code=403, detail="수석 관리자 지정은 최고 관리자(Admin)만 가능합니다.")

    facility = (await db.execute(select(Facility).where(Facility.id == facility_id))).scalars().first()
    if not facility:
        raise HTTPException(status_code=404, detail="시설을 찾을 수 없습니다.")

    if req.user_admin_id is not None:
        # 지정하려는 유저가 해당 시설 직원이 맞는지 검증
        exist = (await db.execute(select(FacilityUser).where(FacilityUser.facility_id == facility_id, FacilityUser.user_id == req.user_admin_id))).scalars().first()
        if not exist:
            raise HTTPException(status_code=400, detail="해당 시설의 직원 리스트에 있는 사람만 지정할 수 있습니다.")

    facility.user_admin_id = req.user_admin_id
    await db.commit()
    return {"status": "success"}