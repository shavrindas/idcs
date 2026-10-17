// ===============================================================
// 경로: lib/components/facility/chart/chart_limits_dialog.dart
// 명세: 차트 기준선의 상·하한을 직접 적는 창
// ===============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/services/chart/chart_limits.dart';
import 'package:idcs/theme/app_theme.dart';

/// 지금 그려져 있는 항목마다 상·하한을 적는 창.
///
/// 자주 쓸 자리가 아니다 — 보통은 웹 콘솔에서 포인트 롤에 넣고, 여기는 그게
/// 아직 비어 있는 동안의 임시 자리다. 그래서 차트 화면에는 작은 글자 버튼
/// 하나로만 내보내고, 실제 입력은 이 창에서 받는다.
///
/// 저장하면 [ChartLimits] 에 남고, 차트를 다시 그릴 때 서버 값이 없는
/// 항목에만 끼워 넣는다.
class ChartLimitsDialog extends StatefulWidget {
  final String roomId;

  /// 지금 차트에 그려진 시리즈. role_name 과 보여줄 이름만 쓴다.
  final List<({String roleName, String label})> series;

  final Map<String, RoleLimit> current;

  const ChartLimitsDialog({
    super.key,
    required this.roomId,
    required this.series,
    required this.current,
  });

  @override
  State<ChartLimitsDialog> createState() => _ChartLimitsDialogState();
}

class _ChartLimitsDialogState extends State<ChartLimitsDialog> {
  late final Map<String, TextEditingController> _low;
  late final Map<String, TextEditingController> _high;

  @override
  void initState() {
    super.initState();
    String text(double? v) => v?.toString() ?? '';
    _low = {
      for (final s in widget.series)
        s.roleName: TextEditingController(text: text(widget.current[s.roleName]?.low)),
    };
    _high = {
      for (final s in widget.series)
        s.roleName: TextEditingController(text: text(widget.current[s.roleName]?.high)),
    };
  }

  @override
  void dispose() {
    for (final c in [..._low.values, ..._high.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final next = <String, RoleLimit>{
      for (final s in widget.series)
        s.roleName: RoleLimit(
          low: double.tryParse(_low[s.roleName]!.text.trim()),
          high: double.tryParse(_high[s.roleName]!.text.trim()),
        ),
    };
    await ChartLimits.saveAll(widget.roomId, next);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.chartLimitsTitle, style: const TextStyle(fontSize: 17)),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.series.isEmpty
            ? Text(
                l10n.chartLimitsEmpty,
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이 값이 어디까지 닿는지 먼저 밝힌다. 적어 두고 알람까지
                  // 울릴 거라고 믿게 두면 안 된다.
                  Text(
                    l10n.chartLimitsLocal,
                    style: TextStyle(fontSize: 11.5, color: colors.textSecondary, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final s in widget.series) ...[
                            _Row(label: s.label, low: _low[s.roleName]!, high: _high[s.roleName]!),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.actionCancel),
        ),
        if (widget.series.isNotEmpty)
          FilledButton(onPressed: _save, child: Text(l10n.panelControlSend)),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final TextEditingController low;
  final TextEditingController high;

  const _Row({required this.label, required this.low, required this.high});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    InputDecoration deco(String text) => InputDecoration(
          labelText: text,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textPrimary),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: low,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
                style: const TextStyle(fontSize: 14),
                decoration: deco(context.l10n.chartLimitsLow),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: high,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
                style: const TextStyle(fontSize: 14),
                decoration: deco(context.l10n.chartLimitsHigh),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
