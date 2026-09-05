# config/settings.py
import os
from dotenv import load_dotenv

load_dotenv()

def to_bool(val: str, default: bool = False) -> bool:
    if val is None:
        return default
    return val.strip().lower() in ("true", "1", "yes", "on")

class Settings:
    ENABLE_LOCAL_DB: bool = to_bool(os.getenv("ENABLE_LOCAL_DB"), default=False)
    ENABLE_WEB: bool = to_bool(os.getenv("ENABLE_WEB"), default=True)
    ENABLE_FACILITY_SERVER: bool = to_bool(os.getenv("ENABLE_FACILITY_SERVER"), default=True)
    ENABLE_CENTER_SERVER: bool = to_bool(os.getenv("ENABLE_CENTER_SERVER"), default=True)

settings = Settings()