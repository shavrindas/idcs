// 경로: lib/routes.dart
part of 'main.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) => const NotFoundScreen(),

  redirect: (context, state) {
    final bool loggedIn = AuthService.isLoggedIn;
    final String path = state.matchedLocation;

    final allowedPaths = ['/', '/login', '/signup', '/find_id', '/find_pw'];

    if (!loggedIn && !allowedPaths.contains(path)) {
      return '/login';
    }

    // 로그인이 유지된 상태면 스플래시/로그인 화면을 건너뛰고 바로 홈으로 보낸다.
    if (loggedIn && (path == '/' || path == '/login')) {
      return '/index/${AuthService.getCurrentUserId()}/home';
    }
    return null;
  },


  routes: [
    // [common]
    GoRoute(path: '/', builder: (context, state) => const OpeningPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
    GoRoute(path: '/find_id', builder: (context, state) => const FindIdPage()),
    GoRoute(path: '/find_pw', builder: (context, state) => const FindPwPage()),
    // GoRoute(path: '/reset_pw', builder: (context, state) => const ResetPwPage()),

    // [index] - 유저 레벨. 하단 네비게이션이 없다.
    //
    // 예전에는 여기에도 탭 바가 하나 있었다(홈/개괄/알람/내 정보). 시설에 들어가면
    // 그 바가 통째로 다른 다섯 개로 바뀌고, '알람'은 양쪽에 하나씩 있어서 같은
    // 이름이 서로 다른 화면을 가리켰다. 바가 발밑에서 바뀌는 화면은 어디에 있는지
    // 알기 어렵다.
    //
    // 이제 유저 레벨은 화면 하나다 — '전체 현황'이 그 자리를 맡는다. '내 시설'은
    // 따로 둘 이유가 없었다. 전체 현황이 이미 시설마다 이름과 호실을 다 보여주고,
    // 시설 이름 줄을 누르면 그 시설로 들어간다. 알람과 내 정보는 헤더로 올라갔고,
    // 눌렀을 때 이 화면 위로 풀스크린 push 된다.
    //
    // 'home' 경로를 그대로 둔 것은 로그인·스플래시·시설 셸이 모두 이 경로로
    // 돌아오기 때문이다. 가리키는 화면만 바뀐다.
    GoRoute(
      path: '/index/:userId',
      redirect: (context, state) => state.matchedLocation == state.uri.toString()
          ? '${state.matchedLocation}/home'
          : null,
      routes: [
        GoRoute(
          path: 'home',
          builder: (context, state) => MonitoringAll(userId: state.pathParameters['userId']!),
        ),
        GoRoute(
          path: 'alarm',
          builder: (context, state) => MainAlarmPage(userId: state.pathParameters['userId']!),
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => PersonalPage(userId: state.pathParameters['userId']!),
        ),
      ],
    ),

    // 자주 쓰지 않는 화면 - 셸 위로 풀스크린 push (시설 등록: 관리자 제외, 통합 소요기록: 관리자 전용)
    GoRoute(path: '/facility_register/:userId', builder: (context, state) => FacilityRegisterPage(userId: state.pathParameters['userId']!)),
    GoRoute(
      path: '/total_board/:userId',
      builder: (context, state) => TotalBoardPage(
        userId: state.pathParameters['userId']!,
      ),
    ),

    // [facility] - 유저 ID & 시설 ID 기반
    // 시설 내부 5개 섹션(모니터링/차트/소요기록/메신저/알람) 하단 네비게이션 셸.
    // go_router 제약상 브랜치 라우트 자체는 파라미터를 가질 수 없으므로,
    // userId/facilityId는 상위 라우트가 소유하고 브랜치는 상대 경로(monitoring, chart 등)만 갖는다.
    GoRoute(
      path: '/facility/:userId/:facilityId',
      // 하위 라우트(monitoring/chart/board/chat/alarm) 없이 이 경로만 단독으로
      // 방문되는 경우는 없으므로(항상 구체적 탭 경로로 이동) 별도 redirect는 두지 않는다.
      redirect: (context, state) => state.matchedLocation == state.uri.toString()
          ? '${state.matchedLocation}/monitoring'
          : null,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => FacilityShellPage(
            userId: state.pathParameters['userId']!,
            facilityId: state.pathParameters['facilityId']!,
            navigationShell: navigationShell,
          ),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: 'monitoring',
                builder: (context, state) => MonitoringRoom(
                  userId: state.pathParameters['userId']!,
                  facilityId: state.pathParameters['facilityId']!,
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: 'chart',
                builder: (context, state) => FacilityChartPage(
                  userId: state.pathParameters['userId']!,
                  facilityId: state.pathParameters['facilityId']!,
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: 'board',
                builder: (context, state) => FacilityBoardPage(
                  userId: state.pathParameters['userId']!,
                  facilityId: state.pathParameters['facilityId']!,
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: 'alarm',
                builder: (context, state) => FacilityAlarmPage(
                  userId: state.pathParameters['userId']!,
                  facilityId: state.pathParameters['facilityId']!,
                ),
              ),
            ]),
          ],
        ),
      ],
    ),

    // 1. 게시글 상세 페이지
    GoRoute(
      path: '/post_detail/:userId/:postId',
      builder: (context, state) => PostDetailPage(
        userId: state.pathParameters['userId']!,
        postId: int.parse(state.pathParameters['postId']!),
      ),
    ),

    // 3. 게시글 작성 페이지
    GoRoute(
      path: '/post_create/:userId/:facilityId',
      builder: (context, state) => PostCreatePage(
        userId: state.pathParameters['userId']!,
        facilityId: state.pathParameters['facilityId']!,
      ),
    ),

    // 4. 게시글 수정 페이지
    GoRoute(
      path: '/post_edit/:userId/:postId',
      builder: (context, state) => PostEditPage(
        userId: state.pathParameters['userId']!,
        postId: int.parse(state.pathParameters['postId']!),
      ),
    ),

    //여기서부터는 모니터링 관련
    //--------------------------------------------------------------------------------
    // [facility_monitoring] - 호실 상세(라이브 제어판). 셸 위로 풀스크린 push.
    // 메신저. 하단 탭에서 헤더 아이콘으로 옮겼다 — 탭 다섯 개 중 이것만
    // 설비 상태와 무관한 '사람끼리 주고받는' 화면이라, 나머지 넷과 같은 줄에
    // 있으면 무엇을 고르는 자리인지가 흐려진다. 셸 위로 풀스크린 push 된다.
    GoRoute(
      path: '/facility_chat/:userId/:facilityId',
      builder: (context, state) => FacilityChatListPage(
        userId: state.pathParameters['userId']!,
        facilityId: state.pathParameters['facilityId']!,
      ),
    ),

    GoRoute(
      path: '/facility_monitoring/:userId/:facilityId/:roomId',
      builder: (context, state) => MonitoringPage(
        userId: state.pathParameters['userId']!,
        facilityId: state.pathParameters['facilityId']!,
        roomId: state.pathParameters['roomId']!,
      ),
    ),
    
    //모니터링 끝-------------------------------------------------------------------

    // [chat_room] - 채팅방 상세. 셸 위로 풀스크린 push.
    GoRoute(
      path: '/chat_room/:userId/:roomId',
      // 방 이름은 목록이 이미 알고 있다. 상세에서 다시 묻지 않고 넘겨 받는다.
      builder: (context, state) => ChatRoomPage(
        userId: state.pathParameters['userId']!,
        roomId: int.parse(state.pathParameters['roomId']!),
        roomName: state.extra is String ? state.extra as String : null,
      ),
    ),

  ],
);

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: Center(child: Text(context.l10n.notFound)),
      );
}