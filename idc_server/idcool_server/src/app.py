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
import firebase_admin
from firebase_admin import credentials

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
# ─── 파이어베이스 서비스 ───
# ===============================================================
if not firebase_admin._apps:
    cred = credentials.Certificate("src/idcs-project-e7dc3-firebase-adminsdk-fbsvc-a944ee7f48.json") # 다운받은 키 경로
    firebase_admin.initialize_app(cred)

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

# 알람 관련 라우터
from src.controllers.alarm.alarm_controller import router as auth_router
app.include_router(auth_router, prefix="/api")

# 계정 관련 라우터
from src.controllers.account.auth_controller import router as auth_router
app.include_router(auth_router, prefix="/api")

# 시설 관련 라우터
from src.controllers.facility.facility_controller import router as facility_router
app.include_router(facility_router, prefix="/api")

# 보드 라우터
from src.controllers.board.board_controller import router as board_router
app.include_router(board_router, prefix="/api")

# 채팅 라우터
from src.controllers.chat.chat_controller import router as chat_router
app.include_router(chat_router, prefix="/api")

# 차트 라우터
from src.controllers.chart.chart_controller import router as chart_router
app.include_router(chart_router, prefix="/api")

# 차트 관리자 매핑용 라우터 [웹]
from src.controllers.chart.chart_mapping_controller import router as chart_mapping_router
app.include_router(chart_mapping_router, prefix="/api")

from src.controllers.facility.facility_management_controller import router as facility_mgmt_router
app.include_router(facility_mgmt_router, prefix="/api")