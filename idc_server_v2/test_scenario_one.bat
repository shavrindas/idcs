@echo off
@REM   echo [Scenario 1] 중앙 - 시설(Node Daon, 8901)
echo [Scenario 1] Center - Facility(Node A, 8901)
start "Node A (Center)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8900 --env-file .testbat\.env.center_only --reload"
timeout /t 3 /nobreak > nul
start "Node Daon (Facility Daon)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8901 --env-file .testbat\.env.fac_daon --reload"
start "Node MoonKyeong (Facility MoonKyeong)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8902 --env-file .testbat\.env.fac_moonkyeong --reload"