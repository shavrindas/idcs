# ===============================================================
# 경로 : src/module/ServiceWeb/controllers/node_manage_controller.py
# 명세 : 시스템 대 시스템 용 노드 관리 컨트롤러
# ===============================================================
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import joinedload
from pydantic import BaseModel
from typing import Optional

from src.config.database import get_db
from src.module.Core.models.Facility import Facility, FacilityNode
from src.module.Core.security import generate_facility_api_key

router = APIRouter(prefix="/admin/nodes", tags=["ServiceWeb - Nodes"])

class NodeCreateReq(BaseModel):
    facility_id: int
    node_code: str
    node_name: str

class NodeUpdateReq(BaseModel):
    node_name: Optional[str] = None
    facility_id: Optional[int] = None

@router.get("/facilities")
async def get_facilities(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Facility).where(Facility.is_active == True).order_by(Facility.name.asc()))
    facilities = result.scalars().all()
    return {
        "status": "success",
        "data": [{"id": f.id, "name": f.name} for f in facilities]
    }

@router.get("")
async def get_nodes(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(FacilityNode)
        .options(joinedload(FacilityNode.facility))
        .order_by(FacilityNode.id.asc())
    )
    nodes = result.scalars().all()
    return {
        "status": "success",
        "data": [
            {
                "id": n.id,
                "facility_id": n.facility_id,
                "facility_name": n.facility.name if n.facility else f"시설 #{n.facility_id}",
                "node_code": n.node_code,
                "node_name": n.node_name,
                "status": n.status,
                "is_active": n.is_active,
                "last_heartbeat_at": n.last_heartbeat_at.isoformat() if n.last_heartbeat_at else None
            }
            for n in nodes
        ]
    }

@router.post("")
async def create_node(req: NodeCreateReq, db: AsyncSession = Depends(get_db)):
    exists = await db.execute(select(FacilityNode).where(FacilityNode.node_code == req.node_code))
    if exists.scalars().first():
        raise HTTPException(status_code=400, detail="이미 존재하는 노드 코드입니다.")

    raw_key, key_hash = generate_facility_api_key()
    new_node = FacilityNode(
        facility_id=req.facility_id,
        node_code=req.node_code,
        node_name=req.node_name,
        api_key_hash=key_hash,
        status="OFFLINE",
        is_active=True
    )
    db.add(new_node)
    await db.commit()
    await db.refresh(new_node)

    return {
        "status": "success",
        "node_code": new_node.node_code,
        "api_key": raw_key
    }

@router.patch("/{node_id}")
async def update_node(node_id: int, req: NodeUpdateReq, db: AsyncSession = Depends(get_db)):
    """노드 명칭 및 소속 시설 수정"""
    result = await db.execute(select(FacilityNode).where(FacilityNode.id == node_id))
    node = result.scalars().first()
    if not node:
        raise HTTPException(status_code=404, detail="노드를 찾을 수 없습니다.")

    if req.node_name is not None:
        node.node_name = req.node_name.strip()
    if req.facility_id is not None:
        node.facility_id = req.facility_id

    await db.commit()
    return {"status": "success", "message": "노드 정보가 수정되었습니다."}

@router.post("/{node_id}/rotate-key")
async def rotate_key(node_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(FacilityNode).where(FacilityNode.id == node_id))
    node = result.scalars().first()
    if not node:
        raise HTTPException(status_code=404, detail="노드를 찾을 수 없습니다.")

    raw_key, key_hash = generate_facility_api_key()
    node.api_key_hash = key_hash
    await db.commit()

    return {
        "status": "success",
        "new_api_key": raw_key
    }

@router.delete("/{node_id}")
async def delete_node(node_id: int, db: AsyncSession = Depends(get_db)):
    """노드 및 API 키 완전 삭제"""
    result = await db.execute(select(FacilityNode).where(FacilityNode.id == node_id))
    node = result.scalars().first()
    if not node:
        raise HTTPException(status_code=404, detail="노드를 찾을 수 없습니다.")

    await db.delete(node)
    await db.commit()
    return {"status": "success", "message": "노드가 삭제되었습니다."}