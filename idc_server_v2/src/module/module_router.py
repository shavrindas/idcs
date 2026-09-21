from fastapi import APIRouter
from Core.router import router as core_router
from CServer.router import router as cserver_router
from FServer.router import router as fserver_router
from ServiceApp.router import router as serviceapp_router  
from ServiceWeb.router import router as serviceweb_router

api_router = APIRouter()

# 하위 모듈 라우터들을 등록
api_router.include_router(core_router,       prefix="/core",        tags=["Core"])
api_router.include_router(cserver_router,    prefix="/cserver",     tags=["CServer"])
api_router.include_router(fserver_router,    prefix="/fserver",     tags=["FServer"])
api_router.include_router(serviceapp_router, prefix="/serviceapp",  tags=["ServiceApp"])
api_router.include_router(serviceweb_router, prefix="/serviceweb",  tags=["ServiceWeb"])