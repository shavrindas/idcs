# ===============================================================
# 경로 : src/app.py
# 명세 : FastAPI 서버 초기화 및 라우터 등록
# ===============================================================
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
from config.db import engine
from src.models.User import User, ExternalProvider
from src.models.Facility import Facility, FacilityRoom, FacilityUser
import os

# ===============================================================
# FastAPI 서버 초기화
# ===============================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: 시작 시 실행 로직
    print("LOG[STARTUP] : IDCool Server is starting up...")
    yield
    # Shutdown: 종료 시 실행 로직
    print("LOG[SHUTDOWN] : Shutting down IDCool Server...")
    await engine.dispose()
    
app = FastAPI(
    title="IDCool Systems API",
    description="IDCool Systems 서버 백엔드 API",
    version="1.0.0",
    lifespan=lifespan
)

# ===============================================================
# ─── 이미지 업로드 디렉토리 설정 ───
# ===============================================================

# 이미지가 저장될 디렉토리 생성 보장
os.makedirs("uploads", exist_ok=True)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

# 정적 파일 제공
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")


# ===============================================================
# ─── 루트 엔드포인트 ───
# ===============================================================
@app.get("/")
async def root():
    # 작동 확인용 
    return {"message": "IDCool Systems API", "status": "running"}


# ===============================================================
# ─── 라우터 ───
# ===============================================================

# 디버그 라우터 
from src.app_debug_list import router as debug_router
app.include_router(debug_router)

# 권한 및 시설 정보 주입 라우터
from src.controllers.free_later_controller import router as free_later_router
app.include_router(free_later_router)

# 계정 관련 라우터
from src.controllers.account.auth_controller import router as auth_router
app.include_router(auth_router, prefix="/api")

# 시설 관련 라우터
from src.controllers.facility.facility_controller import router as facility_router
app.include_router(facility_router, prefix="/api")

# 보드 라우터
# from src.controllers.board.board_controller import router as board_router
# app.include_router(board_router)

