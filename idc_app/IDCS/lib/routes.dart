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

    // [index] - 유저 레벨 3개 섹션(홈/알람/내 정보) 하단 네비게이션 셸.
    // 시설 셸과 동일한 이유로 상위 라우트가 :userId를 소유하고 브랜치는 상대 경로만 갖는다.
    GoRoute(
      path: '/index/:userId',
      redirect: (context, state) => state.matchedLocation == state.uri.toString()
          ? '${state.matchedLocation}/home'
          : null,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => UserShellPage(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: 'home',
                builder: (context, state) => MainIndexPage(userId: state.pathParameters['userId']!),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: 'alarm',
                builder: (context, state) => MainAlarmPage(userId: state.pathParameters['userId']!),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: 'profile',
                builder: (context, state) => PersonalPage(userId: state.pathParameters['userId']!),
              ),
            ]),
          ],
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
                path: 'chat',
                builder: (context, state) => FacilityChatListPage(
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
      builder: (context, state) => ChatRoomPage(
        userId: state.pathParameters['userId']!,
        roomId: int.parse(state.pathParameters['roomId']!),
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