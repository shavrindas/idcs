from fastapi import APIRouter

from src.module.ServiceApp.controllers.auth_controller import router as auth_router
from src.module.ServiceApp.controllers.facility_controller import router as facility_router
from src.module.ServiceApp.controllers.alarm_controller import router as alarm_router
from src.module.ServiceApp.controllers.chat_controller import router as chat_router
from src.module.ServiceApp.controllers.board_controller import router as board_router
from src.module.ServiceApp.controllers.chart_controller import router as chart_router

router = APIRouter()

router.include_router(auth_router)
router.include_router(facility_router)
router.include_router(alarm_router)
router.include_router(chat_router)
router.include_router(board_router)
router.include_router(chart_router)