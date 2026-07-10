from fastapi import FastAPI, APIRouter
from fastapi.middleware.cors import CORSMiddleware
from src.controllers.websocket.chat_controller import router
from config.db import get_db_connection
import src.models.user_table as ud
import psycopg2.extras

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 프로덕션에서는 특정 도메인만 지정하는 것이 좋습니다.
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Hello World"}

uslist = []

@app.post("/userid") # 앱에서도 정확히 '/userid'로 요청해야 합니다.
async def userid(data: dict):
    return ud.user_find_by_name(data["user_name"]).id

@app.get("/users")
async def get_users():
    return ud.users_find_all()

app.include_router(router, prefix="/api")