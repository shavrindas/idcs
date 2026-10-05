# C:\Users\ynham\Desktop\idcV2\src\module\CServer\router.py

from fastapi import APIRouter
from src.module.CServer.controllers.sys_auth_controller import router as sys_auth_router
from src.module.CServer.controllers.sys_auth_controller import stream_router

router = APIRouter()

# 1. HTTP 인증 엔드포인트 (/api/v1/cserver/sys-auth/login)
router.include_router(sys_auth_router)

# 2. WebSocket 스트림 엔드포인트 (/api/v1/cserver/data-stream/{facility_id})
router.include_router(stream_router)