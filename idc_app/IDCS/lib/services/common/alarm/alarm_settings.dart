// ===============================================================
// 경로: lib/services/common/alarm/alarm_settings.dart
// 명세: 알람 표시 방식(소리/진동/잠금화면/다시 알림) 설정 보관
// ===============================================================
import 'package:shared_preferences/shared_preferences.dart';

/// 알람 설정. 기기마다 다른 취향이라 서버가 아닌 기기 로컬에 저장한다.
class AlarmSettings {
  final bool sound;
  final bool vibration;

  /// 잠금화면에서도 내용까지 보여줄지 여부.
  final bool showOnLockScreen;

  /// 확인하지 않았을 때 다시 알려줄 간격(분). 0이면 다시 알리지 않는다.
  final int repeatMinutes;

  const AlarmSettings({
    this.sound = true,
    this.vibration = true,
    this.showOnLockScreen = true,
    this.repeatMinutes = 0,
  });

  /// 다시 알림에서 고를 수 있는 간격. 0은 '없음'.
  static const List<int> repeatOptions = [0, 5, 10, 30];

  /// 다시 알림을 최대 몇 번까지 더 보낼지. 무한 반복은 알림 폭탄이 되므로 제한한다.
  static const int maxRepeatCount = 3;

  static const _kSound = 'alarm_sound';
  static const _kVibration = 'alarm_vibration';
  static const _kLockScreen = 'alarm_lock_screen';
  static const _kRepeatMinutes = 'alarm_repeat_minutes';

  AlarmSettings copyWith({
    bool? sound,
    bool? vibration,
    bool? showOnLockScreen,
    int? repeatMinutes,
  }) {
    return AlarmSettings(
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      showOnLockScreen: showOnLockScreen ?? this.showOnLockScreen,
      repeatMinutes: repeatMinutes ?? this.repeatMinutes,
    );
  }

  static Future<AlarmSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AlarmSettings(
      sound: prefs.getBool(_kSound) ?? true,
      vibration: prefs.getBool(_kVibration) ?? true,
      showOnLockScreen: prefs.getBool(_kLockScreen) ?? true,
      repeatMinutes: prefs.getInt(_kRepeatMinutes) ?? 0,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSound, sound);
    await prefs.setBool(_kVibration, vibration);
    await prefs.setBool(_kLockScreen, showOnLockScreen);
    await prefs.setInt(_kRepeatMinutes, repeatMinutes);
  }
}
