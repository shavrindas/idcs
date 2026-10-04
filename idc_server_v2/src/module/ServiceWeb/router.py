from fastapi import APIRouter
from fastapi.responses import FileResponse
import os

from src.module.ServiceWeb.controllers.node.node_manage_controller import router as node_admin_router
from src.module.ServiceWeb.controllers.chart.chart_mapping_controller import router as chart_mapping_router
from src.module.ServiceWeb.controllers.account.auth_controller import router as auth_router
from src.module.ServiceWeb.controllers.facility.facility_controller import router as facility_router
from src.module.ServiceWeb.controllers.facility.facility_management_controller import router as facility_mgmt_router
from src.module.ServiceWeb.controllers.alarm.alarm_controller import router as alarm_router
from src.module.ServiceWeb.controllers.board.board_controller import router as board_router
from src.module.ServiceWeb.controllers.chart.chart_controller import router as chart_router

router = APIRouter()

# 웹(어드민) 전용 관리 라우터
router.include_router(node_admin_router)
router.include_router(facility_mgmt_router)
router.include_router(chart_mapping_router)

# 웹 일반 기능 라우터 (chat_router 제거됨)
router.include_router(auth_router)
router.include_router(facility_router)
router.include_router(alarm_router)
router.include_router(board_router)
router.include_router(chart_router)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UI_HTML_PATH = os.path.join(BASE_DIR, "webui", "webservice", "dist", "index.html")

@router.get("/dashboard", include_in_schema=False)
async def serve_dashboard():
    return FileResponse(UI_HTML_PATH)