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
import secrets
import string
import random
from datetime import datetime, timedelta, timezone

from src.config.database import get_db
from src.module.Core.models.User import User, ExternalProvider, UserRole
from src.module.Core.email_service import send_email, build_verification_code_email

router = APIRouter(prefix="/auth", tags=["ServiceApp - Auth"])

SECRET_KEY = "idcool_secret_key_v1"
ALGORITHM = "HS256"

# 비밀번호 재설정: 1차 코드 토큰, 2차 재설정 토큰 각각의 유효시간.
PASSWORD_CODE_EXPIRE_MINUTES = 5
PASSWORD_RESET_EXPIRE_MINUTES = 10

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
@router.post("/signup/social", status_code=status.HTTP_201_CREATED)
async def create_social_user(user_in: SocialUserCreate, db: AsyncSession = Depends(get_db)):
    if user_in.provider not in ["google", "apple"]:
        raise HTTPException(status_code=400, detail="지원하지 않는 소셜 제공자입니다.")
    result = await db.execute(select(User).where(User.email == user_in.email))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="이미 이메일로 가입된 내역이 있습니다. 일반 로그인 후 연동해주세요.")

    code = generate_user_code()
    while (await db.execute(select(User).where(User.user_code == code))).scalars().first():
        code = generate_user_code()

    new_user = User(
        email=user_in.email, password=None, name=user_in.name,
        phone_number=user_in.phone_number, role=UserRole.USER, user_code=code
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

    msg = ""
    if user.role == UserRole.ADMIN:
        msg = "해당 이메일은 관리자 계정으로 가입되어 있습니다."
    else:
        msg = "해당 이메일은 일반 계정으로 가입되어 있습니다."
    return {"exists": True, "message": msg}

@router.post("/password/request-code", status_code=status.HTTP_200_OK)
async def request_password_code(req: PasswordRequestCode, db: AsyncSession = Depends(get_db)):
    """[Box #1] 가입된 이메일로 6자리 인증코드 발송. 코드 자체는 저장하지 않고,
    해시만 JWT 안에 담아 돌려준다 — 서버가 상태를 들고 있지 않아도 된다."""
    result = await db.execute(select(User).where(User.email == req.email))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="가입되지 않은 이메일입니다.")

    code = f"{secrets.randbelow(1_000_000):06d}"
    expire = datetime.now(timezone.utc) + timedelta(minutes=PASSWORD_CODE_EXPIRE_MINUTES)
    token = jwt.encode(
        {"email": req.email, "code_hash": hash_code(code), "type": "pw_code", "exp": expire},
        SECRET_KEY, algorithm=ALGORITHM,
    )

    send_email(
        req.email,
        "[IDCool Systems] 비밀번호 재설정 인증코드",
        f"인증코드: {code}\n{PASSWORD_CODE_EXPIRE_MINUTES}분 안에 입력해 주세요.",
        html_body=build_verification_code_email(code, PASSWORD_CODE_EXPIRE_MINUTES),
    )
    return {"token": token, "message": "인증코드를 이메일로 보냈습니다."}

@router.post("/password/verify-code", status_code=status.HTTP_200_OK)
async def verify_password_code(req: PasswordVerifyCode):
    """[Box #2] 코드 확인. 맞으면 실제 비밀번호 변경에 쓸 별도 토큰을 새로 발급한다
    — 1차 토큰은 코드 검증에만 쓰이고, 그 후로는 더 쓰이지 않는다."""
    try:
        payload = jwt.decode(req.token, SECRET_KEY, algorithms=[ALGORITHM])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=400, detail="인증코드가 만료되었습니다. 다시 요청해 주세요.")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=400, detail="유효하지 않은 요청입니다.")

    if payload.get("type") != "pw_code":
        raise HTTPException(status_code=400, detail="유효하지 않은 요청입니다.")
    if hash_code(req.code) != payload.get("code_hash"):
        raise HTTPException(status_code=400, detail="인증코드가 일치하지 않습니다.")

    expire = datetime.now(timezone.utc) + timedelta(minutes=PASSWORD_RESET_EXPIRE_MINUTES)
    reset_token = jwt.encode(
        {"email": payload["email"], "type": "pw_reset", "exp": expire},
        SECRET_KEY, algorithm=ALGORITHM,
    )
    return {"reset_token": reset_token, "message": "인증이 완료되었습니다."}

@router.post("/password/reset", status_code=status.HTTP_200_OK)
async def reset_password(req: PasswordReset, db: AsyncSession = Depends(get_db)):
    """[Box #3] 새 비밀번호 저장. reset_token은 코드 검증을 거쳐야만 발급되므로,
    이 단계에서 이메일을 다시 확인할 필요는 없다."""
    try:
        payload = jwt.decode(req.token, SECRET_KEY, algorithms=[ALGORITHM])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=400, detail="요청이 만료되었습니다. 처음부터 다시 시도해 주세요.")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=400, detail="유효하지 않은 요청입니다.")

    if payload.get("type") != "pw_reset":
        raise HTTPException(status_code=400, detail="유효하지 않은 요청입니다.")

    result = await db.execute(select(User).where(User.email == payload["email"]))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

    user.password = req.new_password
    await db.commit()
    return {"message": "비밀번호가 변경되었습니다."}

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
        "user_code": user.user_code or "", 
        "linked_providers": providers_result.scalars().all()
    }



def generate_user_code() -> str:
    """직원 초대 등에 쓰는 사람이 직접 불러주기 쉬운 짧은 코드. 알파벳 2자 + 숫자 4자."""
    letters = ''.join(secrets.choice(string.ascii_uppercase) for _ in range(2))
    digits = ''.join(secrets.choice(string.digits) for _ in range(4))
    return letters + digits

@router.post("/signup/general", status_code=status.HTTP_201_CREATED)
async def create_general_user(user_in: UserCreate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == user_in.email))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="이미 존재하는 이메일입니다.")

    # 유저 코드 생성 및 중복 방지
    code = generate_user_code()
    while (await db.execute(select(User).where(User.user_code == code))).scalars().first():
        code = generate_user_code()

    new_user = User(
        email=user_in.email,
        password=user_in.password,
        name=user_in.name,
        phone_number=user_in.phone_number,
        role=UserRole.USER,
        user_code=code
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    return {"message": "일반 계정이 성공적으로 생성되었습니다.", "user_id": new_user.id, "user_code": code}

@router.delete("/withdraw", status_code=status.HTTP_200_OK)
async def withdraw(req: WithdrawRequest, db: AsyncSession = Depends(get_db)):
    """[앱 전용] 회원 탈퇴. 관련 시설/채팅/연동 정보는 외래 키 설정에 따라 함께 정리된다."""
    user = (await db.execute(select(User).where(User.id == req.user_id))).scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

    await db.delete(user)
    await db.commit()
    return {"message": "회원 탈퇴가 완료되었습니다."}

@router.put("/{user_id}/name", status_code=status.HTTP_200_OK)
async def update_user_name(user_id: int, req: UpdateNameRequest, db: AsyncSession = Depends(get_db)):
    """Box #2: 이름(username) 수정"""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    
    user.name = req.name
    await db.commit()
    return {"message": "아이디(이름)가 성공적으로 변경되었습니다."}

@router.put("/{user_id}/phone", status_code=status.HTTP_200_OK)
async def update_user_phone(user_id: int, req: UpdatePhoneRequest, db: AsyncSession = Depends(get_db)):
    """Box #3: 전화번호 등록 및 수정"""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    
    user.phone_number = req.phone_number
    await db.commit()
    return {"message": "전화번호가 성공적으로 변경되었습니다."}

@router.put("/{user_id}/password", status_code=status.HTTP_200_OK)
async def update_user_password(user_id: int, req: UpdatePasswordRequest, db: AsyncSession = Depends(get_db)):
    """Box #4: 비밀번호 수정"""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    
    # TODO: 실제로는 해시된 비밀번호를 비교(verify)해야 합니다.
    if user.password != req.current_password:
        raise HTTPException(status_code=400, detail="현재 비밀번호가 일치하지 않습니다.")
    
    # TODO: req.new_password를 해싱하여 저장해야 합니다.
    user.password = req.new_password
    await db.commit()
    return {"message": "비밀번호가 성공적으로 변경되었습니다."}