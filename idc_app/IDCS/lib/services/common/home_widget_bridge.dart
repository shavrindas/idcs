// ===============================================================
// 경로: lib/services/common/home_widget_bridge.dart
// 명세: 안드로이드 홈 화면 위젯(전체 현황 카드)에 값을 넘기는 다리
// ===============================================================
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Talks to the native home-screen widget (android/.../widget/).
///
/// The overview screen publishes what it shows — room names, open alarm counts
/// and the latest live values — and the widget draws the same cards from it.
/// While the app is closed, the optional live service (LiveWidgetService) keeps
/// the values moving. Everything here is a no-op off Android.
class HomeWidgetBridge {
  HomeWidgetBridge._();

  static const _channel = MethodChannel('idcs/home_widget');

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Live values arrive every second; the widget does not need more than this.
  static const Duration _minGap = Duration(seconds: 3);
  static DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  static Timer? _trailing;
  static String? _pending;

  /// [rooms]: one map per room — id, facility, name, alarms, fields.
  static void publish(List<Map<String, dynamic>> rooms) {
    if (!supported) return;
    _pending = jsonEncode(rooms);
    final wait = _minGap - DateTime.now().difference(_last);
    if (wait <= Duration.zero) {
      _flush();
    } else {
      // Keep the last call so the widget ends on the newest values.
      _trailing ??= Timer(wait, _flush);
    }
  }

  static void _flush() {
    _trailing = null;
    final json = _pending;
    if (json == null) return;
    _pending = null;
    _last = DateTime.now();
    _channel.invokeMethod('publish', {'rooms': json}).catchError((_) {});
  }

  /// Where the live service connects when the app is closed.
  static Future<void> configure(String wsUrl) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod('configure', {'wsUrl': wsUrl});
    } catch (_) {}
  }

  static Future<bool> isLive() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('isLive') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setLive(bool enabled) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod('setLive', {'enabled': enabled});
    } catch (_) {}
  }
}
