# config/config.py
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    # .env 파일의 변수명과 일치하게 선언 (타입 힌트 적용)
    PROJECT_NAME: str
    ENVIRONMENT: str

    # MySQL 설정
    DB_HOST: str
    DB_PORT: int = 5432
    DB_USER: str
    DB_PASSWORD: str
    DB_NAME: str

    LOG_LEVEL: str = "INFO"

    # Pydantic Settings 설정: .env 파일을 읽어오도록 지정
    model_config = SettingsConfigDict(
        env_file=".env", 
        env_file_encoding="utf-8",
        extra="ignore" # .env에 더 많은 변수가 있어도 에러 내지 않고 무시
    )

# 어디서든 import해서 사용할 수 있도록 싱글톤 인스턴스 생성
settings = Settings()