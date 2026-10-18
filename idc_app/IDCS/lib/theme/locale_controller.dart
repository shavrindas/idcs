// 경로: lib/theme/locale_controller.dart
// 명세: 앱 표시 언어 선택값 보관 및 기기 저장
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 표시 언어. 기본은 기기 설정을 따르고, 사용자가 고르면 그 값을 기억한다.
///
/// `ThemeController`와 같은 모양으로 둔다 — 앱 전체에서 바뀌는 값이 테마·언어
/// 둘뿐이라 상태관리 패키지를 새로 들일 이유가 없다.
class LocaleController {
  LocaleController._();

  static const _key = 'app_locale';

  /// 지원 언어. MaterialApp의 supportedLocales와 같은 순서를 유지한다.
  static const List<Locale> supported = [Locale('ko'), Locale('en')];

  /// null이면 기기 설정을 따른다.
  static final ValueNotifier<Locale?> locale = ValueNotifier(null);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    locale.value = _fromCode(prefs.getString(_key));
  }

  static Future<void> set(Locale? next) async {
    locale.value = next;
    final prefs = await SharedPreferences.getInstance();
    if (next == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, next.languageCode);
    }
  }

  static Locale? _fromCode(String? code) {
    if (code == null) return null;
    for (final l in supported) {
      if (l.languageCode == code) return l;
    }
    return null;
  }
}
