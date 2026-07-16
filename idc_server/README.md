# idcs
IDCool Systems Software Project



(.venv) PS C:\Users\ynham\devspace\IDCool_Systems\idc_server\idcool_server> tree /f /a         
Folder PATH listing
Volume serial number is 00000005 AE28:4285
C:.
|   requirements.txt
|   
\---src
    |   app.py
    |   __init__.py
    |   
    +---config
    |   |   db.py
    |   |   __init__.py
    |   |   
    |   \---__pycache__
    |           db.cpython-310.pyc
    |           __init__.cpython-310.pyc
    |           
    +---controllers
    |   |   note
    |   |   test_controller.py
    |   |   __init__.py
    |   |   
    |   +---account
    |   |       auth_controller.py
    |   |       
    |   \---__pycache__
    |           test_controller.cpython-310.pyc
    |           __init__.cpython-310.pyc
    |           
    +---models
    |       User.py
    |       __init__.py
    |       
    +---services
    |       __init__.py
    |       
    +---utils
    |       __init__.py
    |       
    \---__pycache__
            app.cpython-310.pyc
            __init__.cpython-310.pyc





목표 
=======================
서버 로직 Server
VSC [fastapi , postgresql]
=======================
    [S/db] src/config/db.py
        [S/db-01] db 연결 처리 
        [S/db-02] src/models/(현재 스코프 데이터 정의).py
    [S/app.py] src/app.py
        [S/db-01] 서버 가동 작업
    [S/bp] src/controllers/board/board_controller.py 및 서비스 로직
        [S/bp-01] 전체 시설 조회
        [S/bp-02] 시설 조회
        [S/bp-03] 포스트 조회
        [S/bp-04] 포스트 삭제
        [S/bp-05] 포스트 생성
        [S/bp-06] 포스트 수정
=======================
앱 로직 App
안드로이드 스튜디오 [플러터]
=======================
    [A/mian] main.dart
        [A/mian-01] 권한 주입 작업하기 
        [A/mian-02] board_main.dart 리다이렉션 해주기
    [A/bp] board_main.dart
        [A/bp-01] 분기 페이지 to [통합 보드,시설 보드]
        [A/bp-02] 통합 보드 (관리자용, 모든 시설)
        [A/bp-02/01] 접근처리 페이지 [허용:관리자]
        [A/bp-02/02] 포스트 리스트 , 페이징
        [A/bp-02/03] 포스트 생성 불가
        [A/bp-03] 시설 보드 페이지 (단일 시설)
        [A/bp-03/01] 접근처리 [허용:관리자, 해당 시설 사용자]
        [A/bp-03/02] 포스트 리스트 , 페이징
        [A/bp-03/03] 포스트 생성하기 분기
        [A/bp-04] 시설 포스트
        [A/bp-04/01] 시설 포스트 생성 페이지 - 생성 처리 (시설 보드에서 이어짐)
        [A/bp-04/02] 시설 포스트 수정 페이지  - 수정 처리
        [A/bp-04/03] 시설 포스트 조회 페이지- 댓글 작성 [허용:관리자, 해당 시설 사용자]
        [A/bp-04/04] 시설 포스트 [생성|수정] 페이지 -  quill 에디터와 이미지 처리 (저장)
        [A/bp-04/05] 시설 포스트 조회 페이지 -  quill 에디터와 이미지 처리 (재배치)



 board_main.dart에서 진행 중요한 내용은 
총 6개의 페이지 

시설 리스트 페이지(분기 페이지) : 현재 계정이 접근 가능한 모든 시설 보드가 리스트로 나열된 페이지, 시설의 명칭과 해당 시설 보드로 이동하는 기능 존재한다. 관리자, 유저 공동 페이지이며 정의될 첫 페이지, 관리자만 이 리스팅에 통합 조회 보드를 포함하면 된다. 

통합 조회 보드 : 관리자(admin)만 접근 가능한 모든 시설의 포스트가 있는 페이지;
시설 조회 보드 : 어떤 한 시설에 할당된 하나의 보드, 접근  가능한 대상은 해당 시설 사용자 및 관리자(admin) 권한; 

시설 포스트 생성 페이지 : 시설 조회 보드에서 포스트를 생성하는 기능(통합 조회 보드에서는 사용 불가);
시설 포스트 수정 페이지 : 시설 포스트 조회 페이지에서 포스트를 수정하는 기능(작성자만 접근 가능);
시설 포스트 조회 페이지 : 각 포스트의 개별적인 페이지, 통합 조회보드에서 접근 가능하다. ;

구조
분기 페이지[통합 조회 보드,시설 조회 보드] -> 일반적인 보드 포스트
