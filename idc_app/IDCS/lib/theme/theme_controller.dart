// 경로: lib/theme/theme_controller.dart
// 명세: 연한/어두운 테마 선택값 보관 및 기기 저장
import 'package:flutter/material.dart';
import 'package:idcs/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 테마 선택값. 기본은 기기 설정을 따라가고, 사용자가 직접 고르면 그 값을 기억한다.
///
/// 상태관리 패키지를 새로 들이지 않고 ValueNotifier 하나로 처리한다.
/// 앱 전체에서 바뀌는 값이 이것 하나뿐이라 그 이상은 과하다.
class ThemeController {
  ThemeController._();

  static const _key = 'theme_mode';

  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    mode.value = _fromName(prefs.getString(_key));
  }

  static Future<void> set(ThemeMode next) async {
    mode.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, next.name);
  }

  static ThemeMode _fromName(String? name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String labelOf(ThemeMode m, AppLocalizations l10n) {
    switch (m) {
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
      case ThemeMode.system:
        return l10n.themeSystem;
    }
  }
}
