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

    // [main_indices] - 유저 ID 기반
    GoRoute(path: '/main_index/:userId', builder: (context, state) => MainIndexPage(userId: state.pathParameters['userId']!)),
    GoRoute(path: '/facility_register/:userId', builder: (context, state) => FacilityRegisterPage(userId: state.pathParameters['userId']!)),
    GoRoute(path: '/main_alarm/:userId', builder: (context, state) => MainAlarmPage(userId: state.pathParameters['userId']!)),
    GoRoute(path: '/user_alarm/:userId', builder: (context, state) => MainAlarmPage(userId: state.pathParameters['userId']!)),
    GoRoute(
      path: '/total_board/:userId',
      builder: (context, state) => TotalBoardPage(
        userId: state.pathParameters['userId']!,
      ),
    ),
    // main_indices/[settings]
    GoRoute(path: '/settings/:userId', builder: (context, state) => SettingsPage(userId: state.pathParameters['userId']!)),
    GoRoute(path: '/personal/:userId', builder: (context, state) => PersonalPage(userId: state.pathParameters['userId']!)),

    // [facility] - 유저 ID & 시설 ID 기반
    GoRoute(path: '/facility_nav/:userId/:facilityId', builder: (context, state) => FacilityTempNavPage(userId: state.pathParameters['userId']!, facilityId: state.pathParameters['facilityId']!,)),




    // 1. 시설 소요 기록 목록 페이지
    GoRoute(
      path: '/facility_board/:userId/:facilityId',
      builder: (context, state) => FacilityBoardPage(
        userId: state.pathParameters['userId']!,
        facilityId: state.pathParameters['facilityId']!,
      ),
    ),

    // 2. 게시글 상세 페이지
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
    // [facility_monitoring]
    GoRoute(
      path: '/facility_monitoring/:userId/:facilityId/:roomId',
      builder: (context, state) => MonitoringPage(
        userId: state.pathParameters['userId']!,
        facilityId: state.pathParameters['facilityId']!,
        roomId: state.pathParameters['roomId']!,
      ),
    ),

    // [facility_room]
    GoRoute(
      path: '/facility_room/:userId/:facilityId',
      builder: (context, state) => MonitoringRoom(
        userId: state.pathParameters['userId']!,
        facilityId: state.pathParameters['facilityId']!,
      ),
    ),
    //모니터링 끝-------------------------------------------------------------------

    //알람 관련-------------------------------------------------------------------
    // 1. 시설 알람 페이지
    GoRoute(
      path: '/facility_alarm/:userId/:facilityId',
      builder: (context, state) => FacilityAlarmPage(
        userId: state.pathParameters['userId']!,
        facilityId: state.pathParameters['facilityId']!,
      ),
    ),

    //알람 끝-------------------------------------------------------------------
    // facility_chat
    GoRoute(
      path: '/chat_list/:userId/:facilityId',
      builder: (context, state) => FacilityChatListPage(
        userId: state.pathParameters['userId']!,
        facilityId: state.pathParameters['facilityId']!,
      ),
    ),
    GoRoute(
      path: '/chat_room/:userId/:roomId',
      builder: (context, state) => ChatRoomPage(
        userId: state.pathParameters['userId']!,
        roomId: int.parse(state.pathParameters['roomId']!),
      ),
    ),


    GoRoute(
      path: '/facility_chart/:userId/:facilityId',
      builder: (context, state) => FacilityChartPage(
        userId: state.pathParameters['userId']!,
        facilityId: state.pathParameters['facilityId']!,
      ),
    ),


  ],
);

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: const Center(child: Text('페이지를 찾을 수 없습니다.')),
      );
}