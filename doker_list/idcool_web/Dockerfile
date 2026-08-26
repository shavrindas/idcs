FROM node:20-alpine

WORKDIR /app

# 1. 패키지 의존성 파일 복사 및 설치
COPY package*.json ./
RUN npm install

# 2. 소스 전체 복사
COPY . .

# 3. Vite 서버 실행 (--host로 외부/도커 바인딩 허용)
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5173"]