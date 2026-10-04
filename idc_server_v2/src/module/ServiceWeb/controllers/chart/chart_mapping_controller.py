# 경로 : src/module/ServiceWeb/controllers/chart/chart_mapping_controller.py
from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from src.config.database import get_db

router = APIRouter(prefix="/chart-mapping", tags=["ServiceWeb - Chart Mapping"])

class GroupCreateReq(BaseModel):
    facility_id: int
    room_id: int
    group_name: str
    role_ids: List[int]

class RoleIndexingItem(BaseModel):
    role_id: int
    display_name: Optional[str] = ""
    short_name: Optional[str] = ""

class RoleIndexingUpdateReq(BaseModel):
    updates: List[RoleIndexingItem]

@router.get("/roles/{facility_id}/{room_id}")
async def get_point_roles(facility_id: int, room_id: int, db: AsyncSession = Depends(get_db)):
    # room_id가 0이면 해당 시설의 공용 호실(000호/공용) 또는 room_id=0 조회
    if room_id == 0:
        query = text("""
            SELECT pr.id as role_id, pr.role_name, pr.target_value,
                   COALESCE(prm.display_name, pr.role_name) as display_name,
                   COALESCE(prm.short_name, pr.role_name) as short_name,
                   prm.data_type
            FROM point_role_table pr
            LEFT JOIN facilities_room_table fr ON pr.room_id = fr.id
            LEFT JOIN point_role_metadata prm ON pr.id = prm.role_id
            WHERE pr.facility_id = :facility_id 
              AND pr.is_current = TRUE
              AND (pr.room_id = 0 OR fr.name LIKE '%000%' OR fr.name LIKE '%공용%')
            ORDER BY pr.id ASC
        """)
        result = await db.execute(query, {"facility_id": facility_id})
    else:
        query = text("""
            SELECT pr.id as role_id, pr.role_name, pr.target_value,
                   COALESCE(prm.display_name, pr.role_name) as display_name,
                   COALESCE(prm.short_name, pr.role_name) as short_name,
                   prm.data_type
            FROM point_role_table pr
            LEFT JOIN point_role_metadata prm ON pr.id = prm.role_id
            WHERE pr.facility_id = :facility_id AND pr.room_id = :room_id AND pr.is_current = TRUE
            ORDER BY pr.id ASC
        """)
        result = await db.execute(query, {"facility_id": facility_id, "room_id": room_id})

    roles = [dict(row._mapping) for row in result.fetchall()]
    return {"status": "success", "roles": roles}

@router.put("/roles/indexing")
async def update_roles_indexing(req: RoleIndexingUpdateReq, db: AsyncSession = Depends(get_db)):
    try:
        for item in req.updates:
            upsert_query = text("""
                INSERT INTO point_role_metadata (role_id, display_name, short_name)
                VALUES (:role_id, :display_name, :short_name)
                ON CONFLICT (role_id) DO UPDATE
                SET display_name = EXCLUDED.display_name,
                    short_name = EXCLUDED.short_name
            """)
            await db.execute(upsert_query, {
                "role_id": item.role_id,
                "display_name": item.display_name.strip() if item.display_name else None,
                "short_name": item.short_name.strip() if item.short_name else None,
            })
        await db.commit()
        return {"status": "success", "message": "인덱싱 업데이트 완료"}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/group")
async def create_chart_group(req: GroupCreateReq, db: AsyncSession = Depends(get_db)):
    try:
        group_query = text("""
            INSERT INTO chart_group_table (facility_id, room_id, group_name)
            VALUES (:facility_id, :room_id, :group_name)
            RETURNING id
        """)
        result = await db.execute(group_query, {
            "facility_id": req.facility_id, 
            "room_id": req.room_id,
            "group_name": req.group_name
        })
        new_group_id = result.scalar()

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
    query = text("""
        SELECT cg.id as group_id, cg.group_name,
               COALESCE(array_agg(cgm.role_id) FILTER (WHERE cgm.role_id IS NOT NULL), '{}') as role_ids
        FROM chart_group_table cg
        LEFT JOIN chart_group_mapping cgm ON cg.id = cgm.group_id
        WHERE cg.facility_id = :facility_id AND cg.room_id = :room_id
        GROUP BY cg.id
        ORDER BY cg.id ASC
    """)
    result = await db.execute(query, {"facility_id": facility_id, "room_id": room_id})
    groups = [dict(row._mapping) for row in result.fetchall()]
    return {"status": "success", "groups": groups}

@router.post("/group/{group_id}/hide-post/{post_id}")
async def hide_post_from_group(group_id: int, post_id: int, db: AsyncSession = Depends(get_db)):
    try:
        query = text("""
            INSERT INTO chart_group_post_blacklist (group_id, post_id)
            VALUES (:group_id, :post_id)
            ON CONFLICT DO NOTHING
        """)
        await db.execute(query, {"group_id": group_id, "post_id": post_id})
        await db.commit()
        return {"status": "success"}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/group/{group_id}/show-post/{post_id}")
async def show_post_in_group(group_id: int, post_id: int, db: AsyncSession = Depends(get_db)):
    try:
        query = text("""
            DELETE FROM chart_group_post_blacklist
            WHERE group_id = :group_id AND post_id = :post_id
        """)
        await db.execute(query, {"group_id": group_id, "post_id": post_id})
        await db.commit()
        return {"status": "success"}
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))