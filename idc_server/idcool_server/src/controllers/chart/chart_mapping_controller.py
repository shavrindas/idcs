from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from config.db import get_db

router = APIRouter(prefix="/chart-mapping", tags=["Chart Mapping"])

# data_type 제거
class GroupCreateReq(BaseModel):
    facility_id: int
    room_id: int
    group_name: str
    role_ids: List[int]

# @router.get("/roles/{facility_id}/{room_id}")
# async def get_point_roles(facility_id: int, room_id: int, db: AsyncSession = Depends(get_db)):
#     query = text("""
#         SELECT pr.id as role_id, pr.role_name, pr.target_value, prm.data_type
#         FROM point_role_table pr
#         LEFT JOIN point_role_metadata prm ON pr.id = prm.role_id
#         WHERE pr.facility_id = :facility_id AND pr.room_id = :room_id AND pr.is_current = TRUE
#     """)
#     result = await db.execute(query, {"facility_id": facility_id, "room_id": room_id})
#     roles = [dict(row._mapping) for row in result.fetchall()]
#     return {"status": "success", "roles": roles}

@router.get("/roles/{facility_id}/{room_id}")
async def get_point_roles(facility_id: int, room_id: int, db: AsyncSession = Depends(get_db)):
    query = text("""
        SELECT 
            pr.id as role_id, 
            pr.role_name,
            COALESCE(NULLIF(prm.display_name, ''), pr.role_name) as display_name,
            COALESCE(NULLIF(prm.short_name, ''), pr.role_name) as short_name,
            pr.target_value, 
            prm.data_type
        FROM point_role_table pr
        LEFT JOIN point_role_metadata prm ON pr.id = prm.role_id
        WHERE pr.facility_id = :facility_id AND pr.room_id = :room_id AND pr.is_current = TRUE
    """)
    result = await db.execute(query, {"facility_id": facility_id, "room_id": room_id})
    roles = [dict(row._mapping) for row in result.fetchall()]
    return {"status": "success", "roles": roles}

@router.post("/group")
async def create_chart_group(req: GroupCreateReq, db: AsyncSession = Depends(get_db)):
    try:
        # data_type 관련 로직 제거
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
    # cg.data_type 제거
    query = text("""
        SELECT cg.id as group_id, cg.group_name,
               array_agg(cgm.role_id) as role_ids
        FROM chart_group_table cg
        LEFT JOIN chart_group_mapping cgm ON cg.id = cgm.group_id
        WHERE cg.facility_id = :facility_id AND cg.room_id = :room_id
        GROUP BY cg.id
    """)
    result = await db.execute(query, {"facility_id": facility_id, "room_id": room_id})
    groups = [dict(row._mapping) for row in result.fetchall()]
    return {"status": "success", "groups": groups}


@router.post("/group/{group_id}/hide-post/{post_id}")
async def hide_post_from_group(group_id: int, post_id: int, db: AsyncSession = Depends(get_db)):
    """특정 차트 그룹에서 해당 소요기록을 숨김(블랙리스트 추가)"""
    # PostgreSQL의 ON CONFLICT DO NOTHING을 사용하여 중복 삽입 에러 방어
    query = text("""
        INSERT INTO post_hidden_chart_groups (post_id, group_id) 
        VALUES (:post_id, :group_id) 
        ON CONFLICT DO NOTHING
    """)
    await db.execute(query, {"post_id": post_id, "group_id": group_id})
    await db.commit()
    return {"status": "success", "message": "해당 기록을 숨겼습니다."}

@router.delete("/group/{group_id}/show-post/{post_id}")
async def show_post_in_group(group_id: int, post_id: int, db: AsyncSession = Depends(get_db)):
    """특정 차트 그룹에서 해당 소요기록 숨김 해제(블랙리스트 복구)"""
    query = text("DELETE FROM post_hidden_chart_groups WHERE post_id = :post_id AND group_id = :group_id")
    await db.execute(query, {"post_id": post_id, "group_id": group_id})
    await db.commit()
    return {"status": "success", "message": "차트에 다시 표시됩니다."}



# ---------------------------------------------------------------------
# 인덱싱용 

class PointRoleIndexUpdateItem(BaseModel):
    role_id: int
    display_name: Optional[str] = None
    short_name: Optional[str] = None

class PointRoleIndexBulkUpdateReq(BaseModel):
    updates: List[PointRoleIndexUpdateItem]

@router.put("/roles/indexing")
async def bulk_update_point_role_indexing(
    req: PointRoleIndexBulkUpdateReq, 
    db: AsyncSession = Depends(get_db)
):
    try:
        upsert_query = text("""
            INSERT INTO point_role_metadata (role_id, display_name, short_name, updated_at)
            VALUES (:role_id, NULLIF(:display_name, ''), NULLIF(:short_name, ''), CURRENT_TIMESTAMP)
            ON CONFLICT (role_id) 
            DO UPDATE SET 
                display_name = EXCLUDED.display_name,
                short_name = EXCLUDED.short_name,
                updated_at = CURRENT_TIMESTAMP
        """)
        for item in req.updates:
            # 3자 제한 검증
            short_val = item.short_name.strip() if item.short_name else None
            if short_val and len(short_val) > 3:
                raise HTTPException(status_code=400, detail=f"약어명은 최대 3자까지 허용됩니다. (Role ID: {item.role_id})")
            
            await db.execute(upsert_query, {
                "role_id": item.role_id,
                "display_name": item.display_name.strip() if item.display_name else None,
                "short_name": short_val
            })

        await db.commit()
        return {"status": "success", "message": f"{len(req.updates)}건의 인덱싱 정보가 저장되었습니다."}
    except HTTPException as he:
        await db.rollback()
        raise he
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))