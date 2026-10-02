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

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("LOG[STARTUP] : IDCool Server is starting up...")
    
    bg_task = None
    if os.getenv("ENABLE_FACILITY_SERVER", "false").lower() == "true":
        bg_task = asyncio.create_task(fserver_conn_manager.maintain_connection())
    yield

    
    print("LOG[SHUTDOWN] : Shutting down IDCool Server...")
    if bg_task:
        bg_task.cancel()
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


app.include_router(api_router, prefix="/api/v1")

@app.get("/")
def root():
    return {"message": "Server is running"}