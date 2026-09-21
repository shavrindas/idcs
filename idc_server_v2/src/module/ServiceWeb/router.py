from fastapi import APIRouter
from fastapi.responses import FileResponse
import os

from src.module.ServiceWeb.controllers.node_manage_controller import router as node_admin_router
from src.module.ServiceWeb.controllers.chart_mapping_controller import router as chart_mapping_router

from src.module.ServiceWeb.controllers.auth_controller import router as auth_router
from src.module.ServiceWeb.controllers.facility_controller import router as facility_router
from src.module.ServiceWeb.controllers.alarm_controller import router as alarm_router
from src.module.ServiceWeb.controllers.chat_controller import router as chat_router
from src.module.ServiceWeb.controllers.board_controller import router as board_router
from src.module.ServiceWeb.controllers.chart_controller import router as chart_router

router = APIRouter()

# 웹(어드민) 전용 라우터
router.include_router(node_admin_router)
router.include_router(chart_mapping_router)

# 일반 웹 기능 라우터
router.include_router(auth_router)
router.include_router(facility_router)
router.include_router(alarm_router)
router.include_router(chat_router)
router.include_router(board_router)
router.include_router(chart_router)

# 임시 WebUI 대시보드 페이지 라우트
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UI_HTML_PATH = os.path.join(BASE_DIR, "webui", "index.html")

@router.get("/dashboard", include_in_schema=False)
async def serve_dashboard():
    return FileResponse(UI_HTML_PATH)