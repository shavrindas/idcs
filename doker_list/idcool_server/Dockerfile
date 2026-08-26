FROM python:3.11-slim

WORKDIR /app

# 1. 의존성 파일 복사 및 설치
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade -r requirements.txt

# 2. idc_server 폴더 내부 전체(idcool_server 폴더 등)를 /app으로 복사
COPY . .

# 3. 실제 Python 실행 루트(idcool_server)로 이동
WORKDIR /app/idcool_server

# 4. src.app 실행
CMD ["uvicorn", "src.app:app", "--host", "0.0.0.0", "--port", "8080"]