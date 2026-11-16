# ===============================================================
# 경로 : src/module/ServiceApp/controllers/board_controller.py
# 명세 : 보드(게시판) 관련 API 컨트롤러 (현재 스코프: 리스트 조회)
# ===============================================================
from fastapi import APIRouter, Depends, HTTPException, Query, Body, UploadFile, File, Request
from pydantic import BaseModel
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from src.config.database import get_db
import os
import uuid
from datetime import datetime
from io import BytesIO
from PIL import Image
# ===============================================================

router = APIRouter(prefix="/board", tags=["Board"])

# 업로드된 첨부 이미지를 저장하는 폴더 (idc_server_v2 작업 디렉터리 기준 상대 경로 —
# firebase 키 경로 등 이 프로젝트의 다른 경로들과 같은 방식). app.py가 "/uploads" 로
# 정적 서빙한다.
UPLOAD_ROOT = "uploads"
MAX_IMAGE_BYTES = 10 * 1024 * 1024  # 10MB
MAX_IMAGE_SIDE = 1920  # 이보다 큰 변을 가진 이미지는 이 크기로 줄인다.

# --- Pydantic Schemas ---
class PostCreateReq(BaseModel):
    # 프론트는 board_id를 모른다 — 시설 하나에 보드 하나가 1:1로 묶여 있고,
    # 프론트가 들고 있는 건 facility_id뿐이라서 그걸 받아 보드를 찾거나 만든다.
    facility_id: int
    title: str
    content: str
    image_ids: List[int] = []  # URL 배열 대신, 사전 업로드된 이미지 ID 배열을 받음

class PostUpdateReq(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    image_ids: Optional[List[int]] = None

class CommentCreateReq(BaseModel):
    content: str



# [S/bp-02] 통합 조회 보드 포스트 리스트 (검색 조건 추가)
@router.get("/integrated")
async def get_integrated_posts(
    user_id: int, 
    page: int = Query(1, ge=1), 
    limit: int = Query(30, le=100),
    search_type: str = Query("all"), # all, title, creator, content
    keyword: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db)
):
    user_query = text("SELECT role FROM user_table WHERE id = :user_id")
    user_res = await db.execute(user_query, {"user_id": user_id})
    user = user_res.fetchone()

    if not user or user.role not in ['ADMIN', 'DEVELOPER']:
        raise HTTPException(status_code=403, detail="통합 조회 보드에 접근할 권한이 없습니다.")

    offset = (page - 1) * limit

    # 검색 쿼리 조건 생성
    where_clause = "WHERE 1=1"
    params = {"limit": limit, "offset": offset, "user_id": user_id}

    if keyword and keyword.strip():
        params["keyword"] = f"%{keyword.strip()}%"
        if search_type == "title":
            where_clause += " AND p.title ILIKE :keyword"
        elif search_type == "creator":
            where_clause += " AND u.name ILIKE :keyword"
        elif search_type == "content":
            where_clause += " AND p.content ILIKE :keyword"
        else: # "all"
            where_clause += " AND (p.title ILIKE :keyword OR u.name ILIKE :keyword OR p.content ILIKE :keyword)"

    # COUNT 쿼리
    count_query = text(f"""
        SELECT COUNT(*) 
        FROM posts p
        JOIN boards b ON p.board_id = b.board_id
        JOIN user_table u ON p.creator_id = u.id
        {where_clause}
    """)
    total_count = (await db.execute(count_query, params)).scalar()

    # Data 쿼리
    query = text(f"""
        SELECT p.post_id, p.title, p.content, p.creator_id, p.created_at,
               b.facility_id, b.facility_name, u.name as creator_name
        FROM posts p
        JOIN boards b ON p.board_id = b.board_id
        JOIN user_table u ON p.creator_id = u.id
        {where_clause}
        ORDER BY p.created_at DESC
        LIMIT :limit OFFSET :offset
    """)
    result = await db.execute(query, params)
    posts = result.fetchall()

    return {
        "status": "success",
        "data": [dict(row._mapping) for row in posts],
        "meta": {
            "page": page,
            "limit": limit,
            "total_count": total_count,
            "total_pages": (total_count + limit - 1) // limit
        }
    }


# [S/bp-03] 시설 조회 보드 포스트 리스트 (검색 조건 추가)
@router.get("/facility/{facility_id}")
async def get_facility_posts(
    facility_id: int, 
    user_id: int, 
    page: int = Query(1, ge=1), 
    limit: int = Query(30, le=100),
    search_type: str = Query("all"),
    keyword: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db)
):
    auth_query = text("""
        SELECT 1 FROM user_table u
        LEFT JOIN facility_users fu ON u.id = fu.user_id AND fu.facility_id = :facility_id
        WHERE u.id = :user_id 
          AND (u.role IN ('ADMIN', 'DEVELOPER') OR fu.id IS NOT NULL)
    """)
    auth_res = await db.execute(auth_query, {"user_id": user_id, "facility_id": facility_id})
    if not auth_res.fetchone():
        raise HTTPException(status_code=403, detail="해당 시설 보드에 접근할 권한이 없습니다.")

    offset = (page - 1) * limit
    where_clause = "WHERE b.facility_id = :facility_id"
    params = {"facility_id": facility_id, "limit": limit, "offset": offset, "user_id": user_id}

    if keyword and keyword.strip():
        params["keyword"] = f"%{keyword.strip()}%"
        if search_type == "title":
            where_clause += " AND p.title ILIKE :keyword"
        elif search_type == "creator":
            where_clause += " AND u.name ILIKE :keyword"
        elif search_type == "content":
            where_clause += " AND p.content ILIKE :keyword"
        else: # "all"
            where_clause += " AND (p.title ILIKE :keyword OR u.name ILIKE :keyword OR p.content ILIKE :keyword)"

    count_query = text(f"""
        SELECT COUNT(*) 
        FROM posts p 
        JOIN boards b ON p.board_id = b.board_id 
        JOIN user_table u ON p.creator_id = u.id
        {where_clause}
    """)
    total_count = (await db.execute(count_query, params)).scalar()

    query = text(f"""
        SELECT p.post_id, p.title, p.content, p.creator_id, p.created_at,
               b.facility_id, b.facility_name, u.name as creator_name
        FROM posts p
        JOIN boards b ON p.board_id = b.board_id
        JOIN user_table u ON p.creator_id = u.id
        {where_clause}
        ORDER BY p.created_at DESC
        LIMIT :limit OFFSET :offset
    """)
    result = await db.execute(query, params)
    posts = result.fetchall()

    return {
        "status": "success",
        "data": [dict(row._mapping) for row in posts],
        "meta": {
            "page": page,
            "limit": limit,
            "total_count": total_count,
            "total_pages": (total_count + limit - 1) // limit
        }
    }


# ===============================================================
# [S/bp-04] 단일 포스트 상세 조회 (댓글 포함)
# ===============================================================
@router.get("/post/{post_id}")
async def get_post_detail(post_id: int, user_id: int, db: AsyncSession = Depends(get_db)):
    # 1. 포스트 기본 정보 조회 (p.images 제거)
    post_query = text("""
        SELECT p.post_id, p.title, p.content, p.creator_id, p.created_at, p.updated_at,
               b.facility_id, b.facility_name, u.name as creator_name
        FROM posts p
        JOIN boards b ON p.board_id = b.board_id
        JOIN user_table u ON p.creator_id = u.id
        WHERE p.post_id = :post_id
    """)
    post = (await db.execute(post_query, {"post_id": post_id})).fetchone()

    if not post:
        raise HTTPException(status_code=404, detail="포스트를 찾을 수 없습니다.")

    # 2. 권한 검증
    auth_query = text("""
        SELECT 1 FROM user_table u
        LEFT JOIN facility_users fu ON u.id = fu.user_id AND fu.facility_id = :facility_id
        WHERE u.id = :user_id AND (u.role IN ('ADMIN', 'DEVELOPER') OR fu.id IS NOT NULL)
    """)
    if not (await db.execute(auth_query, {"user_id": user_id, "facility_id": post.facility_id})).fetchone():
        raise HTTPException(status_code=403, detail="조회 권한이 없습니다.")

    # 3. 댓글 목록 같이 조회
    comment_query = text("""
        SELECT c.comment_id, c.content, c.creator_id, c.created_at, u.name as creator_name
        FROM comments c
        JOIN user_table u ON c.creator_id = u.id
        WHERE c.post_id = :post_id
        ORDER BY c.created_at ASC
    """)
    comments = (await db.execute(comment_query, {"post_id": post_id})).fetchall()

    return {
        "status": "success",
        "data": dict(post._mapping),
        "comments": [dict(c._mapping) for c in comments]
    }


# ===============================================================
# [S/bp-09] 에디터용 이미지 사전 업로드 (Pre-upload) API 명세
# ===============================================================
@router.post("/image/upload")
async def upload_post_image(
    request: Request,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db)
):
    """
    에디터에서 사진을 고르는 즉시(글을 저장하기 전에) 올리는 사전 업로드.
    1. 용량 검증 (10MB 이하)
    2. Pillow로 이미지 메타데이터(Width/Height) 추출, 긴 변이 Max Scale(1920px)을
       넘으면 비율을 지켜 줄인다.
    3. 로컬 디스크에 [uploads]/[YYYY]/[MM]/[DD]/[UUID].[ext] 로 저장
    4. post_images 테이블에 post_id=NULL 로 INSERT 후 image_id 및 image_url 반환
       (글이 실제로 저장될 때 /board/post 가 이 image_id를 post_id에 연결한다)
    """
    raw = await file.read()
    if len(raw) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=413, detail="이미지 용량은 10MB를 넘을 수 없습니다.")

    try:
        image = Image.open(BytesIO(raw))
        image.load()
    except Exception:
        raise HTTPException(status_code=400, detail="이미지 파일을 읽을 수 없습니다.")

    width, height = image.size
    if width <= 0 or height <= 0:
        raise HTTPException(status_code=400, detail="이미지 크기를 확인할 수 없습니다.")

    longer_side = max(width, height)
    if longer_side > MAX_IMAGE_SIDE:
        scale = MAX_IMAGE_SIDE / longer_side
        width, height = max(1, round(width * scale)), max(1, round(height * scale))
        image = image.convert("RGB") if image.mode in ("P", "CMYK") else image
        image = image.resize((width, height), Image.LANCZOS)

    original_name = file.filename or "image"
    ext = os.path.splitext(original_name)[1].lower().lstrip(".") or "jpg"
    if ext not in ("jpg", "jpeg", "png", "webp", "gif"):
        ext = "jpg"

    today = datetime.now()
    rel_dir = os.path.join(today.strftime("%Y"), today.strftime("%m"), today.strftime("%d"))
    abs_dir = os.path.join(UPLOAD_ROOT, rel_dir)
    os.makedirs(abs_dir, exist_ok=True)

    filename = f"{uuid.uuid4().hex}.{ext}"
    abs_path = os.path.join(abs_dir, filename)
    save_format = "JPEG" if ext in ("jpg", "jpeg") else ext.upper()
    if save_format == "JPEG" and image.mode in ("RGBA", "P"):
        image = image.convert("RGB")
    image.save(abs_path, format=save_format)

    file_size = os.path.getsize(abs_path)
    aspect_ratio = round(width / height, 2) if height else 0

    rel_url_path = "/".join(["uploads", rel_dir.replace("\\", "/"), filename])
    image_url = f"{str(request.base_url).rstrip('/')}/{rel_url_path}"

    insert_query = text("""
        INSERT INTO post_images (post_id, image_url, original_name, file_size, width, height, aspect_ratio)
        VALUES (NULL, :image_url, :original_name, :file_size, :width, :height, :aspect_ratio)
        RETURNING image_id
    """)
    result = await db.execute(insert_query, {
        "image_url": image_url,
        "original_name": original_name,
        "file_size": file_size,
        "width": width,
        "height": height,
        "aspect_ratio": aspect_ratio,
    })
    image_id = result.scalar()
    await db.commit()

    return {
        "status": "success",
        "image_id": image_id,
        "image_url": image_url,
    }


# ===============================================================
# [S/bp-05] 포스트 생성
# ===============================================================
@router.post("/post")
async def create_post(user_id: int, req: PostCreateReq, db: AsyncSession = Depends(get_db)):
    # 0. 이 시설의 보드를 찾는다 — 시설마다 보드가 하나씩 자동으로 있어야
    # 하는데, 아직 한 번도 글이 없던 시설이면 보드 행 자체가 안 만들어져
    # 있을 수 있다. 그럴 땐 그 자리에서 만든다.
    board_row = (await db.execute(
        text("SELECT board_id FROM boards WHERE facility_id = :facility_id"),
        {"facility_id": req.facility_id},
    )).fetchone()

    if board_row:
        board_id = board_row.board_id
    else:
        facility_row = (await db.execute(
            text("SELECT name FROM facilities_table WHERE id = :facility_id"),
            {"facility_id": req.facility_id},
        )).fetchone()
        if not facility_row:
            raise HTTPException(status_code=404, detail="시설을 찾을 수 없습니다.")

        new_board = (await db.execute(
            text("""
                INSERT INTO boards (facility_id, facility_name)
                VALUES (:facility_id, :facility_name)
                RETURNING board_id
            """),
            {"facility_id": req.facility_id, "facility_name": facility_row.name},
        )).fetchone()
        board_id = new_board.board_id

    # 1. 포스트 삽입
    query = text("""
        INSERT INTO posts (board_id, creator_id, updater_id, title, content)
        VALUES (:board_id, :user_id, :user_id, :title, :content)
        RETURNING post_id
    """)
    result = await db.execute(query, {
        "board_id": board_id,
        "user_id": user_id,
        "title": req.title,
        "content": req.content
    })
    new_post_id = result.scalar()

    # 2. 선(Pre) 업로드된 이미지 ID 맵핑 (임시로 post_id=NULL 이었던 것을 업데이트)
    if req.image_ids:
        mapping_query = text("""
            UPDATE post_images 
            SET post_id = :post_id 
            WHERE image_id = ANY(:image_ids)
        """)
        await db.execute(mapping_query, {"post_id": new_post_id, "image_ids": req.image_ids})
        
    await db.commit()
    return {"status": "success", "post_id": new_post_id}

# ===============================================================
# [S/bp-06] 포스트 수정
# ===============================================================
@router.put("/post/{post_id}")
async def update_post(post_id: int, user_id: int, req: PostUpdateReq, db: AsyncSession = Depends(get_db)):
    # 1. 작성자 본인 확인
    check_query = text("SELECT creator_id FROM posts WHERE post_id = :post_id")
    post = (await db.execute(check_query, {"post_id": post_id})).fetchone()
    if not post or post.creator_id != user_id:
        raise HTTPException(status_code=403, detail="수정 권한이 없습니다.")

    # 2. 포스트 업데이트
    update_query = text("""
        UPDATE posts 
        SET title = COALESCE(:title, title),
            content = COALESCE(:content, content),
            updater_id = :user_id
        WHERE post_id = :post_id
    """)
    await db.execute(update_query, {
        "title": req.title, 
        "content": req.content, 
        "user_id": user_id, 
        "post_id": post_id
    })

    # 3. 추가된 이미지가 있다면 맵핑
    if req.image_ids:
        mapping_query = text("""
            UPDATE post_images 
            SET post_id = :post_id 
            WHERE image_id = ANY(:image_ids)
        """)
        await db.execute(mapping_query, {"post_id": post_id, "image_ids": req.image_ids})

    await db.commit()
    return {"status": "success", "message": "포스트 수정 완료"}

# ===============================================================
# [S/bp-07] 포스트 삭제
# ===============================================================
@router.delete("/post/{post_id}")
async def delete_post(post_id: int, user_id: int, db: AsyncSession = Depends(get_db)):
    check_query = text("""
        SELECT p.creator_id, u.role 
        FROM posts p JOIN user_table u ON u.id = :user_id 
        WHERE p.post_id = :post_id
    """)
    post = (await db.execute(check_query, {"post_id": post_id, "user_id": user_id})).fetchone()
    
    # 작성자 본인이거나 관리자(ADMIN, DEVELOPER)인 경우 삭제 허용
    if not post or (post.creator_id != user_id and post.role not in ['ADMIN', 'DEVELOPER']):
        raise HTTPException(status_code=403, detail="삭제 권한이 없습니다.")

    # ON DELETE CASCADE로 인해 comments, post_images 등도 자동 삭제됨
    await db.execute(text("DELETE FROM posts WHERE post_id = :post_id"), {"post_id": post_id})
    await db.commit()
    return {"status": "success", "message": "포스트 삭제 완료"}

# ===============================================================
# [S/bp-08] 댓글 생성 및 삭제
# ===============================================================
@router.post("/post/{post_id}/comment")
async def create_comment(post_id: int, user_id: int, req: CommentCreateReq, db: AsyncSession = Depends(get_db)):
    query = text("""
        INSERT INTO comments (post_id, creator_id, content)
        VALUES (:post_id, :user_id, :content)
        RETURNING comment_id
    """)
    result = await db.execute(query, {"post_id": post_id, "user_id": user_id, "content": req.content})
    await db.commit()
    return {"status": "success", "comment_id": result.scalar()}

@router.delete("/comment/{comment_id}")
async def delete_comment(comment_id: int, user_id: int, db: AsyncSession = Depends(get_db)):
    check_query = text("""
        SELECT c.creator_id, u.role 
        FROM comments c JOIN user_table u ON u.id = :user_id 
        WHERE c.comment_id = :comment_id
    """)
    comment = (await db.execute(check_query, {"comment_id": comment_id, "user_id": user_id})).fetchone()
    
    if not comment or (comment.creator_id != user_id and comment.role not in ['ADMIN', 'DEVELOPER']):
        raise HTTPException(status_code=403, detail="삭제 권한이 없습니다.")

    await db.execute(text("DELETE FROM comments WHERE comment_id = :comment_id"), {"comment_id": comment_id})
    await db.commit()
    return {"status": "success", "message": "댓글 삭제 완료"}