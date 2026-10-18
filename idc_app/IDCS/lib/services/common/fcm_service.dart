import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:flutter/widgets.dart' show Locale;
import 'package:idcs/l10n/app_localizations.dart';
import 'package:idcs/theme/locale_controller.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:idcs/firebase_options.dart';
import 'package:idcs/main.dart';
import 'api_client.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:idcs/services/common/alarm/alarm_settings.dart';

/// Loads the app's strings without a BuildContext.
///
/// Notification text is produced outside the widget tree — at startup, and from
/// a background isolate — so it cannot read the locale from a widget. The user's
/// own choice wins; otherwise the device language, falling back to Korean when
/// it is one the app does not carry.
Future<AppLocalizations> _strings() {
  final chosen = LocaleController.locale.value;
  final device = PlatformDispatcher.instance.locale;
  final supported = AppLocalizations.supportedLocales
      .any((l) => l.languageCode == device.languageCode);
  return AppLocalizations.delegate
      .load(chosen ?? (supported ? Locale(device.languageCode) : const Locale('ko')));
}

// 안드로이드는 채널을 한 번 만들면 소리/진동 설정을 나중에 바꿀 수 없다.
// 그래서 조합별로 채널을 미리 만들어 두고, 알림을 띄울 때 설정에 맞는 채널을 고른다.
//
// 채널 이름도 처음 만들 때 고정된다 — 나중에 앱 언어를 바꿔도 안드로이드 설정에
// 보이는 이름은 그대로다. 재설치해야 새 언어로 다시 만들어진다.
enum _AlarmChannel {
  soundVibe('alarm_sound_vibe', sound: true, vibration: true),
  soundOnly('alarm_sound', sound: true, vibration: false),
  vibeOnly('alarm_vibe', sound: false, vibration: true),
  silent('alarm_silent', sound: false, vibration: false);

  const _AlarmChannel(this.id, {required this.sound, required this.vibration});

  final String id;
  final bool sound;
  final bool vibration;

  String name(AppLocalizations l) => switch (this) {
        soundVibe => l.channelSoundVibe,
        soundOnly => l.channelSoundOnly,
        vibeOnly => l.channelVibeOnly,
        silent => l.channelSilent,
      };

  String description(AppLocalizations l) => switch (this) {
        soundVibe => l.channelSoundVibeDesc,
        soundOnly => l.channelSoundOnlyDesc,
        vibeOnly => l.channelVibeOnlyDesc,
        silent => l.channelSilentDesc,
      };

  AndroidNotificationChannel toChannel(AppLocalizations l) => AndroidNotificationChannel(
        id,
        name(l),
        description: description(l),
        importance: Importance.max,
        playSound: sound,
        enableVibration: vibration,
      );
}

_AlarmChannel _channelFor(AlarmSettings s) {
  if (s.sound && s.vibration) return _AlarmChannel.soundVibe;
  if (s.sound) return _AlarmChannel.soundOnly;
  if (s.vibration) return _AlarmChannel.vibeOnly;
  return _AlarmChannel.silent;
}

NotificationDetails _detailsFor(AlarmSettings s, AppLocalizations l10n) {
  final channel = _channelFor(s);
  return NotificationDetails(
    android: AndroidNotificationDetails(
      channel.id,
      channel.name(l10n),
      channelDescription: channel.description(l10n),
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
  final l10n = await _strings();
  final details = _detailsFor(settings, l10n);
  final baseId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  await plugin.show(baseId, title, body, details);

  if (settings.repeatMinutes <= 0) return;

  // 확인하지 못했을 때를 대비한 재알림. 무한 반복은 알림 폭탄이 되므로 횟수를 제한한다.
  for (int i = 1; i <= AlarmSettings.maxRepeatCount; i++) {
    await plugin.zonedSchedule(
      baseId + i,
      title,
      l10n.alarmRepeatSuffix(body, i, AlarmSettings.maxRepeatCount),
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
  debugPrint("🌙 [백그라운드 수신] ID: ${message.messageId}");

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

    debugPrint("Notification permission status: ${settings.authorizationStatus}");

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
        final channelStrings = await _strings();
        for (final channel in _AlarmChannel.values) {
          await androidPlugin.createNotificationChannel(channel.toChannel(channelStrings));
        }
      }

      // 💡 5. 포그라운드 메시지 수신 리스너
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint("🔥 [포그라운드 수신] ID: ${message.messageId}");
        debugPrint("🔥 [Notification]: ${message.notification?.title} / ${message.notification?.body}");
        debugPrint("🔥 [Data]: ${message.data}");

        String title = message.notification?.title ?? message.data['title'] ?? (await _strings()).notificationFallbackTitle;
        String body = message.notification?.body ?? message.data['body'] ?? '';

        try {
          await showAlarmNotification(_localNotifications, title, body);
          debugPrint("✅ 로컬 알림 show() 정상 실행 완료");
        } catch (e) {
          debugPrint("❌ 로컬 알림 show() 실행 중 에러 발생: $e");
        }
      });

      // 6. 알림 클릭 이벤트
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('알림 클릭으로 앱 실행: ${message.data}');
      });

      // 7. 토큰 갱신 리스너
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint("FCM 토큰 변경됨: $newToken");
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
      debugPrint("FCM 토큰 가져오기 실패: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> registToken() async {
    try {
      String? token = await getToken();
      if (token == null) {
        debugPrint("FCM 토큰이 없어 서버 등록을 건너뜁니다.");
        return null;
      }

      debugPrint("발급된 토큰: $token");
      final url = Uri.parse('${AppConfig.baseUrl}/alarms/register');
      final response = await ApiClient.post(
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
        throw ApiException.rejected(error);
      }
    } catch (e) {
      debugPrint("registToken 에러: $e");
      rethrow;
    }
  }
}