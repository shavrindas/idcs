import os
from fastapi import APIRouter
from src.module.Core.router import router as core_router
from src.module.CServer.router import router as cserver_router
from src.module.FServer.router import router as fserver_router
from src.module.ServiceApp.router import router as serviceapp_router  
from src.module.ServiceWeb.router import router as serviceweb_router

api_router = APIRouter()

# 하위 모듈 라우터들을 등록


api_router.include_router(core_router,       prefix="/core",        tags=["Core"])

if os.getenv("ENABLE_CENTER_SERVER", "false").lower() == "true":
    api_router.include_router(cserver_router, prefix="/cserver", tags=["CServer"])

if os.getenv("ENABLE_FACILITY_SERVER", "false").lower() == "true":
    api_router.include_router(fserver_router, prefix="/fserver", tags=["FServer"])

if os.getenv("ENABLE_SERVICE_APP", "false").lower() == "true":
    api_router.include_router(serviceapp_router, prefix="/serviceapp", tags=["ServiceApp"])

if os.getenv("ENABLE_SERVICE_WEB", "false").lower() == "true":
    api_router.include_router(serviceweb_router, prefix="/serviceweb", tags=["ServiceWeb"])