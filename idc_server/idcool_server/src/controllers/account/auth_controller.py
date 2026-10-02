# ===============================================================
# 경로 : src/controllers/account/auth_controller.py
# 명세 : 유저 계정 생성 및 소셜 연동, 로그인 API
# ===============================================================
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from typing import Optional
from src.models.User import User, ExternalProvider, UserRole
from config.db import get_db
from pydantic import BaseModel, EmailStr
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from fastapi import APIRouter, Depends, HTTPException, status
from src.models.User import User, ExternalProvider

from pydantic import BaseModel
import jwt
import hashlib
import random
from datetime import datetime, timedelta, timezone


router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)


# ---------------------------------------------------------------

# TODO: 실제 환경에서는 환경변수(.env)로 분리해야 합니다.
SECRET_KEY = "idcool_secret_key_v1" 
ALGORITHM = "HS256"

# ---------------------------------------------------------------
# Pydantic Schemas (요청 모델)
# ---------------------------------------------------------------

class LoginGeneralRequest(BaseModel):
    email: EmailStr
    password: str
    keep_login: bool = False  # Box #3 (로그인 상태 유지) 연동

class LoginSocialRequest(BaseModel):
    provider: str
    provider_id: str
    keep_login: bool = False  # Box #3 (로그인 상태 유지) 연동

class FindIdRequest(BaseModel):
    name: str
    phone_number: str

class FindPwRequest(BaseModel):
    name: str
    email: EmailStr
    phone_number: str

class WithdrawRequest(BaseModel):
    user_id: int

class CheckAccountRequest(BaseModel):
    email: EmailStr

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


# ---------------------------------------------------------------
# Pydantic Schemas (요청/응답 모델)
# ---------------------------------------------------------------
class UserCreate(BaseModel):
    email: EmailStr
    password: str
    name: str
    phone_number: Optional[str] = None

class SocialUserCreate(BaseModel):
    email: EmailStr
    name: str
    provider: str # "google" 또는 "apple"
    provider_id: str
    phone_number: Optional[str] = None

class LinkSocialProvider(BaseModel):
    email: EmailStr # 실제 환경에서는 JWT 토큰에서 추출한 user_id를 사용하는 것이 안전합니다.
    provider: str
    provider_id: str

# ---------------------------------------------------------------
# API Endpoints
# ---------------------------------------------------------------

@router.post("/signup/general", status_code=status.HTTP_201_CREATED)
async def create_general_user(user_in: UserCreate, db: AsyncSession = Depends(get_db)):
    """Box #1: 일반 계정 생성 (비동기 처리)"""
    
    # 1. 이메일 중복 체크
    result = await db.execute(select(User).where(User.email == user_in.email))
    existing_user = result.scalars().first()
    if existing_user:
        raise HTTPException(status_code=400, detail="이미 존재하는 이메일입니다.")

    # TODO: 실제 구현 시 password는 반드시 해싱 처리해야 합니다.
    hashed_password = user_in.password 

    # 2. 유저 생성 (권한은 USER 고정)
    new_user = User(
        email=user_in.email,
        password=hashed_password,
        name=user_in.name, # 프런트의 '아이디(필수)'에 해당
        phone_number=user_in.phone_number,
        role=UserRole.USER 
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    
    return {"message": "일반 계정이 성공적으로 생성되었습니다.", "user_id": new_user.id}


@router.post("/signup/social", status_code=status.HTTP_201_CREATED)
async def create_social_user(user_in: SocialUserCreate, db: AsyncSession = Depends(get_db)):
    """Box #2: 구글/애플 연동 계정 생성 (비동기 처리)"""
    
    if user_in.provider not in ["google", "apple"]:
        raise HTTPException(status_code=400, detail="지원하지 않는 소셜 제공자입니다.")

    result = await db.execute(select(User).where(User.email == user_in.email))
    existing_user = result.scalars().first()
    if existing_user:
        raise HTTPException(status_code=400, detail="이미 이메일로 가입된 내역이 있습니다. 일반 로그인 후 연동해주세요.")

    # 1. 유저 생성 (비밀번호 NULL)
    new_user = User(
        email=user_in.email,
        password=None, 
        name=user_in.name,
        phone_number=user_in.phone_number,
        role=UserRole.USER
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)

    # 2. 소셜 연동 정보 추가
    new_provider = ExternalProvider(
        account_id=new_user.id,
        provider=user_in.provider,
        provider_id=user_in.provider_id
    )
    db.add(new_provider)
    await db.commit()

    return {"message": f"{user_in.provider} 연동 계정이 생성되었습니다.", "user_id": new_user.id}


@router.post("/link-social", status_code=status.HTTP_200_OK)
async def link_social_to_general(link_in: LinkSocialProvider, db: AsyncSession = Depends(get_db)):
    """기존 계정에 소셜 연동 추가 (비동기 처리)"""
    if link_in.provider not in ["google", "apple"]:
        raise HTTPException(status_code=400, detail="지원하지 않는 소셜 제공자입니다.")

    result = await db.execute(select(User).where(User.email == link_in.email))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

    existing_provider_result = await db.execute(
        select(ExternalProvider).where(
            ExternalProvider.account_id == user.id,
            ExternalProvider.provider == link_in.provider
        )
    )
    if existing_provider_result.scalars().first():
        raise HTTPException(status_code=400, detail="이미 해당 소셜 계정이 연동되어 있습니다.")

    new_provider = ExternalProvider(
        account_id=user.id,
        provider=link_in.provider,
        provider_id=link_in.provider_id
    )
    db.add(new_provider)
    await db.commit()

    return {"message": f"계정에 {link_in.provider} 연동이 완료되었습니다."}




@router.post("/login/general", status_code=status.HTTP_200_OK)
async def login_general(req: LoginGeneralRequest, db: AsyncSession = Depends(get_db)):
    """Box #1: 일반 로그인 처리 (Box #3 로그인 유지 여부 포함)"""
    
    # 1. 유저 조회 (비동기 처리)
    result = await db.execute(select(User).where(User.email == req.email))
    user = result.scalars().first()

    if not user:
        raise HTTPException(status_code=404, detail="가입되지 않은 이메일입니다.")
    
    # 2. 비밀번호 검증 (실제로는 pwd_context.verify 등을 사용해야 함)
    if user.password != req.password: # TODO: 해시 비교 로직으로 변경
        raise HTTPException(status_code=401, detail="비밀번호가 일치하지 않습니다.")

    # 3. 로그인 상태 유지 여부에 따른 토큰 만료 시간 설정
    token_expiry = "30days" if req.keep_login else "1day"

    # TODO: JWT 토큰 생성 및 반환
    return {
        "message": "로그인 성공",
        "access_token": "dummy_token_here",
        "user_id": user.id,
        "role": user.role,
        "expiry_policy": token_expiry
    }


@router.post("/login/social", status_code=status.HTTP_200_OK)
async def login_social(req: LoginSocialRequest, db: AsyncSession = Depends(get_db)):
    """Box #2: 소셜 로그인 처리"""
    
    # 1. 외부 프로바이더 연동 정보 조회
    result = await db.execute(
        select(ExternalProvider).where(
            ExternalProvider.provider == req.provider,
            ExternalProvider.provider_id == req.provider_id
        )
    )
    provider_info = result.scalars().first()

    if not provider_info:
        # 연동 정보가 없으면 프런트에서 회원가입(Box #4) 페이지로 리다이렉트 하도록 유도
        raise HTTPException(status_code=404, detail="연동된 소셜 계정이 없습니다. 회원가입을 진행해주세요.")

    # 2. 유저 정보 획득
    user_result = await db.execute(select(User).where(User.id == provider_info.account_id))
    user = user_result.scalars().first()

    token_expiry = "30days" if req.keep_login else "1day"

    return {
        "message": f"{req.provider} 소셜 로그인 성공",
        "access_token": "dummy_social_token_here",
        "user_id": user.id,
        "expiry_policy": token_expiry
    }


@router.post("/find-id", status_code=status.HTTP_200_OK)
async def find_id(req: FindIdRequest, db: AsyncSession = Depends(get_db)):
    """Box #5: 아이디(이메일) 찾기"""
    
    result = await db.execute(
        select(User).where(
            User.name == req.name,
            User.phone_number == req.phone_number
        )
    )
    user = result.scalars().first()

    if not user:
        raise HTTPException(status_code=404, detail="일치하는 계정 정보가 없습니다.")

    # 보안을 위해 이메일 일부 마스킹 처리 (예: test***@gmail.com)
    email_parts = user.email.split("@")
    masked_id = email_parts[0][:3] + "***" if len(email_parts[0]) > 3 else email_parts[0][:1] + "***"
    masked_email = f"{masked_id}@{email_parts[1]}"

    return {"message": "아이디 찾기 성공", "email": masked_email}


@router.post("/find-pw", status_code=status.HTTP_200_OK)
async def find_pw(req: FindPwRequest, db: AsyncSession = Depends(get_db)):
    """Box #6: 비밀번호 찾기 (임시 비밀번호 발급 방식 예시)"""
    
    result = await db.execute(
        select(User).where(
            User.name == req.name,
            User.email == req.email,
            User.phone_number == req.phone_number
        )
    )
    user = result.scalars().first()

    if not user:
        raise HTTPException(status_code=404, detail="입력하신 정보와 일치하는 계정이 없습니다.")

    # TODO: 난수로 임시 비밀번호 생성 -> 해싱 후 DB 업데이트 -> 이메일 또는 SMS로 발송
    temp_password = "temp1234!" 
    
    return {"message": "입력하신 이메일/연락처로 임시 비밀번호가 발송되었습니다. (테스트 환경이므로 실제 발송은 생략)"}




@router.delete("/withdraw", status_code=status.HTTP_200_OK)
async def withdraw_account(req: WithdrawRequest, db: AsyncSession = Depends(get_db)):
    """
    [통합 계정 탈퇴 API] 일반, 구글, 애플 공통
    
    TODO (추후 세션 적용 시):
    1. 보안: 현재는 req body로 user_id를 받지만, 실제 배포 시에는 Depends(get_current_user)를 통해 검증된 JWT에서 추출해야 합니다.
    2. 애플 완전 탈퇴(Revoke): 애플 정책상 앱 내 탈퇴 시 백엔드에서 Apple Auth Server의 'Revoke Token API'를 호출하여 토큰을 만료시켜야 합니다.
       (참고: httpx 등으로 https://appleid.apple.com/auth/revoke 호출 로직이 이곳에 추가되어야 함)
    """
    result = await db.execute(select(User).where(User.id == req.user_id))
    user = result.scalars().first()

    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

    # DB에 CASCADE가 설정되어 있으므로, user_table에서 삭제 시 
    # 연동된 external_providers 및 facility_users의 정보도 자동(연쇄) 삭제됩니다.
    await db.delete(user)
    await db.commit()

    return {"message": "계정이 성공적으로 탈퇴 처리되었습니다."}


# Pydantic Schemas 상단에 추가
class CheckAccountRequest(BaseModel):
    email: EmailStr

# 라우터 영역에 추가
@router.post("/check-account", status_code=status.HTTP_200_OK)
async def check_account_existence(req: CheckAccountRequest, db: AsyncSession = Depends(get_db)):
    """Box #1 (아이디 찾기 페이지): 이메일로 가입 여부 및 소셜 연동 상태 확인"""
    
    # 1. 유저 조회
    result = await db.execute(select(User).where(User.email == req.email))
    user = result.scalars().first()

    if not user:
        return {"exists": False, "message": "해당 이메일로 가입된 계정이 없습니다."}

    # 2. 소셜 연동 여부 확인
    providers_result = await db.execute(
        select(ExternalProvider).where(ExternalProvider.account_id == user.id)
    )
    providers = providers_result.scalars().all()

    if providers:
        provider_names = ", ".join([p.provider for p in providers])
        return {
            "exists": True, 
            "message": f"해당 이메일은 {provider_names} 소셜 계정으로 연동되어 있습니다."
        }
    else:
        return {
            "exists": True, 
            "message": "해당 이메일은 일반 계정으로 가입되어 있습니다."
        }



# --- 헬퍼 함수 ---
def hash_code(code: str) -> str:
    """인증 코드를 해싱합니다."""
    return hashlib.sha256(code.encode()).hexdigest()



@router.post("/password/request-code", status_code=status.HTTP_200_OK)
async def request_password_code(req: PasswordRequestCode, db: AsyncSession = Depends(get_db)):
    """Box #1: 이메일 확인 및 인증 코드 발송 (JWT 발급)"""
    result = await db.execute(select(User).where(User.email == req.email))
    user = result.scalars().first()
    
    if not user:
        raise HTTPException(status_code=404, detail="가입된 이메일이 없습니다.")

    # 1. 6자리 난수 코드 생성
    code = str(random.randint(100000, 999999))
    hashed_code = hash_code(code)

    # 2. JWT 생성 (만료시간 5분, 해싱된 코드 포함)
    expire = datetime.now(timezone.utc) + timedelta(minutes=5)
    payload = {
        "sub": user.email, 
        "code_hash": hashed_code, 
        "exp": expire
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

    # TODO: 실제 서비스에서는 이메일/SMS 전송 API를 호출하여 `code`를 발송해야 합니다.
    print(f"LOG[DEV] - {user.email} 복구 코드: {code}")

    # 프런트엔드 테스트를 위해 dev_code를 반환합니다. (실 배포 시 제거)
    return {
        "message": "이메일로 복구 코드가 발송되었습니다.", 
        "token": token,
        "dev_code": code 
    }

@router.post("/password/verify-code", status_code=status.HTTP_200_OK)
async def verify_password_code(req: PasswordVerifyCode):
    """Box #2: 입력 코드 확인 및 재설정 토큰 발급"""
    try:
        payload = jwt.decode(req.token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("sub")
        code_hash = payload.get("code_hash")

        # 클라이언트가 보낸 코드를 해싱하여 토큰의 해시값과 비교
        if hash_code(req.code) != code_hash:
            raise HTTPException(status_code=400, detail="코드가 일치하지 않습니다.")

        # 인증 성공 시, 비밀번호 변경 전용 새 JWT 발급 (만료시간 10분)
        expire = datetime.now(timezone.utc) + timedelta(minutes=10)
        reset_token = jwt.encode(
            {"sub": email, "action": "reset_pw", "exp": expire}, 
            SECRET_KEY, 
            algorithm=ALGORITHM
        )

        return {"message": "코드 인증이 완료되었습니다.", "reset_token": reset_token}
        
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=400, detail="인증 시간이 초과되었습니다. 코드를 다시 요청해주세요.")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=400, detail="유효하지 않은 토큰입니다.")

@router.post("/password/reset", status_code=status.HTTP_200_OK)
async def reset_password(req: PasswordReset, db: AsyncSession = Depends(get_db)):
    """Box #3: 새 비밀번호 적용"""
    try:
        payload = jwt.decode(req.token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("sub")
        action = payload.get("action")

        if action != "reset_pw":
            raise HTTPException(status_code=400, detail="잘못된 요청입니다.")

        result = await db.execute(select(User).where(User.email == email))
        user = result.scalars().first()
        if not user:
            raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

        # TODO: 실제 구현 시 반드시 해싱 함수(pwd_context.hash)를 적용해야 합니다.
        user.password = req.new_password
        await db.commit()

        return {"message": "비밀번호가 성공적으로 변경되었습니다."}

    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=400, detail="재설정 시간이 초과되었습니다. 처음부터 다시 진행해주세요.")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=400, detail="유효하지 않은 토큰입니다.")
    


# 로그인 후 용으로 분리된 구역

@router.get("/{user_id}/role", status_code=status.HTTP_200_OK)
async def get_user_role(user_id: int, db: AsyncSession = Depends(get_db)):
    """특정 유저의 권한(Role) 조회"""
    
    result = await db.execute(select(User.role).where(User.id == user_id))
    user_role = result.scalars().first()

    if not user_role:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

    # user_role은 Enum 타입이므로 .value 또는 .name으로 문자열 변환하여 반환
    return {"role": user_role.value}


@router.get("/{user_id}/profile", status_code=status.HTTP_200_OK)
async def get_user_profile(user_id: int, db: AsyncSession = Depends(get_db)):
    """계정 수정 페이지 초기 로드용 정보 조회"""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

    providers_result = await db.execute(
        select(ExternalProvider.provider).where(ExternalProvider.account_id == user_id)
    )
    linked_providers = providers_result.scalars().all()

    return {
        "name": user.name,
        "phone_number": user.phone_number or "",
        "linked_providers": linked_providers, # 예: ['google', 'apple']
        # 소셜로만 가입한 계정은 비밀번호가 없다. 앱에서 비밀번호 변경 UI를
        # 숨길지 판단하는 데 쓴다. (연동 여부만으로는 판단할 수 없다 —
        # 일반 가입 후 소셜을 추가로 연동한 계정은 비밀번호가 그대로 있다)
        "has_password": user.password is not None
    }

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