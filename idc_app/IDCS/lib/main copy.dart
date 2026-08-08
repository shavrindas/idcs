// ===============================================================
// 경로 : lib/main.dart
// 명세 : 권한 주입 간소화 및 라우팅
// ===============================================================
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';


import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:idcs/components/indices/main_alarm/facility_alarm_components.dart';
import 'package:idcs/components/indices/settings_page.dart';
import 'package:idcs/pages/common/find_pw_page.dart';
import 'package:idcs/pages/common/login_page.dart';
import 'package:idcs/pages/common/signup_page.dart';
import 'package:idcs/pages/common/find_id_page.dart';
import 'package:idcs/pages/facility/monitoring//monitoring_room.dart';
import 'package:idcs/pages/facility/facility_temp_nav_page.dart';
import 'package:idcs/pages/facility/monitoring/monitoring_page.dart';
import 'package:idcs/pages/indices/account_edit_page.dart';
import 'package:idcs/pages/facility/facility_alarm_page.dart';
import 'package:idcs/pages/indices/main_alarm_page.dart';
import 'package:idcs/pages/indices/main_index_page.dart';
import 'package:idcs/pages/indices/facility_register_page.dart';
import 'package:idcs/pages/indices/total_board_page.dart';
import 'package:idcs/pages/facility/board/facility_board_page.dart';
import 'package:idcs/pages/facility/board/post_detail_page.dart';
import 'package:idcs/pages/facility/board/post_create_page.dart';
import 'package:idcs/pages/facility/board/post_edit_page.dart';
import 'package:idcs/pages/facility/chat/facility_chat_list_page.dart';
import 'package:idcs/pages/facility/chat/chat_room_page.dart';
import 'package:idcs/pages/facility/chart/facility_chart_page.dart';
import 'pages/common/opening_page.dart';
import 'package:idcs/pages/facility/facility_alarm_page.dart';
import 'package:intl/date_symbol_data_local.dart';
//
// part 'config.dart';
// part 'routes.dart';


// ===============================================================
// AuthService
// ===============================================================

// class AuthService {
//   // 테스트를 위해 이 값을 변경하며 진행합니다. (1: 관리자, 사용자는 아래 참조 )
//   // (1, 4), (1, 5), (1, 6),    -- 1시설에 a(4), b(5), c(6) 배분
//   // (2, 7), (2, 8), (2, 9),    -- 2시설에 d(7), e(8), f(9) 배분
//   // (3, 4), (3, 7), (3, 10);   -- 3시설에 a(4), d(7), g(10) 배분
//   static int _mockUserId = 1;
//   static int getCurrentUserId() => _mockUserId;
//   static void setUserId(int id) {_mockUserId = id;}
// }

class AuthService {
  static int? _currentUserId; // null이면 비로그인 상태로 간주

  // 로그인 상태 판별 (ID가 있으면 로그인된 것)
  static bool get isLoggedIn => _currentUserId != null;

  static int? getCurrentUserId() => _currentUserId;
  static void setUserId(int? id) { _currentUserId = id; }
}

// ===============================================================
// main
// ===============================================================

// class AppConfig {// 안드로이드 에뮬레이터 로컬 루프백 주소
//   static const String baseUrl = 'http://127.0.0.1:8000/api';
//   static const String basewsUrl = 'ws://127.0.0.1:8000/api';
// }

// class AppConfig {// 안드로이드 에뮬레이터 로컬 루프백 주소
//   static const String baseUrl = 'http://172.29.112.1:8000/api';
//   static const String basewsUrl = 'ws://172.29.112.1:8000/api';
// }

class AppConfig {// 안드로이드 에뮬레이터 로컬 루프백 주소
  static const String baseUrl = 'http://192.168.29.159:8000/api';
  static const String basewsUrl = 'ws://192.168.29.159:8000/api';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko_KR', null);
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IDCool Systems Routing',
      // GoRouter 연결
      routerConfig: appRouter,

      // ─── Quill v11 다국어 딜리게이트  ───
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'), // 기본 한국어 설정
        Locale('en', 'US'), // 영어 설정
      ],
      // ──────────────────────────────────────────────────
    );
  }
}


// ===============================================================
// 라우터 설정
// ===============================================================

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) => const NotFoundScreen(),

  // refreshListenable: authService, // 인증 상태 변화 감지 (AuthService 연결 필요)
  redirect: (context, state) {
    final bool loggedIn = AuthService.isLoggedIn;
    final String path = state.matchedLocation;

    // 비로그인 상태에서도 허용할 경로 리스트 (오프닝, 로그인, 가입, 아이디/비번 찾기)
    final allowedPaths = ['/', '/login', '/signup', '/find_id', '/find_pw'];

    // 로그인하지 않은 사용자가 허용되지 않은 경로로 접근하려고 할 때만 로그인 페이지로 리다이렉트
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

// // 1. 단순 이동
// context.go('/login');
//
// // 2. 파라미터가 있는 이동 (main_index 등)
// context.go('/main_index/1');
//
// // 3. 복합 파라미터 이동 (facility_board 등)
// context.go('/facility_board/1/A01');





class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Not Found')), body: const Center(child: Text('페이지를 찾을 수 없습니다.')));
}