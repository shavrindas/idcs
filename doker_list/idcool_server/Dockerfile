FROM python:3.11-slim
WORKDIR /app
COPY ./requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt
COPY . /app
# uvicorn 포트는 8080으로 실행 (Nginx 설정과 매칭)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]