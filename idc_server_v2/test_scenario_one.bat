@echo off
start "Node A (Center)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8900 --env-file .runbat\.env.center_only --reload"
timeout /t 3 /nobreak > nul
start "Node Daon (Facility Daon)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8901 --env-file .runbat\.env.fac_daon --reload"
start "Node MoonKyeong (Facility MoonKyeong)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8902 --env-file .runbat\.env.fac_moonkyeong --reload"
start "Node FromBIO (Facility FromBIO)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8903 --env-file .runbat\.env.fac_frombio --reload"
start "Node Test (Facility Test)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8904 --env-file .testbat\.env.fac_test --reload"
start "Node Moohan (Facility Moohan)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8905 --env-file .runbat\.env.fac_moohan --reload"
start "Node IK (Facility I&K)" cmd /k "uvicorn src.app:app --host 0.0.0.0 --port 8906 --env-file .runbat\.env.fac_ik --reload"