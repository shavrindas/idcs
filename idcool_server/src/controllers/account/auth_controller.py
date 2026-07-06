import logging
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from src.config.db import get_db

router = APIRouter()


@router.post("/login")
def login(request: LoginSchema, db: Session = Depends(get_db)):
    # 컨트롤러는 오직 "입력값 검증"과 "응답 반환"만 수행
    user = auth_service.authenticate_user(db, request.email, request.password)
    if not user:
        raise HTTPException(status_code=400, detail="로그인 실패")
    return {"token": "some_token"}