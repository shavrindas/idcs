@echo off

start "Node A (Center)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8900 --env-file .testbat\.env.center_only --reload"
timeout /t 3 /nobreak > nul
start "Node Test (Facility Test)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8901 --env-file .testbat\.env.fac_test --reload"
start "Node Moohan (Facility Moohan)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8902 --env-file .runbat\.env.fac_moohan --reload"
start "Node IK (Facility I&K)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8903 --env-file .runbat\.env.fac_ik --reload"