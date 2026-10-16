// ===============================================================
// 경로: lib/components/facility/monitoring/control_row.dart
// 명세: 설비에 쓸 수 있는 다섯 줄을, 각자 생긴 대로 조작하게 한다
// ===============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:idcs/components/facility/monitoring/device_labels.dart';
import 'package:idcs/components/facility/monitoring/field_meaning.dart';
import 'package:idcs/components/facility/monitoring/room_status.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
import 'package:idcs/theme/app_theme.dart';

/// 쓸 수 있는 항목이 실제로 어떤 모양인지.
///
/// 지어낸 것이 아니라 설비 쓰기 주소표(`WriteList.py`)에 적혀 있는 그대로다.
/// 비트 주소(`%MX`)는 켜고 끄는 것이고, 워드 주소(`%DW`)는 수치다.
///
/// | 항목             | 주소            | 뜻   |
/// |------------------|-----------------|------|
/// | control_runsw    | `01%MX4000/1`   | 비트 |
/// | control_efa      | `01%MX4002/1`   | 비트 |
/// | control_tica     | `01%MX4003/1`   | 비트 |
/// | temp_sv          | `01%DW720/0.1`  | 수치 |
/// | temp_hey         | `01%DW721/0.1`  | 수치 |
///
/// 세 개가 켜고 끄는 스위치인데 지금까지는 다섯 줄 모두 빈 입력칸이었다.
/// '운전SW' 옆 칸에 무엇을 적어야 하는지 — `1`인지 `ON`인지 `켜기`인지 —
/// 화면은 알려주지 않았고, 잘못 적으면 어떻게 되는지도 알려주지 않았다.
enum ControlKind { toggle, number }

/// api key -> 어떻게 조작하는 항목인지.
const Map<String, ControlKind> controlKinds = {
  'control_runsw': ControlKind.toggle,
  'control_efa': ControlKind.toggle,
  'control_tica': ControlKind.toggle,
  'temp_sv': ControlKind.number,
  'temp_hey': ControlKind.number,
};

/// 설비로 실제로 나가는 문자열.
///
/// 앱이 보낸 값은 그대로 PLC 명령에 박혀 나간다
/// (`Wr\xFF01%MX4000/1^{값}`). 그래서 여기가 형식을 정하는 유일한 자리다.
///
/// 비트는 `1`/`0`. 주소 뒤 배율이 `/1`이므로 1이 켜짐이다.
///
/// 수치는 사람이 읽는 단위 그대로 — `-21.0`. 주소에 배율 `/0.1`이 함께
/// 실려 나가므로 환산은 게이트웨이가 한다고 보았다. 읽을 때 0.1을 곱하는
/// 쪽은 우리 파이썬 코드(`DataIntercept/main.py`)지 설비가 아니라, 두 경로가
/// 서로 다른 구조다.
///
/// **이 부분만은 실제 설비에서 한 번 확인해야 한다.** 그래서 보내기 전에
/// 확인창이 이 문자열을 그대로 보여 준다 — 틀렸다면 눈에 띄고, 고칠 곳도
/// 여기 한 군데다.
class ControlWire {
  ControlWire._();

  static String forToggle(bool on) => on ? '1' : '0';

  static String forNumber(double value) => value.toStringAsFixed(1);
}

/// 조작 카드의 한 줄.
class ControlRow extends StatelessWidget {
  final String fieldKey;

  /// 지금 설비에서 올라온 값.
  final String value;

  final MonitoringViewSettings view;

  /// 실제로 보냈으면 true 를 돌려준다.
  final bool Function(String fieldKey, String wireValue) onSend;

  const ControlRow({
    super.key,
    required this.fieldKey,
    required this.value,
    required this.view,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final kind = controlKinds[fieldKey] ?? ControlKind.number;
    final label = DeviceLabels.of(context, fieldKey);

    return switch (kind) {
      ControlKind.toggle => _ToggleControl(
          fieldKey: fieldKey,
          label: label,
          value: value,
          onSend: onSend,
        ),
      ControlKind.number => _NumberControl(
          fieldKey: fieldKey,
          label: label,
          value: value,
          view: view,
          onSend: onSend,
        ),
    };
  }
}

/// 보내기 전에 한 번 묻는다.
///
/// 운전SW를 끄면 그 호실의 냉동이 멈춘다. 설정값을 잘못 넣으면 창고 하나
/// 분량이 상한다. 되돌릴 수 없는 일이라 손가락이 스친 것과 하려던 것을
/// 구별해야 한다. 창에는 설비로 나갈 문자열을 그대로 적는다.
Future<bool> _confirm(
  BuildContext context, {
  required String label,
  required String from,
  required String to,
  required String wire,
}) async {
  final colors = context.colors;
  final l10n = context.l10n;

  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.panelControlConfirm, style: const TextStyle(fontSize: 17)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(from, style: TextStyle(fontSize: 18, color: colors.textSecondary)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, size: 18, color: colors.textSecondary),
              ),
              Text(
                to,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${l10n.panelControlWire}: $wire',
            style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.panelControlSend),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class _ToggleControl extends StatelessWidget {
  final String fieldKey;
  final String label;
  final String value;
  final bool Function(String, String) onSend;

  const _ToggleControl({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final meaning = FieldMeaning.forKey(fieldKey);
    final on = RoomStatus.asSwitch(value);

    String word(bool v) =>
        meaning?.word(context, v) ??
        (v ? context.l10n.roomStatusOn : context.l10n.roomStatusOff);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  // 값이 아직 안 올라왔으면 꺼짐으로 그리지 않는다. 꺼져 있다는
                  // 뜻으로 읽힌다.
                  on == null ? context.l10n.roomStateNoData : word(on),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: on == null ? colors.textSecondary : colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: on ?? false,
            // 지금 상태를 모르면 무엇으로 바꾸는지도 말할 수 없다.
            onChanged: on == null
                ? null
                : (next) async {
                    final wire = ControlWire.forToggle(next);
                    final ok = await _confirm(
                      context,
                      label: label,
                      from: word(on),
                      to: word(next),
                      wire: wire,
                    );
                    if (ok) onSend(fieldKey, wire);
                  },
          ),
        ],
      ),
    );
  }
}

class _NumberControl extends StatefulWidget {
  final String fieldKey;
  final String label;
  final String value;
  final MonitoringViewSettings view;
  final bool Function(String, String) onSend;

  const _NumberControl({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.view,
    required this.onSend,
  });

  @override
  State<_NumberControl> createState() => _NumberControlState();
}

class _NumberControlState extends State<_NumberControl> {
  /// 사람이 맞춰 둔 값. 아직 안 건드렸으면 null — 그동안은 설비 값이
  /// 바뀔 때마다 따라 움직인다.
  double? _draft;

  static const double _step = 0.5;

  /// 손가락이 미끄러져 창고 하나를 날리는 일은 없게 한다. 냉동 창고가
  /// 쓰는 범위를 넉넉히 덮으면서, 자릿수를 잘못 넣은 값(210)은 막는다.
  static const double _min = -50;
  static const double _max = 50;

  double? get _current => double.tryParse(widget.value.trim());

  double? get _shown => _draft ?? _current;

  void _nudge(double delta) {
    final base = _shown;
    if (base == null) return;
    setState(() => _draft = (base + delta).clamp(_min, _max));
  }

  Future<void> _send() async {
    final target = _draft;
    final from = _current;
    if (target == null) return;

    final wire = ControlWire.forNumber(target);
    final ok = await _confirm(
      context,
      label: widget.label,
      from: from == null ? '—' : from.toStringAsFixed(1),
      to: target.toStringAsFixed(1),
      wire: wire,
    );
    if (!ok) return;
    if (widget.onSend(widget.fieldKey, wire)) {
      // 보냈으면 다시 설비 값을 따라가게 둔다. 설비가 반영하면 그 값이 올라온다.
      setState(() => _draft = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shown = _shown;
    final changed = _draft != null && _draft != _current;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
          const SizedBox(height: 4),
          Row(
            children: [
              _StepButton(icon: Icons.remove_rounded, onTap: shown == null ? null : () => _nudge(-_step)),
              Expanded(
                child: Center(
                  child: Text(
                    shown == null ? '—' : shown.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 24,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      // 아직 안 보낸 값은 색으로 구분한다. 지금 설비에 들어
                      // 있는 값과 내가 맞춰 둔 값은 다른 것이다.
                      color: changed ? colors.primary : colors.textPrimary,
                      fontFamily: shown != null && widget.view.ledDigits
                          ? MonitoringViewSettings.ledFontFamily
                          : null,
                      letterSpacing: shown != null && widget.view.ledDigits ? 1 : null,
                    ),
                  ),
                ),
              ),
              _StepButton(icon: Icons.add_rounded, onTap: shown == null ? null : () => _nudge(_step)),
              const SizedBox(width: 8),
              // 바꾸기 전에는 보낼 것이 없다.
              FilledButton(
                onPressed: changed ? _send : null,
                child: Text(context.l10n.panelControlSend),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: onTap == null ? colors.textSecondary.withValues(alpha: 0.4) : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
