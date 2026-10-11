// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsDeviceOnly => '이 설정은 이 기기에만 적용됩니다.';

  @override
  String get settingsLanguage => '언어';

  @override
  String get languageSystem => '시스템 설정';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsTheme => '화면 테마';

  @override
  String get themeSystem => '시스템 설정';

  @override
  String get themeLight => '밝게';

  @override
  String get themeDark => '어둡게';

  @override
  String get settingsPanel => '제어판 화면';

  @override
  String get settingsPanelNote => '호실에 들어갔을 때 보이는 실시간 제어판에만 적용됩니다.';

  @override
  String get panelBackground => '배경';

  @override
  String get panelOpacity => '투명도';

  @override
  String get panelValueSize => '숫자 크기';

  @override
  String get panelLedDigits => 'LED 숫자';

  @override
  String get panelLedDigitsNote => '숫자를 7세그먼트 표시기 모양으로 보여줍니다.';

  @override
  String get panelSampleLabel => '고내온도';

  @override
  String get backgroundNone => '없음';

  @override
  String get backgroundBlueprint => '도면';

  @override
  String get backgroundCoil => '냉각 코일';

  @override
  String get backgroundMetal => '금속';

  @override
  String get backgroundGrid => '격자';

  @override
  String get settingsAlarmStyle => '알림 방식';

  @override
  String get alarmSound => '소리';

  @override
  String get alarmSoundNote => '알람이 올 때 소리로 알립니다.';

  @override
  String get alarmVibration => '진동';

  @override
  String get alarmVibrationNote => '알람이 올 때 진동으로 알립니다.';

  @override
  String get alarmLockScreen => '잠금화면에 내용 표시';

  @override
  String get alarmLockScreenNote => '꺼두면 잠금화면에서는 알람이 왔다는 사실만 보입니다.';

  @override
  String get alarmRepeat => '다시 알림';

  @override
  String alarmRepeatNote(int count) {
    return '알람을 확인하지 못했을 때 설정한 간격으로 최대 $count번까지 다시 알려줍니다.';
  }

  @override
  String get alarmRepeatNone => '없음';

  @override
  String alarmRepeatMinutes(int minutes) {
    return '$minutes분';
  }
}
