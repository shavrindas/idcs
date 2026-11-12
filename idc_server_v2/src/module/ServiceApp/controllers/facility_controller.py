from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import text
from pydantic import BaseModel
from fastapi import WebSocket, WebSocketDisconnect
from starlette.websockets import WebSocketState
from src.module.CServer.controllers.sys_auth_controller import stream_bridge
import json
import asyncio
import time
from datetime import datetime
from typing import Optional

from src.config.database import get_db, AsyncSessionLocal
from src.module.Core.models.Facility import Facility, FacilityUser, FacilityRoom
from src.module.Core.models.Monitoring import PointRole, PointRoleMetadata
from src.module.Core.models.User import User, UserRole
from sqlalchemy import text
from src.module.Core.models.Chat import ChatRoom, ChatParticipant, ChatRoomType
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/facilities", tags=["ServiceApp - Facility"])

# Last-known-reading fallback for the live panel socket: no fac_server is
# connected for every facility all the time (dev environments, a node that's
# briefly offline), and the panel used to just sit on 'NA' forever with no
# way to tell "never reported" apart from "reported 10 minutes ago". This
# pulls the latest row per point straight from the hypertables, shaped like
# the live 'datas' payload ("{room_id}.{role_name}": value) so the panel can
# reuse its existing parsing unchanged.
_SNAPSHOT_SOURCES = [
    ("temperature_numerical_logs", "temp_mean"),
    ("gear_numerical_logs", "gear_mean"),
    ("equipment_static_logs", "setnum"),
    ("bool_logs", "status_value"),
]

# 테이블 하나가 느려도 (예: 인덱스 상태가 다른 하이퍼테이블) 패널 전체가
# 그 테이블만큼 멈추면 안 된다. 테이블마다 제 커넥션으로 따로 열어 동시에
# 묻고, 이 시간 안에 못 끝내면 그 테이블만 조용히 비운다 — 틀린 값을 보여
#주는 대신 그 항목만 '없음'으로 둔다.
_SNAPSHOT_TABLE_TIMEOUT = 2.5

def _format_snapshot_value(value) -> str:
    # REAL 컬럼은 float4->float8 변환 잔여 오차 때문에 str()이 그대로
    # '-21.219999313354492' 같은 긴 문자열을 내놓는다. 실시간 설비가 보내는
    # 값은 항상 짧게 반올림돼 있어서, 패널 숫자판이 그 길이를 기준으로
    # 그려져 있다 — 그대로 보내면 자릿수가 넘쳐 화면 밖으로 밀려난다.
    if isinstance(value, bool):
        return str(value)
    if isinstance(value, float):
        return f"{value:.2f}"
    return str(value)

async def _snapshot_from_table(table: str, value_col: str, role_ids: list) -> list:
    async with AsyncSessionLocal() as db:
        max_query = text(f"SELECT MAX(timestamp) FROM {table} WHERE role_id = ANY(:role_ids)")
        table_latest = (await db.execute(max_query, {"role_ids": role_ids})).scalar()
        if table_latest is None:
            return []

        # chart_controller.py의 방식을 그대로 따른다: 먼저 이 테이블에서
        # role들의 가장 최근 시각을 구하고, 그 시각 기준 하루 안으로만
        # 훑는다. 시간 경계 없이 'ORDER BY role_id, timestamp DESC'만
        # 쓰면 하이퍼테이블 청크를 전부 훑어야 해서 느렸다 — role이 더
        # 못 받아온 지 오래됐다면 (latest - 1일) 보다 전에 멈춰 있을
        # 뿐이니, 그런 role은 이번 스냅샷에서 조용히 빠진다(=데이터 없음).
        query = text(f"""
            SELECT DISTINCT ON (role_id) role_id, {value_col} AS value, timestamp
            FROM {table}
            WHERE role_id = ANY(:role_ids)
              AND timestamp >= (CAST(:table_latest AS timestamptz) - INTERVAL '1 day')
              AND timestamp <= CAST(:table_latest AS timestamptz)
            ORDER BY role_id, timestamp DESC
        """)
        rows = (await db.execute(query, {"role_ids": role_ids, "table_latest": table_latest})).fetchall()
        return [(row.role_id, row.value, row.timestamp) for row in rows]

async def _bounded_snapshot_from_table(table: str, value_col: str, role_ids: list) -> list:
    try:
        return await asyncio.wait_for(
            _snapshot_from_table(table, value_col, role_ids), timeout=_SNAPSHOT_TABLE_TIMEOUT
        )
    except (asyncio.TimeoutError, Exception):
        # DB 쪽 문제(타임아웃, 쿼리 실패)로 한 테이블을 못 읽어도 나머지
        # 테이블의 값은 그대로 보여줘야 한다 — 패널 전체를 비우는 것보다
        # 낫다.
        return []

async def _latest_snapshot_for_facility(facility_id: int, db: AsyncSession) -> tuple[dict, Optional[datetime]]:
    # role_id를 먼저 가볍게 구해 둔 뒤 하이퍼테이블은 'role_id = ANY(...)'로만
    # 찌른다. point_role_table과 직접 JOIN 하면 role_id 범위를 못 좁혀서
    # (chart_controller.py가 쓰는 방식과 반대로) 하이퍼테이블 전체를 훑게
    # 되어 느렸다.
    role_query = text("""
        SELECT id, room_id, role_name
        FROM point_role_table
        WHERE facility_id = :facility_id AND is_current = TRUE
    """)
    role_rows = (await db.execute(role_query, {"facility_id": facility_id})).fetchall()
    if not role_rows:
        return {}, None

    role_info = {row.id: (row.room_id, row.role_name) for row in role_rows}
    role_ids = list(role_info.keys())

    results = await asyncio.gather(
        *[_bounded_snapshot_from_table(table, value_col, role_ids) for table, value_col in _SNAPSHOT_SOURCES]
    )

    datas: dict = {}
    latest_ts: Optional[datetime] = None
    for rows in results:
        for role_id, value, timestamp in rows:
            room_id, role_name = role_info[role_id]
            datas[f"{room_id}.{role_name}"] = _format_snapshot_value(value)
            if latest_ts is None or timestamp > latest_ts:
                latest_ts = timestamp

    return datas, latest_ts

class RegisterFacilityReq(BaseModel):
    access_code: str

class InviteUserReq(BaseModel):
    user_code: str

@router.get("/{user_id}")
async def get_user_facilities(user_id: int, db: AsyncSession = Depends(get_db)):
    """유저가 소속된 시설 목록 조회 (앱 셸 권한 검증용)"""
    user = (await db.execute(select(User).where(User.id == user_id))).scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

    if user.role == UserRole.DEVELOPER:
        stmt = select(Facility).where(Facility.is_active == True)
    else:
        stmt = (
            select(Facility)
            .join(FacilityUser, Facility.id == FacilityUser.facility_id)
            .where(FacilityUser.user_id == user_id, Facility.is_active == True)
        )
        
    result = await db.execute(stmt)
    facilities = result.scalars().all()
    
    return {
        "facilities": [
            {
                "id": f.id, 
                "name": f.name, 
                "start_date": f.start_date, 
                "end_date": f.end_date,
                # [수정] 앱 셸에서 user_admin 여부를 알 수 있도록 ID 포함
                "user_admin_id": getattr(f, 'user_admin_id', None) 
            }
            for f in facilities
        ]
    }

@router.get("/{room_id}/room_roles")
async def get_facility_roles(room_id: int, db: AsyncSession = Depends(get_db)):
    '''해당 호실의 포인트 롤 목록 확인'''
    result = await db.execute(select(PointRole)
                              .where(PointRole.room_id == room_id))

    roles = result.scalars().all()

    if not roles:
        raise HTTPException(status_code=404, detail="호실에 배정된 역할을 찾을 수 없습니다.")

    return {
        "roles": [
            {"id": r.id, "facility_id": r.facility_id, "role_name": r.role_name}
            for r in roles
        ]
    }

@router.get("/{room_id}/room_roles_meta")
async def get_facility_roles(room_id: int, db: AsyncSession = Depends(get_db)):
    '''해당 호실의 포인트 롤 목록 확인'''
    stmt = (
        select(PointRole, PointRoleMetadata)
        .outerjoin(PointRoleMetadata, PointRole.id == PointRoleMetadata.role_id) # 👈 inner join 대신 outerjoin 사용
        .where(PointRole.room_id == room_id)
    )
    result = await db.execute(stmt)

    roles = result.all()

    if not roles:
        raise HTTPException(status_code=404, detail="호실에 배정된 역할을 찾을 수 없습니다.")

    return {
        "roles": [
            {"id": r.id, "facility_id": r.facility_id, "role_name": r.role_name, "display_name": m.display_name if m else None, "short_name": m.short_name if m else None}
            for r, m in roles
        ]
    }

@router.post("/{user_id}/register")
async def register_facility(user_id: int, req: RegisterFacilityReq, db: AsyncSession = Depends(get_db)):
    """접근 코드를 통한 시설 등록"""
    result = await db.execute(select(Facility).where(Facility.access_code == req.access_code))
    facility = result.scalars().first()
    
    if not facility or not facility.is_active:
        raise HTTPException(status_code=404, detail="유효하지 않은 접근 코드입니다.")
        
    exist_check = await db.execute(
        select(FacilityUser).where(FacilityUser.user_id == user_id, FacilityUser.facility_id == facility.id)
    )
    if exist_check.scalars().first():
        raise HTTPException(status_code=400, detail="이미 등록된 시설입니다.")
        
    new_mapping = FacilityUser(facility_id=facility.id, user_id=user_id)
    db.add(new_mapping)
    await db.commit()
    
    return {"message": f"'{facility.name}' 시설이 등록되었습니다."}

# @router.delete("/{user_id}/unlink/{facility_id}")
# async def unlink_facility(user_id: int, facility_id: int, db: AsyncSession = Depends(get_db)):
#     """시설 연결 해제"""
#     result = await db.execute(
#         select(FacilityUser).where(FacilityUser.user_id == user_id, FacilityUser.facility_id == facility_id)
#     )
#     mapping = result.scalars().first()    
#     if not mapping:
#         raise HTTPException(status_code=404, detail="해당 시설에 등록되어 있지 않습니다.")        
#     await db.delete(mapping)
#     await db.commit()
#     return {"message": "시설 등록이 해제되었습니다."}

@router.delete("/{user_id}/unlink/{facility_id}")
async def unlink_facility(user_id: int, facility_id: int, db: AsyncSession = Depends(get_db)):
    """시설 연결 해제 및 채팅방 자동 퇴장"""
    # 1. 시설 매핑 해제
    result = await db.execute(
        select(FacilityUser).where(FacilityUser.user_id == user_id, FacilityUser.facility_id == facility_id)
    )
    mapping = result.scalars().first()
    
    if not mapping:
        raise HTTPException(status_code=404, detail="해당 시설에 등록되어 있지 않습니다.")
        
    await db.delete(mapping)

    # 2. [추가] 해당 시설의 공식 채팅방(FACILITY)에서 참가자(ChatParticipant) 삭제
    chat_room = (await db.execute(
        select(ChatRoom).where(ChatRoom.facility_id == facility_id, ChatRoom.type == ChatRoomType.FACILITY)
    )).scalars().first()

    if chat_room:
        part_result = await db.execute(
            select(ChatParticipant).where(
                ChatParticipant.room_id == chat_room.room_id, 
                ChatParticipant.user_id == user_id
            )
        )
        participant = part_result.scalars().first()
        if participant:
            await db.delete(participant)

    await db.commit()
    return {"message": "시설 등록이 해제되었으며 채팅방에서 퇴장 처리되었습니다."}



@router.get("/rooms/{facility_id}")
async def get_facility_rooms(facility_id: int, db: AsyncSession = Depends(get_db)):
    """시설 내 호실 목록 조회"""
    result = await db.execute(select(FacilityRoom).where(FacilityRoom.facility_id == facility_id))
    rooms = result.scalars().all()
    return {
        "rooms": [
            {
                "id": r.id, 
                "facility_id": r.facility_id, 
                "name": r.name, 
                "status": r.status.value if hasattr(r.status, 'value') else r.status
            } for r in rooms
        ]
    }

@router.websocket("/data/get/{facility_id}")
async def app_facility_monitoring_ws(websocket: WebSocket, facility_id: int):
    await websocket.accept()
    if facility_id not in stream_bridge.client_Listeners:
        stream_bridge.client_Listeners[facility_id] = set()
    stream_bridge.client_Listeners[facility_id].add(websocket)

    # 접속 즉시 마지막 캐싱된 상태가 있다면 1회 전송
    if facility_id in stream_bridge.latest_data:
        await websocket.send_text(json.dumps(stream_bridge.latest_data[facility_id]))
    else:
        # 지금 이 시설에 연결된 FServer가 없는 경우: 메모리 캐시 대신 마지막
        # 저장된 계측값을 DB에서 한 번 읽어 보낸다. 'live': False 로 표시해서
        # 화면이 이 값을 '방금 들어온 값'으로 착각해 신선도를 잘못 표시하지
        # 않게 한다 (패널은 live가 없거나 True일 때만 수신 시각을 지금으로 찍는다).
        async with AsyncSessionLocal() as snapshot_db:
            datas, latest_ts = await _latest_snapshot_for_facility(facility_id, snapshot_db)
        if datas:
            await websocket.send_text(json.dumps({
                "datas": datas,
                "live": False,
                "snapshot_time": latest_ts.isoformat() if latest_ts else None,
            }))

    try:
        while True:
            # 앱에서 보낸 원격 제어 명령(WR)을 해당 시설 FServer로 전달
            cmd_text = await websocket.receive_text()
            await stream_bridge.send_command_to_fserver(facility_id, cmd_text)
    except WebSocketDisconnect:
        stream_bridge.client_Listeners[facility_id].discard(websocket)

# data/get과 같은 '없으면 DB 스냅샷' 보강을 개괄(outget) 피드에도 쓴다 —
# 전체 현황 화면과 홈 화면 위젯이 같은 소켓을 보므로, 여기도 비어 있으면
# 위젯 카드가 전부 '—'로만 남는다. 다만 이 소켓은 1초마다 도는 루프라
# data/get처럼 접속 시 한 번만 조회하면 안 되고(매번 다시 물으면 초당 DB
# 왕복이 생긴다), 그렇다고 매초 다시 조회할 것도 아니라서 시설별로 잠깐
# 캐시해 둔다.
_OUTGET_FALLBACK_KEYWORDS = ["temp_pv", "temp_sv", "temp_comp", "deforest_def", "control_runsw", "emergency_emg", "emergency_cint", "emergency_high"]
_OUTGET_FALLBACK_TTL = 60.0
_outget_fallback_cache: dict = {}

async def _outget_fallback_datas(facility_id: int) -> dict:
    cached = _outget_fallback_cache.get(facility_id)
    now = time.monotonic()
    if cached and now - cached[1] < _OUTGET_FALLBACK_TTL:
        return cached[0]

    async with AsyncSessionLocal() as snapshot_db:
        datas, _ = await _latest_snapshot_for_facility(facility_id, snapshot_db)

    filtered = {
        key: val for key, val in datas.items()
        if any(keyword in key for keyword in _OUTGET_FALLBACK_KEYWORDS)
    }
    _outget_fallback_cache[facility_id] = (filtered, now)
    return filtered

'''개괄 모니터링 브로드캐스팅 용'''
@router.websocket("/data/outget/{user_id}")
async def app_facility_monitoring_ws(websocket: WebSocket, user_id: int):
    facility_list = []
    # 유저에게 연결된 퍼실리티 리스트 추출
    async for db in get_db():
        stmt = select(User.role).where(User.id == user_id)
        res = await db.execute(stmt)
        role = res.scalars().first()

        # Only DEVELOPER gets every facility; ADMIN is scoped to its own company.
        if role == UserRole.DEVELOPER:
            stmt = select(Facility.id).distinct()
        else:
            stmt = select(FacilityUser.facility_id).where(FacilityUser.user_id == user_id).distinct()

        res2 = await db.execute(stmt)
        facility_list = res2.scalars().all()

    await websocket.accept()

    try:
        while True:
            for f_id in facility_list:
                if f_id in stream_bridge.latest_data:
                    filtered_datas = {}
                    
                    if isinstance(stream_bridge.latest_data[f_id].get("datas"), dict):
                        for key, val in stream_bridge.latest_data[f_id]["datas"].items():
                            # control_runsw 를 더했다. 호실 목록('내 시설' 안)이
                            # 운전 상태를 이 값으로 그리는데, 개괄 화면은 같은
                            # 카드를 쓰면서 이 값만 못 받아 '콤프' 칸이 비어 있었다.
                            if any(keyword in key for keyword in ["temp_pv", "temp_sv", "temp_comp", "deforest_def", "control_runsw", "emergency_emg", "emergency_cint", "emergency_high"]):
                                filtered_datas[key] = val
                                
                    if filtered_datas:
                        await websocket.send_text(json.dumps({"facility_id": f_id, "datas": filtered_datas}))
                else:
                    # 이 시설에 연결된 FServer가 없음: DB 스냅샷으로 대신한다
                    # (시설별로 60초 캐시, 매초 재조회하지 않는다).
                    fallback_datas = await _outget_fallback_datas(f_id)
                    if fallback_datas:
                        await websocket.send_text(json.dumps({
                            "facility_id": f_id, "datas": fallback_datas, "live": False,
                        }))

            #연결상태 점검용
            try:
                await asyncio.wait_for(websocket.receive_text(), timeout=0.1)
            except asyncio.TimeoutError:
                pass
            
            await asyncio.sleep(1)
            
    except WebSocketDisconnect:
        print(f"[CServer] 개괄 모니터링 유저({user_id}) 연결 단절됨 (WebSocketDisconnect)")



@router.get("/{facility_id}/employees")
async def get_facility_employees(facility_id: int, user_id: int, db: AsyncSession = Depends(get_db)):
    """[앱 전용] 특정 시설의 소속 직원 목록 조회"""
    actor = (await db.execute(select(User).where(User.id == user_id))).scalars().first()
    if not actor:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

    # [방어 로직] Enum 비교 버그 원천 차단
    role_str = str(actor.role).upper()
    is_admin = "ADMIN" in role_str or "DEVELOPER" in role_str

    if not is_admin:
        exist = (await db.execute(select(FacilityUser).where(FacilityUser.user_id == user_id, FacilityUser.facility_id == facility_id))).scalars().first()
        if not exist:
            raise HTTPException(status_code=403, detail="해당 시설의 직원 목록을 볼 권한이 없습니다.")

    facility = (await db.execute(select(Facility).where(Facility.id == facility_id))).scalars().first()
    user_admin_id = getattr(facility, 'user_admin_id', None)

    # 쿼리: ADMIN과 DEVELOPER는 직원 목록에 뜨지 않도록 제외
    query = text("""
        SELECT u.id, u.name, u.email, u.role,
               fu.can_control_device, fu.can_manage_board, fu.can_manage_alarm
        FROM facility_users fu
        JOIN user_table u ON fu.user_id = u.id
        WHERE fu.facility_id = :fid
          AND u.role NOT IN ('ADMIN', 'DEVELOPER')
    """)

    try:
        result = await db.execute(query, {"fid": facility_id})
        employees = result.fetchall()
    except Exception as e:
        print(f"직원 쿼리 실패: {e}")
        raise HTTPException(status_code=500, detail="DB 쿼리 중 오류가 발생했습니다.")

    # row._mapping 을 통해 DB 조회 결과를 안전하게 딕셔너리로 변환 (500 에러 차단)
    return {
        "status": "success",
        "employees": [
            {
                "id": row._mapping["id"],
                "name": row._mapping["name"],
                "email": row._mapping["email"],
                "is_user_admin": (row._mapping["id"] == user_admin_id),
                "is_system_admin": False,
                "can_control_device": row._mapping["can_control_device"],
                "can_manage_board": row._mapping["can_manage_board"],
                "can_manage_alarm": row._mapping["can_manage_alarm"],
            } for row in employees
        ]
    }

class EmployeePermissionReq(BaseModel):
    can_control_device: bool
    can_manage_board: bool
    can_manage_alarm: bool

@router.put("/{facility_id}/employee/{target_user_id}/permissions")
async def update_employee_permissions(facility_id: int, target_user_id: int, req: EmployeePermissionReq, user_id: int, db: AsyncSession = Depends(get_db)):
    """[앱 전용] 직원의 권한(기기 제어/게시판/알람 관리) 수정"""
    actor = (await db.execute(select(User).where(User.id == user_id))).scalars().first()
    facility = (await db.execute(select(Facility).where(Facility.id == facility_id))).scalars().first()
    if not actor or not facility:
        raise HTTPException(status_code=404, detail="사용자 또는 시설을 찾을 수 없습니다.")

    role_str = str(actor.role).upper()
    is_admin = "ADMIN" in role_str or "DEVELOPER" in role_str
    is_user_admin = (getattr(facility, 'user_admin_id', None) == user_id)
    if not is_admin and not is_user_admin:
        raise HTTPException(status_code=403, detail="직원 권한을 수정할 권한이 없습니다.")

    mapping = (await db.execute(select(FacilityUser).where(FacilityUser.facility_id == facility_id, FacilityUser.user_id == target_user_id))).scalars().first()
    if not mapping:
        raise HTTPException(status_code=404, detail="해당 직원이 시설에 존재하지 않습니다.")

    mapping.can_control_device = req.can_control_device
    mapping.can_manage_board = req.can_manage_board
    mapping.can_manage_alarm = req.can_manage_alarm
    await db.commit()
    return {"status": "success"}

@router.post("/{facility_id}/invite-by-code")
async def invite_user_by_code(facility_id: int, req: InviteUserReq, user_id: int, db: AsyncSession = Depends(get_db)):
    """[앱 전용] 유저 코드를 이용한 시설 직원 즉시 등록 및 공식 채팅방 초대"""
    actor = (await db.execute(select(User).where(User.id == user_id))).scalars().first()
    facility = (await db.execute(select(Facility).where(Facility.id == facility_id))).scalars().first()
    
    if not actor or not facility:
        raise HTTPException(status_code=404, detail="사용자 또는 시설을 찾을 수 없습니다.")

    role_str = str(actor.role).upper()
    is_admin = "ADMIN" in role_str or "DEVELOPER" in role_str
    is_user_admin = (getattr(facility, 'user_admin_id', None) == user_id)
    
    if not is_admin and not is_user_admin:
        raise HTTPException(status_code=403, detail="직원을 초대할 권한이 없습니다.")

    target_user = (await db.execute(select(User).where(User.user_code == req.user_code))).scalars().first()
    if not target_user:
        raise HTTPException(status_code=404, detail="해당 유저 코드를 가진 사용자를 찾을 수 없습니다.")

    exist = (await db.execute(select(FacilityUser).where(FacilityUser.facility_id == facility_id, FacilityUser.user_id == target_user.id))).scalars().first()
    if exist:
        raise HTTPException(status_code=400, detail="이미 해당 시설에 등록된 직원입니다.")

    # 시설-유저 매핑 추가 (즉시 등록)
    db.add(FacilityUser(facility_id=facility_id, user_id=target_user.id))

    # 공식 채팅방(FACILITY) 자동 참여
    chat_room = (await db.execute(select(ChatRoom).where(ChatRoom.facility_id == facility_id, ChatRoom.type == ChatRoomType.FACILITY))).scalars().first()
    if chat_room:
        db.add(ChatParticipant(room_id=chat_room.room_id, user_id=target_user.id))

    await db.commit()
    return {"status": "success", "message": f"'{target_user.name}' 직원이 초대되었습니다."}

@router.delete("/{facility_id}/remove-employee/{target_user_id}")
async def remove_employee(facility_id: int, target_user_id: int, user_id: int, db: AsyncSession = Depends(get_db)):
    """[앱 전용] 직원을 시설에서 퇴출 (채팅방 자동 퇴장 포함)"""
    actor = (await db.execute(select(User).where(User.id == user_id))).scalars().first()
    facility = (await db.execute(select(Facility).where(Facility.id == facility_id))).scalars().first()
    
    if not actor or not facility:
        raise HTTPException(status_code=404, detail="사용자 또는 시설을 찾을 수 없습니다.")

    role_str = str(actor.role).upper()
    is_admin = "ADMIN" in role_str or "DEVELOPER" in role_str
    is_user_admin = (getattr(facility, 'user_admin_id', None) == user_id)
    
    # 자기 자신은 나갈 수 있음, 타인은 관리 권한 필요
    if user_id != target_user_id and not is_admin and not is_user_admin:
        raise HTTPException(status_code=403, detail="직원을 퇴출시킬 권한이 없습니다.")
    
    if getattr(facility, 'user_admin_id', None) == target_user_id:
        facility.user_admin_id = None

    mapping = (await db.execute(select(FacilityUser).where(FacilityUser.facility_id == facility_id, FacilityUser.user_id == target_user_id))).scalars().first()
    if not mapping:
        raise HTTPException(status_code=404, detail="해당 직원이 시설에 존재하지 않습니다.")
        
    await db.delete(mapping)

    # 공식 채팅방 자동 퇴장
    chat_room = (await db.execute(select(ChatRoom).where(ChatRoom.facility_id == facility_id, ChatRoom.type == ChatRoomType.FACILITY))).scalars().first()
    if chat_room:
        participant = (await db.execute(select(ChatParticipant).where(ChatParticipant.room_id == chat_room.room_id, ChatParticipant.user_id == target_user_id))).scalars().first()
        if participant:
            await db.delete(participant)

    await db.commit()
    return {"status": "success", "message": "직원이 시설에서 제외되었습니다."}