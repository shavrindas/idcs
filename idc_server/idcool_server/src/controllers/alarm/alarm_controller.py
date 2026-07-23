# ===============================================================
# 경로 : src/controllers/alarm/alarm.py
# 명세 : 알람 관련 API 엔드포인트 정의
# ===============================================================

from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from fastapi import APIRouter, Depends
from config.db import get_db
from src.models.User import UserFcmToken

router = APIRouter(prefix="/alarms", tags=["Alarms"])

class RegistTokenRequest(BaseModel):
    fcm_token: str
    user_id: int

@router.post('/register')
async def registToken(user_in: RegistTokenRequest, db: AsyncSession = Depends(get_db)):
    """Box #1: FCM 토큰 등록 (비동기 처리)"""
    
    # 1. 중복 등록 확인
    mapping_result = await db.execute(
        select(UserFcmToken).where(UserFcmToken.fcm_token == user_in.fcm_token)
    )
    existing_token = mapping_result.scalars().first()

    # 이미 동일한 토큰이 등록된 경우
    if existing_token:
        # 소유 유저가 바뀌었을 가능성이 있으므로 user_id 업데이트 후 저장
        if existing_token.user_id != user_in.user_id:
            existing_token.user_id = user_in.user_id
            await db.commit()
            return {"message": "기존 토큰의 사용자 정보가 갱신되었습니다.", "user_id": user_in.user_id}
        
        return {"message": "이미 등록된 토큰입니다.", "user_id": user_in.user_id}

    new_token = UserFcmToken(
        fcm_token=user_in.fcm_token, 
        user_id=user_in.user_id
    )
    
    db.add(new_token)
    await db.commit()

    return {"message": "토큰이 성공적으로 등록되었습니다.", "user_id": new_token.user_id}