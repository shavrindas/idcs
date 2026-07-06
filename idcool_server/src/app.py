from fastapi import FastAPI
from src.controllers.test_controller import router as test_router
from src.config.db import engine, Base

app = FastAPI(title="Project API")

# DB 초기화 (이미 테이블이 있다면 create_all은 단순히 메타데이터 매핑만 수행합니다)
Base.metadata.create_all(bind=engine)

app.include_router(test_router, prefix="/api")

@app.get("/")
def read_root():
    return {"message": "Server is running"}