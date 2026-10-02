// 경로: lib/auth_service.dart
// 명세: 로그인 상태(유저 ID) 보관 및 로컬 저장소 연동
//
// config.dart는 개발자마다 서버 주소가 달라 .gitignore에 등록되어 있다.
// AuthService는 모두가 공유하는 로직이라 이 파일로 분리해 버전 관리에 포함시킨다.
part of 'main.dart';

class AuthService {
  static int? _currentUserId;

  static bool get isLoggedIn => _currentUserId != null;
  static int? getCurrentUserId() => _currentUserId;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('userId');
  }

  /// [persist]가 false면 앱을 껐다 켰을 때 로그인이 풀리도록 메모리에만 보관한다.
  /// (로그인 화면의 '로그인 상태 유지' 체크박스와 연결된다)
  static Future<void> setUserId(int? id, {bool persist = true}) async {
    _currentUserId = id;
    final prefs = await SharedPreferences.getInstance();
    if (id != null && persist) {
      await prefs.setInt('userId', id);
    } else {
      await prefs.remove('userId');
    }
  }
}
