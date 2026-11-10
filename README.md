# IDCS

냉동·냉장 창고의 온도, 가스 압력, 압축기 상태 등을 현장에서 실시간으로 수집하고,
모바일 앱과 웹 콘솔을 통해 모니터링·제어할 수 있는 시스템이다.

## 데이터 흐름

```
현장 센서
   │
fac_server / DataIntercept   (창고 현장에서 센서 데이터 수집)
   │
idc_server_v2                (중앙 서버 — 데이터 저장 및 API 제공)
   │                  │
idc_app            웹 콘솔
(모바일 앱)       (ServiceWeb webui)
```

## 사용자

- **현장 직원** — 모바일 앱(`idc_app`)으로 모니터링, 차트 조회, 게시판, 채팅, 알람 확인.
- **관리자** — 웹 콘솔로 시설/호실/센서 구성, 센서 매핑 및 이름 지정, 직원 권한 관리.
- **개발팀** — 두 클라이언트가 공유하는 `idc_server_v2` 백엔드와 현장 수집기를 개발.

## 구성

| 경로 | 설명 |
|---|---|
| `idc_server_v2` | FastAPI 백엔드. `Core`(공통 모델/DB), `CServer`(중앙 노드), `FServer`(시설 노드), `ServiceApp`(모바일 앱 API), `ServiceWeb`(웹 콘솔 API + React 프론트엔드)로 모듈이 나뉘며, 각 모듈은 환경 변수로 개별 활성화한다. |
| `idc_app` | Flutter 모바일 앱. |
| `fac_server` | 창고 현장 설치용 프로그램. 센서에 직접(케이블) 연결해 데이터를 읽어 중앙 서버로 전송. |
| `DataIntercept` | `fac_server`와 같은 역할이나 네트워크(이더넷) 연결 방식을 사용하는 버전. |
| `doker_list` | 운영 서버 배포용 Docker 설정 모음(DB, Nginx, Redis, 서버, 웹). |
| `.legacy` | 이전 세대 서버/웹(`idc_server`, `idc_web`). 더 이상 개발하지 않으며 `idc_server_v2`로 대체됨. |

## 기술 스택

- 백엔드: Python · FastAPI · PostgreSQL(TimescaleDB) · SQLAlchemy(async)
- 웹 콘솔: React 19 · TypeScript · Vite · ECharts
- 모바일 앱: Flutter · Dart
- 현장 수집기: Python

## 서버 실행

`idc_server_v2`는 모듈을 환경 변수로 켜고 끈다. 로컬에서 중앙+앱+웹을 한 번에 띄우는 예:

```bash
cd idc_server_v2
ENABLE_CENTER_SERVER=true ENABLE_SERVICE_WEB=true ENABLE_SERVICE_APP=true \
  uvicorn src.app:app --host 0.0.0.0 --port 8900
```

중앙 노드와 시설 노드를 분리해 띄우는 등의 시나리오는 `idc_server_v2/.testbat/`에
예시 배치 파일이 있다.

웹 콘솔 개발 서버:

```bash
cd idc_server_v2/src/module/ServiceWeb/webui/webservice
npm run dev
```

## 브랜치 전략

`main`은 운영 중인 기준 브랜치다. 기능·디자인 작업은 별도 브랜치에서 진행한 뒤
검토를 거쳐 병합한다.
