from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel, EmailStr
from config.db import get_db
from src.models.User import User

router = APIRouter(prefix="/web-auth", tags=["Web Authentication"])

class WebLoginReq(BaseModel):
    email: EmailStr
    password: str

@router.post("/login", status_code=status.HTTP_200_OK)
async def web_login(req: WebLoginReq, db: AsyncSession = Depends(get_db)):
    # 1. 유저 조회
    result = await db.execute(select(User).where(User.email == req.email))
    user = result.scalars().first()

    if not user:
        raise HTTPException(status_code=404, detail="가입되지 않은 이메일입니다.")
    
    # 2. 비밀번호 검증 (실제 운영시 해시 비교 필요)
    if user.password != req.password: 
        raise HTTPException(status_code=401, detail="비밀번호가 일치하지 않습니다.")

    # 3. 웹용 세션/토큰 발급 및 권한 반환
    return {
        "message": "웹 로그인 성공",
        "access_token": "web_dummy_token_here", # 실제 적용 시 JWT 토큰 생성
        "user": {
            "id": user.id,
            "email": user.email,
            "name": user.name,
            "role": user.role.value
        }
    }