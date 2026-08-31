import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:idcs/firebase_options.dart';
import 'package:idcs/main.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 🔥 최상단 백그라운드 핸들러 (앱이 백그라운드/종료 상태일 때 처리)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🌙 [백그라운드 수신] ID: ${message.messageId}");

  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

  // 백그라운드 isolate 알림 초기화 추가
  const AndroidInitializationSettings initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  await localNotifications.initialize(const InitializationSettings(android: initSettingsAndroid));

  String title = message.notification?.title ?? message.data['title'] ?? '';
  String body = message.notification?.body ?? message.data['body'] ?? '';

  if (title.isNotEmpty || body.isNotEmpty) {
    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          '고중요 알림',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    '고중요 알림',
    description: '이 채널은 중요한 알림을 위해 사용됩니다.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> initialize() async {
    // 💡 1. 백그라운드 핸들러 선제 등록 (경고 로그 방지)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. FCM 권한 요청
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print("Notification permission status: ${settings.authorizationStatus}");

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {

      // 3. 로컬 알림 초기화
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

      await _localNotifications.initialize(initializationSettings);

      // 4. Android 구현체 획득 및 채널 재등록 (채널 꼬임 방지)
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.deleteNotificationChannel(_channel.id);
        await androidPlugin.createNotificationChannel(_channel);
      }

      // 💡 5. 포그라운드 메시지 수신 리스너
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print("🔥 [포그라운드 수신] ID: ${message.messageId}");
        print("🔥 [Notification]: ${message.notification?.title} / ${message.notification?.body}");
        print("🔥 [Data]: ${message.data}");

        String title = message.notification?.title ?? message.data['title'] ?? '알림';
        String body = message.notification?.body ?? message.data['body'] ?? '';

        try {
          await _localNotifications.show(
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title,
            body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                icon: '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
              ),
            ),
          );
          print("✅ 로컬 알림 show() 정상 실행 완료");
        } catch (e) {
          print("❌ 로컬 알림 show() 실행 중 에러 발생: $e");
        }
      });

      // 6. 알림 클릭 이벤트
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('알림 클릭으로 앱 실행: ${message.data}');
      });

      // 7. 토큰 갱신 리스너
      _messaging.onTokenRefresh.listen((newToken) {
        print("FCM 토큰 변경됨: $newToken");
        if (AuthService.getCurrentUserId() != null) {
          registToken();
        }
      });
    }
  }

  static Future<String?> getToken() async {
    try {
      String? token = await _messaging.getToken();
      return token;
    } catch (e) {
      print("FCM 토큰 가져오기 실패: $e");
      return null;
    }
  }

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