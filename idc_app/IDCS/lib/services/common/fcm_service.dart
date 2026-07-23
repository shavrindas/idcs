import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:idcs/firebase_options.dart';
import 'package:idcs/main.dart';
import 'package:http/http.dart' as http;

// 백그라운드 핸들러
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("백그라운드 메시지 수신: ${message.messageId}");
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  // 💡 수정 핵심: 정적 변수로 즉시 생성하지 않고 Getter로 필요할 때 초기화된 인스턴스를 가져옵니다.
  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  // 1. 초기화 메서드 (권한 요청 및 이벤트 리스너)
  static Future<void> initialize() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 포그라운드 수신
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('포그라운드 메시지 수신: ${message.notification?.title}');
      });

      // 알림 클릭 이벤트
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('알림 클릭으로 앱 실행: ${message.data}');
      });

      // 토큰이 갱신(변경)될 때 자동으로 실행되는 리스너
      _messaging.onTokenRefresh.listen((newToken) {
        print("FCM 토큰이 새롭게 변경됨: $newToken");
        if (AuthService.getCurrentUserId() != null) {
          registToken();
        }
      });
    }
  }

  // 2. 토큰 반환 메서드
  static Future<String?> getToken() async {
    try {
      String? token = await _messaging.getToken();
      return token;
    } catch (e) {
      print("FCM 토큰 가져오기 실패: $e");
      return null;
    }
  }

  /// Box #1: 안드로이드->서버 토큰 저장
  static Future<Map<String, dynamic>?> registToken() async {
    try {
      String? token = await getToken();
      if (token == null) {
        print("FCM 토큰이 없어 서버 등록을 건너뜁니다.");
        return null;
      }

      print("발급된 토큰: $token");
      final url = Uri.parse('${AppConfig.baseUrl}/alarms/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fcm_token': token,
          'user_id': AuthService.getCurrentUserId()
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? '토큰 등록에 실패했습니다.');
      }
    } catch (e) {
      print("registToken 에러: $e");
      rethrow;
    }
  }
}