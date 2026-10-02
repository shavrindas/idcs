# =================================================
#  경로 : src/module/Core/security.py
#  설명 : 토큰 발급과 검증을 담당하는 공통 보안 유틸리티입니다.
# =================================================

import jwt
import os
import secrets
import hashlib
from datetime import datetime, timedelta, timezone

API_KEY_PREFIX = "idk_live_"

# 운영 환경 변수에서 로드 (미설정 시 즉시 에러 발생)
SYSTEM_SECRET_KEY = os.getenv("SYSTEM_SECRET_KEY")
if not SYSTEM_SECRET_KEY:
    # 테스트/개발 환경 편의를 위한 경고 겸 기본 fallback을 두거나, 엄격하게 예외 처리
    # raise RuntimeError("CRITICAL: SYSTEM_SECRET_KEY 환경 변수가 설정되지 않았습니다.")
    SYSTEM_SECRET_KEY = "idcool_system_super_secret_key_v2_secure_32bytes_min"


ALGORITHM = "HS256"


def create_system_token(node_id: int, facility_id: int, expires_delta: timedelta = timedelta(hours=6)):
    """시스템(FServer) 접속용 JWT 발급"""
    expire = datetime.now(timezone.utc) + expires_delta
    payload = {
        "sub": str(node_id),
        "facility_id": facility_id,
        "type": "system",
        "exp": expire
    }
    return jwt.encode(payload, SYSTEM_SECRET_KEY, algorithm=ALGORITHM)

def verify_system_token(token: str):
    """X-System-Token 검증 로직"""
    try:
        payload = jwt.decode(token, SYSTEM_SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != "system":
            return None
        return payload
    except jwt.ExpiredSignatureError:
        return "EXPIRED"
    except jwt.InvalidTokenError:
        return None

def generate_facility_api_key() -> tuple[str, str]:
    """(원문 API Key, DB 저장용 해시값) 생성"""
    raw_secret = secrets.token_urlsafe(32)
    raw_key = f"{API_KEY_PREFIX}{raw_secret}"
    key_hash = hash_api_key(raw_key)
    return raw_key, key_hash

def hash_api_key(raw_key: str) -> str:
    """API Key SHA-256 해싱"""
    return hashlib.sha256(raw_key.encode()).hexdigest()