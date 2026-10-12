// ===============================================================
// 경로: lib/components/facility/monitoring/panel_summary_card.dart
// 명세: 제어판 맨 위 요약 — 지금 고내온도가 몇 도이고, 그 값이 언제 것인지
// ===============================================================
import 'package:flutter/material.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
import 'package:idcs/theme/app_theme.dart';

/// 제어판을 열었을 때 가장 먼저 보이는 카드.
///
/// 이 앱을 여는 이유는 대부분 "지금 몇 도인가" 하나다. 예전에는 그 값이 두 번째
/// 카드의 두 번째 줄, 화면 아래쪽에 있었고 맨 위는 시설 ID·호실 ID·관리자 ID 가
/// 차지하고 있었다 — 모두 DB 키라서 현장에서는 쓸 일이 없는 숫자다.
///
/// 값만 큼직하게 두지 않고 설정값과 마지막 수신 시각을 같이 보여준다. 숫자
/// 하나만으로는 그게 정상인지 알 수 없고, 통신이 끊기면 멈춘 값이 그대로
/// 남아 있어 멀쩡해 보이기 때문이다.
class PanelSummaryCard extends StatelessWidget {
  /// 측정값(temp_pv). 아직 수신 전이면 'NA'.
  final String currentTemp;

  /// 설정값(temp_sv).
  final String setpoint;

  /// 마지막으로 값이 들어온 시각. 한 번도 못 받았으면 null.
  final DateTime? lastUpdate;

  final MonitoringViewSettings view;

  const PanelSummaryCard({
    super.key,
    required this.currentTemp,
    required this.setpoint,
    required this.lastUpdate,
    required this.view,
  });

  /// 'NA' 나 빈 값은 숫자가 아니므로 그대로 두고, 숫자면 단위를 붙인다.
  static double? _asNumber(String raw) => double.tryParse(raw.trim());

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = _asNumber(currentTemp);
    final sv = _asNumber(setpoint);

    final stale = _staleMinutes();
    final hasSignal = lastUpdate != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.panelCurrentTemp,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value == null ? '—' : currentTemp.trim(),
                style: TextStyle(
                  fontSize: 44,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  // 값이 수치일 때만 LED 서체를 쓴다. 'NA' 를 7세그먼트로 그리면
                  // 읽을 수 없다.
                  fontFamily: value != null && view.ledDigits
                      ? MonitoringViewSettings.ledFontFamily
                      : null,
                  letterSpacing: value != null && view.ledDigits ? 2 : null,
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    context.l10n.unitCelsius,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                ),
              ],
              const Spacer(),
              if (sv != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      context.l10n.panelSetpoint,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${setpoint.trim()} ${context.l10n.unitCelsius}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: !hasSignal
                      ? colors.textSecondary
                      : stale > 0
                          ? colors.warning
                          : colors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                _freshnessLabel(context, stale),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: stale > 0 ? FontWeight.w700 : FontWeight.w500,
                  color: stale > 0 ? colors.warning : colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 신호가 끊긴 것으로 볼 분 수. 아직 괜찮으면 0.
  int _staleMinutes() {
    if (lastUpdate == null) return 0;
    final minutes = DateTime.now().difference(lastUpdate!).inMinutes;
    return minutes >= 2 ? minutes : 0;
  }

  String _freshnessLabel(BuildContext context, int stale) {
    final l10n = context.l10n;
    if (lastUpdate == null) return l10n.panelWaitingData;
    if (stale > 0) return l10n.panelNoSignal(stale);

    final seconds = DateTime.now().difference(lastUpdate!).inSeconds;
    if (seconds < 5) return l10n.panelUpdatedJustNow;
    if (seconds < 60) return l10n.panelUpdatedSecondsAgo(seconds);
    return l10n.panelUpdatedMinutesAgo(seconds ~/ 60);
  }
}
