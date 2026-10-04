@echo off
@REM  echo [Scenario 2] 중앙(Node A, 8900) - 시설B(8901) - 시설C(8902)
echo [Scenario 2] Center(Node A, 8900) - Facility B(8901) - Facility C(8902)
start "Node A (Center Only)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8900 --env-file .testbat\.env.center_only --reload"
timeout /t 3 /nobreak > nul
start "Node B (Facility B)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8901 --env-file .testbat\.env.fac_b --reload"
start "Node C (Facility C)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8902 --env-file .testbat\.env.fac_c --reload"