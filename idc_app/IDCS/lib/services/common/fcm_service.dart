import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:idcs/firebase_options.dart';
import 'package:idcs/main.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:idcs/services/common/alarm/alarm_settings.dart';

// 안드로이드는 채널을 한 번 만들면 소리/진동 설정을 나중에 바꿀 수 없다.
// 그래서 조합별로 채널을 미리 만들어 두고, 알림을 띄울 때 설정에 맞는 채널을 고른다.
const List<AndroidNotificationChannel> alarmChannels = [
  AndroidNotificationChannel('alarm_sound_vibe', '알람 (소리+진동)',
      description: '소리와 진동을 모두 사용하는 알람', importance: Importance.max, playSound: true, enableVibration: true),
  AndroidNotificationChannel('alarm_sound', '알람 (소리만)',
      description: '소리만 사용하는 알람', importance: Importance.max, playSound: true, enableVibration: false),
  AndroidNotificationChannel('alarm_vibe', '알람 (진동만)',
      description: '진동만 사용하는 알람', importance: Importance.max, playSound: false, enableVibration: true),
  AndroidNotificationChannel('alarm_silent', '알람 (무음)',
      description: '소리와 진동 없이 표시만 하는 알람', importance: Importance.max, playSound: false, enableVibration: false),
];

AndroidNotificationChannel _channelFor(AlarmSettings s) {
  if (s.sound && s.vibration) return alarmChannels[0];
  if (s.sound) return alarmChannels[1];
  if (s.vibration) return alarmChannels[2];
  return alarmChannels[3];
}

NotificationDetails _detailsFor(AlarmSettings s) {
  final channel = _channelFor(s);
  return NotificationDetails(
    android: AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
      playSound: s.sound,
      enableVibration: s.vibration,
      // 잠금화면에서 내용을 숨길지 여부
      visibility: s.showOnLockScreen ? NotificationVisibility.public : NotificationVisibility.private,
    ),
  );
}

/// 알람을 띄우고, '다시 알림'이 켜져 있으면 뒤이어 재알림을 예약한다.
Future<void> showAlarmNotification(
  FlutterLocalNotificationsPlugin plugin,
  String title,
  String body,
) async {
  final settings = await AlarmSettings.load();
  final details = _detailsFor(settings);
  final baseId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  await plugin.show(baseId, title, body, details);

  if (settings.repeatMinutes <= 0) return;

  // 확인하지 못했을 때를 대비한 재알림. 무한 반복은 알림 폭탄이 되므로 횟수를 제한한다.
  for (int i = 1; i <= AlarmSettings.maxRepeatCount; i++) {
    await plugin.zonedSchedule(
      baseId + i,
      title,
      '$body (다시 알림 $i/${AlarmSettings.maxRepeatCount})',
      tz.TZDateTime.now(tz.local).add(Duration(minutes: settings.repeatMinutes * i)),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

// 🔥 최상단 백그라운드 핸들러 (앱이 백그라운드/종료 상태일 때 처리)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🌙 [백그라운드 수신] ID: ${message.messageId}");

  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

  // 백그라운드 isolate 알림 초기화 추가
  const AndroidInitializationSettings initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  await localNotifications.initialize(const InitializationSettings(android: initSettingsAndroid));

  // 백그라운드는 별도 isolate라 앱에서 초기화한 타임존 정보가 없다.
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  String title = message.notification?.title ?? message.data['title'] ?? '';
  String body = message.notification?.body ?? message.data['body'] ?? '';

  if (title.isNotEmpty || body.isNotEmpty) {
    await showAlarmNotification(localNotifications, title, body);
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 다시 알림 예약에 필요. 앱이 한국 기준으로 동작하므로 서울로 고정한다.
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

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
        // 소리/진동 조합별 채널을 모두 등록해 두고, 알림을 띄울 때 설정에 맞는 것을 고른다.
        for (final channel in alarmChannels) {
          await androidPlugin.createNotificationChannel(channel);
        }
      }

      // 💡 5. 포그라운드 메시지 수신 리스너
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print("🔥 [포그라운드 수신] ID: ${message.messageId}");
        print("🔥 [Notification]: ${message.notification?.title} / ${message.notification?.body}");
        print("🔥 [Data]: ${message.data}");

        String title = message.notification?.title ?? message.data['title'] ?? '알림';
        String body = message.notification?.body ?? message.data['body'] ?? '';

        try {
          await showAlarmNotification(_localNotifications, title, body);
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