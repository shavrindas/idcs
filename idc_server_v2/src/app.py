from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
from src.config.database import engine
from src.module.Core.models.User import User, ExternalProvider
from src.module.Core.models.Facility import Facility, FacilityRoom, FacilityUser
import os
import asyncio
import firebase_admin
from firebase_admin import credentials
from src.module.module_router import api_router
from src.module.FServer.controllers.connection_manager import fserver_conn_manager
from src.module.FServer.controllers.connection_facility import facility_ethernet
from src.module.CServer.controllers.sys_auth_controller import monitor_facility_connections

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("LOG[STARTUP] : IDCool Server is starting up...")
    
    bg_task = None
    et_task = None
    center_et_check_task = None

    if os.getenv("ENABLE_FACILITY_SERVER", "false").lower() == "true":
        bg_task = asyncio.create_task(fserver_conn_manager.maintain_connection())
        et_task = asyncio.create_task(facility_ethernet.to_facility_connect())
    if os.getenv("ENABLE_CENTER_SERVER", "false").lower() == "true":
        center_et_check_task = asyncio.create_task(monitor_facility_connections())

    yield
    
    print("LOG[SHUTDOWN] : Shutting down IDCool Server...")
    if bg_task:
        bg_task.cancel()
    if et_task:
        et_task.cancel()
    if center_et_check_task:
        center_et_check_task.cancel()
    await engine.dispose()

app = FastAPI(
    title="IDCool Systems API",
    description="IDCool Systems 서버 백엔드 API",
    version="2.0.0",
    lifespan=lifespan
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # 개발 단계이므로 전체 허용
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

# ===============================================================
# ─── 파이어베이스 서비스 ───
# ===============================================================
if not firebase_admin._apps:
    cred = credentials.Certificate("src/config/idcs-project-e7dc3-0b05c98663ba.json") # 다운받은 키 경로
    firebase_admin.initialize_app(cred)


app.include_router(api_router, prefix="/api/v1")

@app.get("/")
def root():
    return {"message": "Server is running"}


WEBUI_DIST_DIR = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "module", "ServiceWeb", "webui", "webservice", "dist"
)
if os.path.exists(WEBUI_DIST_DIR):
    app.mount("/webui", StaticFiles(directory=WEBUI_DIST_DIR, html=True), name="webui")