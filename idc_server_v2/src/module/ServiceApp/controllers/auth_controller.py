# ==============================================================
# 경로 : src/module/ServiceApp/controllers/auth_controller.py
# 명세 : 서비스 앱용 인증 컨트롤러
# ==============================================================
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
import jwt
import hashlib
import random
from datetime import datetime, timedelta, timezone

from src.config.database import get_db
from src.module.Core.models.User import User, ExternalProvider, UserRole

router = APIRouter(prefix="/auth", tags=["ServiceApp - Auth"])

SECRET_KEY = "idcool_secret_key_v1" 
ALGORITHM = "HS256"

# --- Schemas ---
class UserCreate(BaseModel):
    email: EmailStr
    password: str
    name: str
    phone_number: Optional[str] = None

class SocialUserCreate(BaseModel):
    email: EmailStr
    name: str
    provider: str
    provider_id: str
    phone_number: Optional[str] = None

class LoginGeneralRequest(BaseModel):
    email: EmailStr
    password: str
    keep_login: bool = False

class LoginSocialRequest(BaseModel):
    provider: str
    provider_id: str
    keep_login: bool = False

class LinkSocialProvider(BaseModel):
    email: EmailStr
    provider: str
    provider_id: str

class CheckAccountRequest(BaseModel):
    email: EmailStr

class FindIdRequest(BaseModel):
    name: str
    phone_number: str

class FindPwRequest(BaseModel):
    name: str
    email: EmailStr
    phone_number: str

class WithdrawRequest(BaseModel):
    user_id: int

class PasswordRequestCode(BaseModel):
    email: EmailStr

class PasswordVerifyCode(BaseModel):
    token: str
    code: str

class PasswordReset(BaseModel):
    token: str
    new_password: str

class UpdateNameRequest(BaseModel):
    name: str

class UpdatePhoneRequest(BaseModel):
    phone_number: str

class UpdatePasswordRequest(BaseModel):
    current_password: str
    new_password: str

def hash_code(code: str) -> str:
    return hashlib.sha256(code.encode()).hexdigest()

# --- Endpoints ---
@router.post("/signup/general", status_code=status.HTTP_201_CREATED)
async def create_general_user(user_in: UserCreate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == user_in.email))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="이미 존재하는 이메일입니다.")

    new_user = User(
        email=user_in.email,
        password=user_in.password,
        name=user_in.name,
        phone_number=user_in.phone_number,
        role=UserRole.USER 
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    return {"message": "일반 계정이 성공적으로 생성되었습니다.", "user_id": new_user.id}

@router.post("/signup/social", status_code=status.HTTP_201_CREATED)
async def create_social_user(user_in: SocialUserCreate, db: AsyncSession = Depends(get_db)):
    if user_in.provider not in ["google", "apple"]:
        raise HTTPException(status_code=400, detail="지원하지 않는 소셜 제공자입니다.")
    result = await db.execute(select(User).where(User.email == user_in.email))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="이미 이메일로 가입된 내역이 있습니다. 일반 로그인 후 연동해주세요.")

    new_user = User(
        email=user_in.email, password=None, name=user_in.name,
        phone_number=user_in.phone_number, role=UserRole.USER
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)

    new_provider = ExternalProvider(
        account_id=new_user.id, provider=user_in.provider, provider_id=user_in.provider_id
    )
    db.add(new_provider)
    await db.commit()
    return {"message": f"{user_in.provider} 연동 계정이 생성되었습니다.", "user_id": new_user.id}

@router.post("/login/general", status_code=status.HTTP_200_OK)
async def login_general(req: LoginGeneralRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == req.email))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="가입되지 않은 이메일입니다.")
    if user.password != req.password: 
        raise HTTPException(status_code=401, detail="비밀번호가 일치하지 않습니다.")

    token_expiry = "30days" if req.keep_login else "1day"
    return {
        "message": "로그인 성공",
        "access_token": "dummy_token_here",
        "user_id": user.id,
        "role": user.role.value if hasattr(user.role, 'value') else user.role,
        "expiry_policy": token_expiry
    }

@router.post("/login/social", status_code=status.HTTP_200_OK)
async def login_social(req: LoginSocialRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(ExternalProvider).where(ExternalProvider.provider == req.provider, ExternalProvider.provider_id == req.provider_id)
    )
    provider_info = result.scalars().first()
    if not provider_info:
        raise HTTPException(status_code=404, detail="연동된 소셜 계정이 없습니다. 회원가입을 진행해주세요.")

    user_result = await db.execute(select(User).where(User.id == provider_info.account_id))
    user = user_result.scalars().first()
    token_expiry = "30days" if req.keep_login else "1day"
    return {
        "message": f"{req.provider} 소셜 로그인 성공",
        "access_token": "dummy_social_token_here",
        "user_id": user.id,
        "expiry_policy": token_expiry
    }

@router.post("/check-account", status_code=status.HTTP_200_OK)
async def check_account_existence(req: CheckAccountRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == req.email))
    user = result.scalars().first()
    if not user:
        return {"exists": False, "message": "해당 이메일로 가입된 계정이 없습니다."}

    providers_result = await db.execute(select(ExternalProvider).where(ExternalProvider.account_id == user.id))
    providers = providers_result.scalars().all()
    if providers:
        provider_names = ", ".join([p.provider for p in providers])
        return {"exists": True, "message": f"해당 이메일은 {provider_names} 소셜 계정으로 연동되어 있습니다."}
    return {"exists": True, "message": "해당 이메일은 일반 계정으로 가입되어 있습니다."}

@router.get("/{user_id}/role", status_code=status.HTTP_200_OK)
async def get_user_role(user_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User.role).where(User.id == user_id))
    user_role = result.scalars().first()
    if not user_role:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    return {"role": user_role.value if hasattr(user_role, 'value') else user_role}

@router.get("/{user_id}/profile", status_code=status.HTTP_200_OK)
async def get_user_profile(user_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    providers_result = await db.execute(select(ExternalProvider.provider).where(ExternalProvider.account_id == user_id))
    return {
        "name": user.name,
        "phone_number": user.phone_number or "",
        "linked_providers": providers_result.scalars().all()
    }