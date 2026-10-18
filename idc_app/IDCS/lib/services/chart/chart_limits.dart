// ===============================================================
// 경로: lib/services/chart/chart_limits.dart
// 명세: 차트 기준선의 상·하한을 이 기기에 직접 적어 두는 자리
// ===============================================================
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 한 항목의 상·하한.
@immutable
class RoleLimit {
  final double? low;
  final double? high;

  const RoleLimit({this.low, this.high});

  bool get isEmpty => low == null && high == null;
}

/// 차트에 기준선을 그리려면 상·하한이 있어야 하는데, 지금 등록된 포인트 롤에는
/// 그 칸이 비어 있다. 서버가 채워 주기 전까지 '안전 범위 선'은 켤 수조차 없다.
///
/// 그래서 직접 적어 둘 수 있게 한다. 다만 이건 어디까지나 임시 자리다 —
/// 이 기기에만 저장되고, 다른 사람 화면에는 안 보이고, 알람도 이 값으로는
/// 울리지 않는다. 알람까지 닿으려면 웹 콘솔에서 포인트 롤에 넣어야 한다.
/// 그 사실을 화면에도 적어 두었다.
class ChartLimits {
  ChartLimits._();

  static String _key(String roomId) => 'chart_limits_$roomId';

  /// 호실 하나의 저장된 기준값 전부. 키는 서버가 주는 role_name.
  static Future<Map<String, RoleLimit>> load(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(roomId));
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final e in decoded.entries)
          if (e.value is Map)
            e.key.toString(): RoleLimit(
              low: (e.value['low'] as num?)?.toDouble(),
              high: (e.value['high'] as num?)?.toDouble(),
            ),
      };
    } catch (_) {
      // 저장해 둔 것이 깨져 있어도 차트는 열려야 한다.
      return {};
    }
  }

  static Future<void> saveAll(String roomId, Map<String, RoleLimit> limits) async {
    final prefs = await SharedPreferences.getInstance();

    // 둘 다 비어 있는 항목은 아예 지운다 — 빈 칸을 남겨 두면 다음에 열었을 때
    // '뭔가 설정돼 있다'고 읽힌다.
    final kept = {
      for (final e in limits.entries)
        if (!e.value.isEmpty)
          e.key: {
            if (e.value.low != null) 'low': e.value.low,
            if (e.value.high != null) 'high': e.value.high,
          },
    };

    if (kept.isEmpty) {
      await prefs.remove(_key(roomId));
      return;
    }
    await prefs.setString(_key(roomId), jsonEncode(kept));
  }

  /// 서버가 내려준 차트 데이터에 저장해 둔 기준값을 끼워 넣는다.
  ///
  /// 서버가 준 값이 있으면 그쪽이 먼저다 — 직접 적어 둔 것은 어디까지나
  /// 빈자리를 메우는 용도다. 여기서 끼워 넣으면 차트를 그리는 쪽은 그 값이
  /// 어디서 왔는지 몰라도 된다.
  static void apply(Map<String, dynamic>? chartData, Map<String, RoleLimit> limits) {
    if (chartData == null || limits.isEmpty) return;

    final datasets = chartData['data']?['datasets'];
    if (datasets is! List) return;

    for (final ds in datasets) {
      if (ds is! Map) continue;
      final limit = limits[ds['role_name']?.toString()];
      if (limit == null) continue;

      if (ds['target_low_limit'] == null && limit.low != null) {
        ds['target_low_limit'] = limit.low.toString();
      }
      if (ds['target_high_limit'] == null && limit.high != null) {
        ds['target_high_limit'] = limit.high.toString();
      }
    }
  }
}
