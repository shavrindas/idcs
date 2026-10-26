// ===============================================================
// 경로: lib/services/common/monitoring_view_settings.dart
// 명세: 실시간 제어판의 겉모습 설정(배경·패널 투명도·숫자 크기·LED 숫자) 보관
// ===============================================================
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How the live control panel looks. Device-local, like [AlarmSettings] —
/// it is a matter of taste and of the screen being looked at, not of the account.
@immutable
class MonitoringViewSettings {
  /// Panel fill opacity. 1.0 keeps the solid cards the app has always had.
  final double panelOpacity;

  /// Multiplier on the value text size only; labels keep their size.
  final double valueFontScale;

  /// Draw numeric readings in a seven-segment face.
  final bool ledDigits;

  /// 모든 화면 뒤에서 눈을 내릴지.
  final bool snow;

  /// Rule a line above and below the big temperature on room cards, so the
  /// reading stands apart from the setpoint and lamps around it.
  final bool tempDividers;

  const MonitoringViewSettings({
    this.panelOpacity = 1.0,
    this.valueFontScale = 1.0,
    this.ledDigits = true,
    this.snow = true,
    this.tempDividers = true,
  });

  /// 카드를 얼마나 비칠 수 있게 할지의 한계.
  ///
  /// 0 이다 — 끝까지 밀면 카드가 완전히 비쳐서 배경색 그대로가 된다.
  /// 중간에서 멈추면 카드 색이 배경색과 흰색 사이 어딘가가 되는데, 그건
  /// '비치는 카드'가 아니라 '색이 다른 카드'로 보인다. 카드의 자리는
  /// 테두리가 지킨다(AppPalette.cardShadow).
  ///
  /// 예전에는 0.6 이었다(=투명도 40%). 그때는 제어판 배경 그림 위에서만
  /// 쓰던 값이라 글자가 그림에 묻히지 않게 막아 둔 것이었다.
  static const double minOpacity = 0.0;

  /// Base size of a value in the panel, in logical pixels.
  static const double baseValueFontSize = 14;

  /// Seven-segment face, registered in pubspec. See assets/fonts/DSEG-LICENSE.txt.
  static const String ledFontFamily = 'DSEG7';

  /// Whether a reading should be drawn in the LED face.
  ///
  /// Only numbers: DSEG7 renders letters as seven-segment approximations, which
  /// turns 'NA', 'ON' and the Korean status words into something unreadable.
  /// Those keep the normal font.
  bool usesLedFor(String value) =>
      ledDigits && double.tryParse(value.trim()) != null;

  /// Scale bounds — 14sp up to 28sp.
  static const double minFontScale = 1.0;
  static const double maxFontScale = 2.0;

  static const _kOpacity = 'panel_opacity';
  static const _kFontScale = 'panel_value_font_scale';
  static const _kLedDigits = 'panel_led_digits';
  static const _kSnow = 'app_snowfall';
  static const _kTempDividers = 'card_temp_dividers';

  /// Value text size after the user's scale is applied.
  double get valueFontSize => baseValueFontSize * valueFontScale;

  MonitoringViewSettings copyWith({
    double? panelOpacity,
    double? valueFontScale,
    bool? ledDigits,
    bool? snow,
    bool? tempDividers,
  }) {
    return MonitoringViewSettings(
      panelOpacity: panelOpacity ?? this.panelOpacity,
      valueFontScale: valueFontScale ?? this.valueFontScale,
      ledDigits: ledDigits ?? this.ledDigits,
      snow: snow ?? this.snow,
      tempDividers: tempDividers ?? this.tempDividers,
    );
  }

  static Future<MonitoringViewSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return MonitoringViewSettings(
      // Clamp on read as well as on write: a value stored by an older build
      // could sit outside the range the current one considers readable.
      panelOpacity: (prefs.getDouble(_kOpacity) ?? 1.0).clamp(minOpacity, 1.0),
      valueFontScale:
          (prefs.getDouble(_kFontScale) ?? 1.0).clamp(minFontScale, maxFontScale),
      ledDigits: prefs.getBool(_kLedDigits) ?? true,
      snow: prefs.getBool(_kSnow) ?? true,
      tempDividers: prefs.getBool(_kTempDividers) ?? true,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kOpacity, panelOpacity);
    await prefs.setDouble(_kFontScale, valueFontScale);
    await prefs.setBool(_kLedDigits, ledDigits);
    await prefs.setBool(_kSnow, snow);
    await prefs.setBool(_kTempDividers, tempDividers);
  }
}

/// Holds the current panel settings so the 제어판 redraws the moment they change,
/// without threading them through the router. Same single-ValueNotifier approach
/// as `ThemeController` — the app has no state-management package and these two
/// values do not justify adding one.
class MonitoringViewController {
  MonitoringViewController._();

  static final ValueNotifier<MonitoringViewSettings> settings =
      ValueNotifier(const MonitoringViewSettings());

  static Future<void> load() async {
    settings.value = await MonitoringViewSettings.load();
  }

  static Future<void> set(MonitoringViewSettings next) async {
    settings.value = next;
    await next.save();
  }
}
