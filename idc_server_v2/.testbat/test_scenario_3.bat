@echo off
@REM  echo [Scenario 3] 중앙 단독(Web, App 활성화)
echo [Scenario 3] Center Only(Web, App Active)
start "Node A (Center Only)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8900 --env-file .testbat\.env.center_only --reload"