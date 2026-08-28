# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**IDCool Systems (IDCS)** — a monitoring/control system for freezing warehouses / cold-storage facilities
(Flutter app description: "Proactive Service system for Freezing Warehouses"). Physical refrigeration
equipment (sensors, gear) is polled over serial/ethernet, aggregated into time-series stats, streamed to a
FastAPI backend over WebSocket, stored in TimescaleDB, and surfaced through a React admin web console and a
Flutter mobile app (with chat, board/community, alarms, and charting).

This is a monorepo with five independent subprojects, each with its own dependency manifest — there is no
shared root build. Work inside the relevant subdirectory.

## Subprojects

| Path | Stack | Role |
|---|---|---|
| `idc_server/` | FastAPI + SQLAlchemy (async) + PostgreSQL/TimescaleDB | Main backend API + WebSocket ingest |
| `idc_web/setuptmp/` | React 19 + TypeScript + Vite + react-router-dom + ECharts | Admin/monitoring web console |
| `idc_app/IDCS/` | Flutter (Dart) | Mobile app (iOS/Android/desktop) for facility staff |
| `fac_server/DataLayer/` | Python, layered (RS485 serial → WebSocket) | Runs on-site at a facility; polls equipment via serial and streams data to the backend |
| `DataIntercept/` | Python, threaded | Alternate/legacy on-site data collector — connects to a TCP device gateway (`211.55.127.239:4000`) instead of serial, aggregates stats, pushes over WebSocket |
| `doker_list/` | docker-compose per service | Deployment definitions (nginx, TimescaleDB, redis, backend, frontend) |

`fac_server` and `DataIntercept` both play the same role (facility-side data collector feeding
`idc_server`) but talk to hardware differently — check which one is actually in use before assuming the
other is dead code.

## Commands

### Backend (`idc_server/idcool_server`)
```bash
pip install -r idc_server/requirements.txt
cd idc_server/idcool_server
uvicorn src.app:app --reload --host 0.0.0.0        # matches .vscode/tasks.json "Run FastAPI Server"
```
Interactive API docs at `/docs` (FastAPI default) once running.

### Web console (`idc_web/setuptmp`)
```bash
cd idc_web/setuptmp
npm install
npm run dev       # vite dev server, port 5173
npm run build      # tsc -b && vite build
npm run lint       # oxlint
npm run preview
```

### Mobile app (`idc_app/IDCS`)
```bash
cd idc_app/IDCS
flutter pub get
flutter run
flutter analyze    # uses flutter_lints via analysis_options.yaml
flutter test       # only test/widget_test.dart exists currently
```

### Facility-side collectors
```bash
cd fac_server/DataLayer && python main.py     # serial (RS485) collector
cd DataIntercept && python main.py            # TCP-gateway collector
```
Both require `pyserial`/`websockets` etc. installed manually — neither subproject ships a
requirements/lock file; check imports before running.

### Full stack via Docker (see `doker_list/할것.txt`)
```bash
docker network create idcool-network
cd doker_list/idcool_database && docker compose up -d
cd ../idcool_redis && docker compose up -d
cd ../idcool_server && docker compose up -d --build
cd ../idcool_web && docker compose up -d --build
cd ../idcool_nginx && docker compose up -d --build
```
nginx (port 80) reverse-proxies `/api/*`, `/docs`, `/redoc`, `/openapi.json`, and the
`/api/facilities/data/{set,get}/` WebSocket endpoints to the backend, and everything else to the Vite dev
server. The compose files expect a sibling clone at `../../idcs/...` (see `context:` paths) — they are not
meant to be run from inside this checkout directly without adjusting paths, or by cloning this repo as
`idcs` next to `doker_list`.

## Architecture

### Data flow
```
Physical equipment (sensors/gear)
  → fac_server (serial/RS485)  or  DataIntercept (TCP gateway @211.55.127.239:4000)
  → periodic stat aggregation (mean/var/std/min/max, ~1 min windows)
  → WebSocket → idc_server  (ws://.../api/facilities/data/set/{facility_id})
  → PostgreSQL/TimescaleDB (point_role / *_logs tables in models/Monitoring.py)
  → REST API (/api/chart/..., /api/chart-mapping/...)
  → idc_web (ECharts) and idc_app (fl_chart) render it
```

### `fac_server/DataLayer` layering
Documented order in `fac_server/DataLayer/Readme.md`:
`Mapping_Layer -> Transmission -> Command_Layer -> Data_Layer`
- `Data_Layer/DataList.py` — the static list of equipment addresses/labels to poll.
- `Command_Layer/Command.py` — builds the serial command frames per address.
- `Machine_Layer/Machine_Transmission.py` — owns the actual `pyserial` port (hardcoded `COM3`,
  115200 baud) and a send/recv queue pair driving a background worker thread.
- `Mapping_Layer/Mapping.py` — maps raw responses to labeled values (`LabelMap`).
- `Ethernet_Layer/Ethernet.py` — pushes `LabelMap` to `idc_server` over WebSocket every second, and
  listens for `COMMAND_REQUEST` packets from the server to answer on-demand queries; auto-reconnects with
  a 3s backoff.

`DataIntercept` is a flatter, single-file-per-concern version of the same idea, but sources data from a
raw TCP socket instead of serial, and does its own per-category statistical aggregation
(`categorized_data` / `cashed_data`, change-detection for boolean/static values) before pushing JSON over
WebSocket roughly every 6 seconds (`timedelta(minutes=0.1)`).

### `idc_server` backend
- Entry point: `idcool_server/src/app.py`. Routers are registered there under `/api` by domain:
  `account/auth_controller`, `account/auth_web_controller` (separate app-vs-web login flows),
  `alarm/alarm_controller`, `facility/facility_controller`, `facility/facility_management_controller`,
  `board/board_controller`, `chat/chat_controller`, `chart/chart_controller`,
  `chart/chart_mapping_controller`, plus a debug router (`app_debug_list.py`) and
  `free_later_controller.py` (permission/facility-context injection).
- DB access is async SQLAlchemy (`config/db.py`, `AsyncSession`, `get_db` dependency). Connection string
  defaults to a hardcoded TimescaleDB host but is overridable via the `DATABASE_URL` env var (see
  `doker_list/idcool_server/docker-compose.yml` for the containerized DB_* env vars, which are *not*
  currently wired into `db.py` — only `DATABASE_URL` is read there).
- No Alembic migration scripts exist yet despite `alembic` being a dependency; schema setup is currently
  just `doker_list/idcool_database/init-db.sql` (extension + role) plus whatever the SQLAlchemy models in
  `src/models/*.py` imply — there's no `create_all()` call either, so check how tables actually get
  created before assuming migrations will pick up a model change.
- Models: `User.py` (users, external OAuth providers, FCM tokens), `Facility.py` (facilities, rooms,
  facility-user membership), `Monitoring.py` (`point_role_table`/`point_role_metadata` — the addressable
  "points" being monitored — plus `temperature_numerical_logs`, `gear_numerical_logs`, `bool_logs`,
  `equipment_static_logs`, `remote_control_logs`, `alarms`, `chart_group_table`/`chart_group_mapping`),
  `Board.py` (community board/posts/comments), `Chat.py` (chatrooms, messages, hashtags).
- Firebase Admin is initialized in `app.py` from a service-account JSON checked into `src/` — used for FCM
  push (`services/alarm.py`, `models/User.UserFcmToken`).
- Auth is JWT-based (`PyJWT`) with a hardcoded `SECRET_KEY` in `auth_controller.py` (marked TODO to move to
  env) and currently compares passwords as plaintext, not hashes — treat as a known gap, not a pattern to
  copy. `auth_web_controller.py` is a separate, simpler login path for the web console still returning a
  dummy token.

### `idc_web/setuptmp` web console
- React Router with role-gated routes in `App.tsx`: `ADMIN`/`DEVELOPER` see dashboard (`/main`), mapping
  admin (`/mapping`), point-name indexing (`/indexing`), and facility/room management
  (`/facility-manager`); all logged-in users see the chart viewer (`/viewer`).
- `services/apiService.ts` is the sole API client — `BASE_URL` is a **hardcoded LAN IP**
  (`http://192.168.29.159:8000/api`), not an env var; update it when pointing at a different backend.
- Chart mapping concepts: a "point role" (`chart-mapping/roles/:facilityId/:roomId`) is a monitored value
  slot; "chart groups" (`chart-mapping/group(s)`) bundle role IDs together for combined charting
  (`components/chart/mapper/*`, `components/chart/viewer/*`).

### `idc_app/IDCS` mobile app
- Routing via `go_router` in `lib/routes.dart` (loaded as `part of 'main.dart'`), path-parameterized by
  `:userId` and `:facilityId` (no central auth/facility state object — IDs are threaded through the URL).
  A `redirect` guard in the router sends unauthenticated users to `/login` except for a small allowlist of
  public paths.
- Feature areas under `lib/pages/` and `lib/components/`: `common/` (auth: login/signup/find-id/find-pw),
  `indices/` (user-level: main index, alarms, account, facility registration, board), `facility/` (per-
  facility: monitoring, chart, board, chat, alarms) — mirrors the backend's user-vs-facility split.
  `services/*/{...}_api_service.dart` files are one-per-domain HTTP clients matching the backend's
  controller split; `services/common/web_socket_service.dart` and `fcm_service.dart` handle the live data
  socket and push notifications respectively.
- Auth providers: Google Sign-In and Sign in with Apple alongside email/password (`social_auth_service.dart`).

## Language / conventions

Code comments, commit messages, and doc files in this repo are predominantly Korean — match that when
editing existing files unless told otherwise. Git branching policy is documented in
`.프로젝트 정책/git_memo.md`: `main` (protected, no direct commits) ← `intergrator` (integration branch) ←
`package_N` (large work units, kept) ← per-feature branches (deleted after merge into their `package_N`).
