@echo off
@REM   echo [Scenario 1] 중앙+시설(Node A, 8900) - 시설(Node B, 8901)
echo [Scenario 1] Center+Facility(Node A, 8900) - Facility(Node B, 8901)
start "Node A (Center+Fac)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8900 --env-file .testbat\.env.center_fac --reload"
timeout /t 3 /nobreak > nul
start "Node B (Facility B)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8901 --env-file .testbat\.env.fac_b --reload"