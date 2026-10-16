// ===============================================================
// 경로: lib/components/facility/monitoring/panel_status_card.dart
// 명세: 제어판 두 번째 카드 — "지금 괜찮은가"와 "지금 뭐가 돌고 있나"
// ===============================================================
import 'package:flutter/material.dart';
import 'package:idcs/components/facility/monitoring/device_labels.dart';
import 'package:idcs/components/facility/monitoring/field_meaning.dart';
import 'package:idcs/components/facility/monitoring/room_status.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
import 'package:idcs/theme/app_theme.dart';

/// 제어판을 열었을 때 온도 다음으로 알고 싶은 두 가지.
///
/// 예전에는 '이상 정보' 카드에 열두 줄이 그냥 늘어서 있었다. 평소에는 열두
/// 줄 전부가 OFF 라서 읽을 것이 없고, 정작 하나가 켜지면 OFF 열한 개 사이에
/// 섞여서 눈에 띄지 않는다. 그래서 답을 한 줄로 먼저 말한다 — 이상이 없으면
/// "이상 없음" 한 줄이고, 있으면 무엇이 켜졌는지 이름을 댄다.
///
/// 그 아래는 지금 돌고 있는 것들이다. 이쪽은 좋고 나쁨이 아니라 상태다 —
/// 제상은 돌아도 정상이고 멈춰도 정상이라, 색을 입히지 않고 말로만 적는다.
class PanelStatusCard extends StatefulWidget {
  /// 이 호실의 모든 실시간 값을 합친 것 (필드 이름 -> 값).
  final Map<String, String> values;

  final MonitoringViewSettings view;

  const PanelStatusCard({super.key, required this.values, required this.view});

  @override
  State<PanelStatusCard> createState() => _PanelStatusCardState();
}

class _PanelStatusCardState extends State<PanelStatusCard> {
  bool _expanded = false;

  /// 지금 켜져 있는 이상 항목.
  List<String> get _activeFaults => widget.values.entries
      .where((e) =>
          FieldMeaning.isFaultFlag(e.key) &&
          (RoomStatus.asSwitch(e.value) ?? false))
      .map((e) => e.key)
      .toList();

  /// 값이 올라온 이상 항목 전부. 펼쳤을 때 보여 준다.
  List<String> get _allFaultKeys => widget.values.keys
      .where((k) => FieldMeaning.isFaultFlag(k) && RoomStatus.asSwitch(widget.values[k]) != null)
      .toList()
    ..sort();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    final faults = _activeFaults;
    final clear = faults.isEmpty;
    final accent = clear ? colors.success : colors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: widget.view.panelOpacity),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: clear ? colors.outline : accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.panelNowTitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          _verdict(context, faults, accent, clear),
          if (_expanded) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: colors.outline),
            const SizedBox(height: 8),
            ..._allFaultKeys.map((k) => _FaultRow(
                  label: DeviceLabels.of(context, k),
                  on: RoomStatus.asSwitch(widget.values[k]) ?? false,
                  meaning: FieldMeaning.forKey(k),
                )),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.outline),
          const SizedBox(height: 12),
          _runningStates(context),
        ],
      ),
    );
  }

  Widget _verdict(BuildContext context, List<String> faults, Color accent, bool clear) {
    final colors = context.colors;
    final l10n = context.l10n;

    // 이상 항목이 하나도 안 올라오면 펼칠 것도 없다.
    final canExpand = _allFaultKeys.isNotEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: canExpand ? () => setState(() => _expanded = !_expanded) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                clear ? Icons.verified_rounded : Icons.warning_amber_rounded,
                size: 22,
                color: accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clear ? l10n.panelNoFaults : l10n.panelFaultCount(faults.length),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: clear ? colors.textPrimary : accent,
                      ),
                    ),
                    if (!clear) ...[
                      const SizedBox(height: 2),
                      Text(
                        faults.map((k) => DeviceLabels.of(context, k)).join(', '),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              if (canExpand)
                Icon(
                  _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 20,
                  color: colors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 지금 돌고 있는 것들. 값이 올라온 것만 내건다.
  Widget _runningStates(BuildContext context) {
    const keys = ['control_runsw', 'temp_comp', 'deforest_def'];

    final rows = <Widget>[];
    for (final key in keys) {
      final on = RoomStatus.asSwitch(widget.values[key]);
      if (on == null) continue;
      rows.add(_StateRow(
        label: DeviceLabels.of(context, key),
        on: on,
        meaning: FieldMeaning.forKey(key),
      ));
    }

    if (rows.isEmpty) {
      return Text(
        context.l10n.panelWaitingData,
        style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
      );
    }
    return Column(children: rows);
  }
}

/// 돌고 있는지 아닌지 한 줄. 좋고 나쁨이 아니므로 색을 쓰지 않는다 —
/// 색은 이상에만 쓴다. 아무 데나 칠하면 빨간 줄이 묻힌다.
class _StateRow extends StatelessWidget {
  final String label;
  final bool on;
  final FieldMeaning? meaning;

  const _StateRow({required this.label, required this.on, required this.meaning});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final word = meaning?.word(context, on) ??
        (on ? context.l10n.roomStatusOn : context.l10n.roomStatusOff);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? colors.primary : Colors.transparent,
              border: on ? null : Border.all(color: colors.textSecondary.withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ),
          Text(
            word,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: on ? colors.textPrimary : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 펼쳤을 때 보이는 이상 항목 한 줄.
class _FaultRow extends StatelessWidget {
  final String label;
  final bool on;
  final FieldMeaning? meaning;

  const _FaultRow({required this.label, required this.on, required this.meaning});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final word = meaning?.word(context, on) ??
        (on ? context.l10n.roomStatusOn : context.l10n.roomStatusOff);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            on ? Icons.error_rounded : Icons.check_circle_outline_rounded,
            size: 15,
            color: on ? colors.error : colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12.5, color: colors.textSecondary)),
          ),
          Text(
            word,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: on ? colors.error : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
