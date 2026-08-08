// 경로: lib/config.dart
part of 'main.dart';

class AppConfig {
  static const String baseUrl = 'http://192.168.29.159:8000/api';
  static const String basewsUrl = 'ws://192.168.29.159:8000/api';

  // 💡 향후 추가될 모든 초기화 로직은 main.dart가 아닌 여기에 추가합니다.
  static Future<void> initializeAll() async {
    await initializeDateFormatting('ko_KR', null);
    await Firebase.initializeApp();
    await AuthService.init(); // 로그인 상태 로컬 저장소에서 불러오기
  }
}

class AuthService {
  static int? _currentUserId;

  static bool get isLoggedIn => _currentUserId != null;
  static int? getCurrentUserId() => _currentUserId;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('userId');
  }

  static Future<void> setUserId(int? id) async {
    _currentUserId = id;
    final prefs = await SharedPreferences.getInstance();
    if (id != null) {
      await prefs.setInt('userId', id);
    } else {
      await prefs.remove('userId');
    }
  }
}