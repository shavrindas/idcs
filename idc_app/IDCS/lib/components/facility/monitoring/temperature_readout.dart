// 경로: lib/components/facility/monitoring/temperature_readout.dart
// 명세: 호실 카드의 큰 현재 온도 표시 (전체 현황·시설 안 호실 격자 공용)
import 'package:flutter/material.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
import 'package:idcs/theme/app_theme.dart';

/// The big current-temperature line on a room card.
///
/// Right-aligned so the digits line up across cards like a panel readout. The
/// minus always sits in its own slot like an LED segment: lit when the value is
/// negative, faint otherwise — so -18.5 and 3.2 keep their digits in place.
class TemperatureReadout extends StatelessWidget {
  final double? temp;
  final Color color;
  final bool ledDigits;

  const TemperatureReadout({
    super.key,
    required this.temp,
    required this.color,
    required this.ledDigits,
  });

  @override
  Widget build(BuildContext context) {
    final value = temp;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (value != null)
          // Drawn as a bar rather than a '-' glyph so it looks the same in the
          // regular and the 7-segment font.
          Padding(
            padding: const EdgeInsets.only(right: 2, bottom: 10),
            child: Container(
              width: 10,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1.5),
                color: color.withValues(alpha: value < 0 ? 1 : 0.1),
              ),
            ),
          ),
        Text(
          value == null ? '—' : value.abs().toStringAsFixed(1),
          style: TextStyle(
            fontSize: 25,
            height: 1,
            fontWeight: FontWeight.w700,
            color: color,
            // 제어판과 같은 7세그먼트 서체. 수치일 때만 쓴다 —
            // '—' 를 7세그먼트로 그리면 읽을 수 없다.
            fontFamily: value != null && ledDigits ? MonitoringViewSettings.ledFontFamily : null,
            letterSpacing: value != null && ledDigits ? 1 : null,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (value != null)
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 2),
            child: Text(
              context.l10n.unitCelsius,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.colors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}
