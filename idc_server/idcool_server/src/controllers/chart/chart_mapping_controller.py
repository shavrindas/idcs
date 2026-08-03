from fastapi import APIRouter, Depends, HTTPException
from typing import List
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from config.db import get_db

router = APIRouter(prefix="/chart-mapping", tags=["Chart Mapping"])

class GroupCreateReq(BaseModel):
    facility_id: int
    room_id: int
    group_name: str
    data_type: str
    role_ids: List[int]

@router.get("/roles/{facility_id}/{room_id}")
async def get_point_roles(facility_id: int, room_id: int, db: AsyncSession = Depends(get_db)):
    """특정 호실의 가용한 PointRole 목록을 반환"""
    query = text("""
        SELECT id as role_id, role_name, target_value
        FROM point_role_table
        WHERE facility_id = :facility_id AND room_id = :room_id AND is_current = TRUE
    """)
    result = await db.execute(query, {"facility_id": facility_id, "room_id": room_id})
    roles = [dict(row._mapping) for row in result.fetchall()]
    return {"status": "success", "roles": roles}

@router.post("/group")
async def create_chart_group(req: GroupCreateReq, db: AsyncSession = Depends(get_db)):
    """웹 어드민에서 생성한 그룹 및 N:M 매핑 저장"""
    try:
        # 1. chart_group_table 에 그룹 삽입
        group_query = text("""
            INSERT INTO chart_group_table (facility_id, room_id, group_name, data_type)
            VALUES (:facility_id, :room_id, :group_name, :data_type)
            RETURNING id
        """)
        result = await db.execute(group_query, {
            "facility_id": req.facility_id, "room_id": req.room_id,
            "group_name": req.group_name, "data_type": req.data_type
        })
        new_group_id = result.scalar()

        # 2. chart_group_mapping 에 매핑 삽입
        if req.role_ids:
            mapping_query = text("""
                INSERT INTO chart_group_mapping (group_id, role_id)
                VALUES (:group_id, :role_id)
            """)
            for r_id in req.role_ids:
                await db.execute(mapping_query, {"group_id": new_group_id, "role_id": r_id})
        
        await db.commit()
        return {"status": "success", "message": "그룹 생성 완료", "group_id": new_group_id}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/groups/{facility_id}/{room_id}")
async def get_chart_groups(facility_id: int, room_id: int, db: AsyncSession = Depends(get_db)):
    """Flutter 앱에서 렌더링할 그룹 리스트 반환"""
    query = text("""
        SELECT cg.id as group_id, cg.group_name, cg.data_type,
               array_agg(cgm.role_id) as role_ids
        FROM chart_group_table cg
        LEFT JOIN chart_group_mapping cgm ON cg.id = cgm.group_id
        WHERE cg.facility_id = :facility_id AND cg.room_id = :room_id
        GROUP BY cg.id
    """)
    result = await db.execute(query, {"facility_id": facility_id, "room_id": room_id})
    groups = [dict(row._mapping) for row in result.fetchall()]
    return {"status": "success", "groups": groups}