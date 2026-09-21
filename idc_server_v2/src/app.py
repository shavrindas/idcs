from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
from config.database import engine
from src.module.Core.models.User import User, ExternalProvider
from src.module.Core.models.Facility import Facility, FacilityRoom, FacilityUser
import os
import firebase_admin
from firebase_admin import credentials
from module.module_router import api_router

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
    version="2.0.0",
    lifespan=lifespan
)

app.include_router(api_router, prefix="/api/v1")

@app.get("/")
def root():
    return {"message": "Server is running"}