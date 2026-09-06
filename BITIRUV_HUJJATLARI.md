# Bitiruv loyihasi hujjatlari (충북대학교 형식)

Bu fayl — 충북대학교 소프트웨어학과 bitiruv loyihasi (졸업작품연구과제) uchun talab qilinadigan
8 ta rasmiy hujjat shablonining (D01–D08) tushuntirishi. Har biri nima uchun kerakligi va
**aynan IDCS loyihasi uchun** nima yozish kerakligi shu yerda yozilgan — keyingi safar so'ralganda
shu faylni o'qib javob berish mumkin.

## Umumiy tartib

| # | Hujjat | Necha marta yoziladi | Qisqacha maqsad |
|---|---|---|---|
| D01 | 시스템 정의서 (프로젝트 요약서) | 1 marta, eng boshida | Loyiha mavzusini tasdiqlatish uchun 1 betlik qisqa tavsif |
| D02 | 프로젝트관리계획서 (요약) | 1 marta | Qanday jarayon bilan ishlaymiz, kim nima qiladi, qachon yig'ilamiz |
| D03 | 소프트웨어 기능 아키텍처 | 1 marta | Kim (actor) tizimda nima qila oladi — Use Case ro'yxati/diagrammasi |
| D04 | 프로덕트 백로그 (요구사항 정의) | 1 marta, keyin yangilanadi | Barcha funksiyalarning to'liq ro'yxati (Epic → User Story) |
| D05 | N차 스프린트 백로그 (태스크 목록) | **har sprintda qayta** | Shu sprintda qaysi story'lar, qanday tasklarga bo'linadi, kim bajaradi |
| D06 | N차 스프린트 명세서 | **har sprintda qayta** | Shu sprintda yozilgan real kod — klasslar, DB, API, ekran skrinshotlari |
| D07 | 소프트웨어 시스템 시험결과서 | 1 marta, oxirida | Butun tizim ishlayotganini test case'lar bilan isbotlash |
| D08 | 프로젝트 결과보고서 | 1 marta, oxirida (2 bet) | Butun loyihaning bir-ikki betlik yakuniy xulosasi |

D05/D06 juftligi har sprint (odatda 2-3 haftalik davr) uchun qayta yoziladi — masalan
"1차 스프린트 백로그" + "1차 스프린트 명세서", keyin "2차 스프린트 백로그" + "2차 스프린트 명세서"
va h.k. Qolgan 6 tasi loyiha davomida bir marta (ba'zilari boshida, ba'zilari oxirida) yoziladi.

---

## D01 — 시스템 정의서 (프로젝트 요약서)

**Nima uchun:** Loyiha mavzusini rasmiy tasdiqlatish uchun eng birinchi, 1 betlik "elevator pitch"
hujjat. Jamoa a'zolari, rahbar, muddat + loyihaning o'zi haqida qisqa jadval.

**Nima yozish kerak (IDCS uchun):**
- **작품 설명** (nima qiladi): "IDCool Systems — muzlatgich omborlarni real vaqtda kuzatish va
  masofadan boshqarish tizimi. Harorat/gaz bosimi/kompressor holatini o'lchab, mobil ilova va
  veb-konsol orqali ko'rsatadi."
- **사용자 유형**: 주요 사용자 — sitting (ombor) xodimlari; 보조 사용자 — sitting egalari/mijozlar;
  관리자 — tizim ishlab chiqaruvchi/operator jamoa.
- **운영개념**: Flutter mobil ilova + React veb-konsol, FastAPI backend, TimescaleDB;
  ombordagi jismoniy sensorlar RS485 (serial) yoki TCP orqali `fac_server`/`DataIntercept`
  kolektorlari bilan o'qiladi va WebSocket orqali serverga yuboriladi.
- **작품의 주요 기능**: real vaqtda monitoring, uzoqdan boshqarish, chart/grafik, alarm,
  chat, hisobot (board), ko'p sittingni bitta hisobdan boshqarish.
- **Key Words (5 ta)**: masalan — 냉동창고 모니터링, IoT 실시간 제어, Flutter, FastAPI, WebSocket.

---

## D02 — 프로젝트관리계획서 (요약)

**Nima uchun:** "Loyihani qanday boshqaramiz" rejasi — jarayon modeli, jamoa rollari, yig'ilish
jadvali, ichki qoidalar (Ground Rules), dev muhiti, hujjatlar ro'yxati.

**Nima yozish kerak (IDCS uchun):**
- **2.1 프로세스 모형**: talablar loyiha davomida bir necha marta o'zgargan (masalan chart
  mantig'i butunlay qayta yozilgani, alarm advanced-settings qo'shilgani kuzatilgan) —
  shuning uchun **점진적 모델 (incremental) yoki 프로토타입 모델** tanlash to'g'ri, 폭포수
  (waterfall) emas.
- **3. 팀 구성**: jamoa a'zolarini repo tuzilishiga mos rollarga bo'lish mumkin — backend
  (`idc_server`), mobil ilova (`idc_app`), veb-konsol (`idc_web`), sitting-tomon kolektor
  (`fac_server`/`DataIntercept`).
- **5. 개발 환경**: `CLAUDE.md`dagi stack bilan bir xil — FastAPI + SQLAlchemy (async) +
  PostgreSQL/TimescaleDB; React 19 + TypeScript + Vite; Flutter (Dart); Python (serial/TCP
  kolektorlar); Docker Compose orqali deploy.

---

## D03 — 소프트웨어 기능 아키텍처 (aslida Use Case hujjati)

**Nima uchun:** Tizimda kim (actor) bor va har biri nima qila olishini (use case) aniqlash —
jadval + UML Use Case diagrammasi.

**Nima yozish kerak (IDCS uchun):**
- **액터 목록**: `User` (oddiy sitting xodimi), `Admin`/`Developer` (tizim boshqaruvchisi),
  va tashqi tizim sifatida sitting-tomon ma'lumot yuboruvchi kolektor (`fac_server`/
  `DataIntercept`) — bu ham bir "actor" sifatida hisoblanishi mumkin (tizimga tashqaridan
  ma'lumot yuboradi).
- **사용사례 목록** (actor bo'yicha):
  - User: 로그인/회원가입, 시설 목록 조회, 시설 등록(코드로), 모니터링 확인, 원격 제어,
    차트 조회, 알람 확인, 게시판 작성/조회, 채팅.
  - Admin: 시설/호실/포인트롤 관리(웹), 차트 그룹 매핑, 명칭 인덱싱, 통합 소요기록 조회.

---

## D04 — 프로덕트 백로그 (요구사항 정의)

**Nima uchun:** Har bir use case'ni "Epic"larga, har epic'ni "User Story"larga bo'lib,
har biriga baho (추정작업량) va ustuvorlik (우선순위) berish — to'liq funksiya ro'yxati.

**Nima yozish kerak (IDCS uchun, misol):**
- Theme (주제) "모니터링" → Epic'lar: 실시간 데이터 수신, 원격 제어, 이상 알람 표시.
- User Story misoli: "Foydalanuvchi xonaning haroratini real vaqtda kuzatish uchun
  monitoring sahifasini ochadi va WebSocket orqali yangilanayotgan qiymatlarni ko'radi."
- Theme "차트" → Epic: 데이터 그룹별 그래프 조회, 조회 기간/해상도 설정.
- Theme "커뮤니티" → Epic: 시설 게시판, 통합 게시판(관리자), 채팅.

---

## D05 — N차 스프린트 백로그 (태스크 목록) — har sprintda qayta

**Nima uchun:** Shu sprint uchun Product Backlog'dan qaysi story'lar tanlanganini ko'chirib,
har birini kichik texnik tasklarga bo'lib, kimga va qachon berilganini yozish.

**Nima yozish kerak (IDCS uchun):** Masalan "2차 스프린트" da chart qismi ustida ishlangan bo'lsa:
- Story: "Foydalanuvchi 데이터 그룹 tanlab grafikni ko'radi."
- Tasklar: `ChartFilterBox` GUI dizayni, backend `chart_controller.py` endpoint yozish,
  Flutter `fl_chart` integratsiyasi, real ma'lumot bilan test qilish.
- **[Muhim]**: 2-sprintdan boshlab, oldingi sprintda o'zgargan narsa bo'lsa, eski ID saqlanadi,
  yangi narsa yangi ID oladi, va alohida "o'zgarishlar" jadvali qo'shiladi.

---

## D06 — N차 스프린트 명세서 — har sprintda qayta

**Nima uchun:** Sprint TUGAGANDAN keyin, real yozilgan kodni hujjatlashtirish: klass
diagrammasi, DB sxemasi, API'lar, va haqiqiy ekran skrinshotlari.

**Nima yozish kerak (IDCS uchun) — bu qism eng oson, chunki kod allaqachon bor:**
- **3.1 클래스 명세**: masalan Flutter tomonda `MonitoringPage`, `ChartFilterBox`,
  `AlarmRow` kabi klasslarning member funksiyalarini jadval qilib yozish.
- **3.3 DB 스키마 명세**: `idc_server/idcool_server/src/models/Monitoring.py`dagi
  `point_role_table`, `temperature_numerical_logs`, `gear_numerical_logs`, `bool_logs`,
  `alarms` va h.k. jadvallarni to'g'ridan-to'g'ri shu yerdan ko'chirib olsa bo'ladi.
- **3.4 API 명세**: `idc_server`dagi FastAPI controller'lardagi real endpoint'lar
  (masalan `/api/chart/{facility_id}/{room_id}`, `/api/auth/login/general`).
- **4. 사용자 인터페이스(GUI)**: haqiqiy ekran skrinshotlari — bu sessiyada Playwright orqali
  olingan skrinshotlarning aynan shu maqsad uchun ishlatilishi mumkin (masalan monitoring,
  chart, chat ro'yxati skrinshotlari).

---

## D07 — 소프트웨어 시스템 시험결과서 — oxirida 1 marta

**Nima uchun:** Butun tizimni (barcha backlog talablarini) yakuniy sinovdan o'tkazish —
har Epic uchun "necha foiz funksiya ishlayapti" va konkret test case'lar (kirish → kutilgan
natija → real natija → pass/fail).

**Nima yozish kerak (IDCS uchun):** Test case misollari — bu sessiyada qilingan tekshirishlarning
aynan shu formatga tushishi mumkin:
- Test ID: `STC-LOGIN-001` — Kirish: haqiqiy admin email/parol → Kutilgan: dashboard ochiladi.
- Test ID: `STC-CHART-001` — Kirish: sitting+xona tanlab "적용" bosish → Kutilgan: real
  ma'lumot chizig'i chiqadi (bu sessiyada Playwright orqali aynan shu tekshirilgan va
  ishlagani screenshot bilan tasdiqlangan).
- Test ID: `STC-NAV-001` — Kirish: sitting ichiga kirib "orqaga" tugmasini bosish → Kutilgan:
  "내 시설" sahifasiga qaytish.

---

## D08 — 프로젝트 결과보고서 (2 bet, yakuniy)

**Nima uchun:** Butun loyihaning eng oxirgi, bir-ikki betlik xulosasi — taqdimot/topshirish
uchun "poster" kabi.

**Nima yozish kerak (IDCS uchun):**
- **시스템 설명 / 운영환경 / 개발 적용 기술**: `CLAUDE.md` va asosiy README'dagi arxitektura
  tavsifidan qisqartirib olish mumkin.
- **개발목표결과물**: tizim sxemasi (data flow diagrammasi) + eng yaxshi ekran skrinshotlari.
- **프로젝트 산출물 목록**: D01–D07 hujjatlari + GitHub repo (`uiux`/`main` branch) + bu
  fayllar ro'yxati.
- **시스템 활용 효과**: masalan — qo'lda tekshirishni kamaytiradi, real vaqtda alarm orqali
  mahsulot buzilishining oldini oladi, ko'p sittingni bitta hisobdan markazlashtirib
  boshqarish imkonini beradi.
- **Key Words**: D01 bilan bir xil bo'lishi mumkin.
