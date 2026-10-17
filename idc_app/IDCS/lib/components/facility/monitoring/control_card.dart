// ===============================================================
// 경로: lib/components/facility/monitoring/control_card.dart
// 명세: 제어판에서 유일하게 설비에 닿는 카드
// ===============================================================
import 'package:flutter/material.dart';
import 'package:idcs/components/facility/monitoring/control_row.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/theme/motion.dart';

/// 사람이 실제로 할 수 있는 일만 모은 카드.
///
/// 쉰두 줄 가운데 설비에 닿는 것은 다섯 줄뿐인데, 그 다섯이 여섯 카드에
/// 흩어져 있었다. 게다가 다섯 줄 모두 빈 입력칸이라 '운전SW' 옆에 무엇을
/// 적어야 하는지 화면이 알려주지 않았다 — 실제로는 셋이 켜고 끄는 스위치고
/// 둘이 온도다.
///
/// 그래서 항목마다 생긴 대로 조작하게 한다. 상세 카드들은 읽기 전용으로
/// 두었다. 같은 값을 두 군데서 서로 다른 방식으로 바꾸게 하면, 어느 쪽이
/// 맞는지 알 수 없다.
class ControlCard extends StatefulWidget {
  /// 쓸 수 있는 항목만 (필드 이름 -> 지금 값).
  final Map<String, String> fields;

  final MonitoringViewSettings view;

  /// 실제로 보냈으면 true 를 돌려준다.
  final bool Function(String fieldKey, String wireValue) onSend;

  const ControlCard({
    super.key,
    required this.fields,
    required this.view,
    required this.onSend,
  });

  @override
  State<ControlCard> createState() => _ControlCardState();
}

class _ControlCardState extends State<ControlCard> {
  /// 처음에는 닫혀 있다.
  ///
  /// 펼쳐 둔 채로 두면 호실을 열자마자 ± 와 스위치가 손가락 밑에 들어온다.
  /// 스쳐서 눌린 것과 하려던 것을 구별할 수 없고, 운전SW 하나가 그 호실의
  /// 냉동을 멈춘다. 한 번 눌러서 여는 것은 귀찮은 일이 아니라, 지금부터
  /// 설비를 건드린다는 뜻이다.
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fields = widget.fields;
    final view = widget.view;
    final onSend = widget.onSend;

    if (fields.isEmpty) return const SizedBox.shrink();

    // 켜고 끄는 것과 수치를 섞어 두면 줄마다 생김새가 달라 읽기 어렵다.
    final toggles = fields.keys
        .where((k) => controlKinds[k] == ControlKind.toggle)
        .toList();
    final numbers = fields.keys
        .where((k) => controlKinds[k] != ControlKind.toggle)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: view.panelOpacity),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
        boxShadow: colors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _open ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      context.l10n.panelControlTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: Motion.of(context, Motion.normal),
            curve: Motion.enter,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 6),
                      for (final key in numbers)
                        ControlRow(fieldKey: key, value: fields[key] ?? '', view: view, onSend: onSend),
                      if (numbers.isNotEmpty && toggles.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Divider(height: 1, color: colors.outline),
                        const SizedBox(height: 2),
                      ],
                      for (final key in toggles)
                        ControlRow(fieldKey: key, value: fields[key] ?? '', view: view, onSend: onSend),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
