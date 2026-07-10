import 'package:flutter/material.dart';
import 'chatlist.dart';
// ----------------------------------
enum UserRole {
  user,    // 일반 유저 (메신저 접근 가능)
  admin,   // 관리자 (메신저, 게시판 모두 접근 가능)
  guest,   // 비회원
}
// ----------------------------------
const UserRole currentLoggedInUserRole = UserRole.admin;
const String currentUserId = "a"; // 추후 DB에서 ID로 권한을 조회할 때 사용
// ----------------------------------


void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Role Based Routing',
      initialRoute: '/',
      // 권한 제어를 위해 RouteGenerator를 사용합니다.
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}

// [3] 권한 주입 및 페이지 접근 제어를 담당하는 공간
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {

    // 미래에 DB에서 ID로 권한을 가져오는 로직이 들어갈 곳입니다.
    // 예: final userRole = await UserRepository.getRoleById(currentUserId);
    final UserRole userRole = currentLoggedInUserRole;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case '/messenger':
      // 메신저는 user, admin 모두 접근 가능
        if (userRole == UserRole.user || userRole == UserRole.admin) {
          return MaterialPageRoute(builder: (_) => const MessengerScreen());
        }
        return _accessDeniedRoute();

      case '/board':
      // 게시판은 오직 admin만 접근 가능 (권한 체크)
        if (userRole == UserRole.admin) {
          return MaterialPageRoute(builder: (_) => const BoardScreen());
        }
        // 권한이 없으면 접근 거부 화면이나 NotFound로 리다이렉트
        return _accessDeniedRoute();

      default:
        return MaterialPageRoute(builder: (_) => const NotFoundScreen());
    }
  }

  // 권한 없음 처리 화면
  static Route<dynamic> _accessDeniedRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('접근 제한'), backgroundColor: Colors.orange.shade200),
        body: const Center(
          child: Text(
            '이 페이지에 접근할 권한이 없습니다.',
            style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// --- 아래는 화면 위젯들입니다 ---

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈 화면'),
        actions: [
          // 현재 상단에 주입된 권한 표시
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '현재 권한: ${currentLoggedInUserRole.name.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/messenger'),
              child: const Text('메신저 이동 (User 이상)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/board'),
              child: const Text('게시판 이동 (Admin 전용)'),
            ),
          ],
        ),
      ),
    );
  }
}

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('게시판 개발')), body: const Center(child: Text('게시판 페이지')));
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Not Found')), body: const Center(child: Text('페이지를 찾을 수 없습니다.')));
}