// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDeviceOnly => 'These settings apply to this device only.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get themeSystem => 'System default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsPanel => 'Control panel';

  @override
  String get settingsPanelNote =>
      'Applies only to the live control panel shown inside a room.';

  @override
  String get panelBackground => 'Background';

  @override
  String get panelOpacity => 'Transparency';

  @override
  String get panelValueSize => 'Reading size';

  @override
  String get panelLedDigits => 'LED digits';

  @override
  String get panelLedDigitsNote => 'Show numbers as a seven-segment display.';

  @override
  String get panelSampleLabel => 'Room temp';

  @override
  String get backgroundNone => 'None';

  @override
  String get backgroundBlueprint => 'Blueprint';

  @override
  String get backgroundCoil => 'Cooling coil';

  @override
  String get backgroundMetal => 'Metal';

  @override
  String get backgroundGrid => 'Grid';

  @override
  String get settingsAlarmStyle => 'Alarm alerts';

  @override
  String get alarmSound => 'Sound';

  @override
  String get alarmSoundNote => 'Play a sound when an alarm arrives.';

  @override
  String get alarmVibration => 'Vibration';

  @override
  String get alarmVibrationNote => 'Vibrate when an alarm arrives.';

  @override
  String get alarmLockScreen => 'Show details on lock screen';

  @override
  String get alarmLockScreenNote =>
      'When off, the lock screen only shows that an alarm arrived.';

  @override
  String get alarmRepeat => 'Remind again';

  @override
  String alarmRepeatNote(int count) {
    return 'If an alarm goes unread, remind you at the chosen interval up to $count more times.';
  }

  @override
  String get alarmRepeatNone => 'Off';

  @override
  String alarmRepeatMinutes(int minutes) {
    return '$minutes min';
  }
}
