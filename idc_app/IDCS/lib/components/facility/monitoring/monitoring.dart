import 'package:flutter/material.dart';
import 'package:idcs/components/facility/monitoring/device_labels.dart';
import 'package:idcs/components/facility/monitoring/field_meaning.dart';
import 'package:idcs/components/facility/monitoring/room_status.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/theme/motion.dart';
import 'package:idcs/l10n/l10n_context.dart';

/// 한 묶음의 값을 보여 주는 카드.
///
/// [collapsible] 이면 제목 줄만 남기고 접힌다. 제어판에는 쉰 줄이 넘게 있는데,
/// 호실을 열 때마다 그걸 다 지나쳐 내려가야 했다. 평소에 보는 것은 그중
/// 몇 줄뿐이라, 나머지는 찾을 때만 펼치게 둔다 — 없애지는 않는다. 설비를
/// 보는 사람에게는 언젠가 전부 필요하다.
class MonitoringCard extends StatefulWidget {
  final String title;
  final Map<String, String> fields; // 평평한 1층짜리 딕셔너리 (속성명: 속성값)

  /// 접을 수 있는 카드인지. 접히면 처음에는 닫혀 있다.
  final bool collapsible;

  /// 제어판 겉모습 설정. 배경을 비치게 하는 투명도와 값 글자 크기를 여기서 받는다.
  final MonitoringViewSettings view;

  /// fields 의 키가 서버 필드 이름이면 true — 표시 이름을 DeviceLabels 에서 찾는다.
  /// 시설 기본 정보 카드처럼 이미 사람이 읽을 라벨이면 false.
  final bool deviceKeys;

  const MonitoringCard({
    super.key,
    required this.title,
    required this.fields,
    required this.view,
    this.deviceKeys = false,
    this.collapsible = false,
  });

  @override
  State<MonitoringCard> createState() => _MonitoringCardState();
}

class _MonitoringCardState extends State<MonitoringCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final fields = widget.fields;
    final view = widget.view;
    final deviceKeys = widget.deviceKeys;
    final expanded = !widget.collapsible || _open;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        // Letting the backdrop show through is the whole point of the opacity
        // setting; at 1.0 this is the solid card the panel has always had.
        color: context.colors.surface.withValues(alpha: view.panelOpacity),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 접히는 카드는 제목 줄 전체가 손잡이다. 화살표만 누르게 두면
          // 작아서 잘 안 맞는다.
          _MaybeTappable(
            enabled: widget.collapsible,
            onTap: () => setState(() => _open = !_open),
            child: Row(
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textSecondary, letterSpacing: 0.3),
              ),
              if (widget.collapsible) ...[
                const SizedBox(width: 6),
                Text(
                  '${fields.length}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.textSecondary.withValues(alpha: 0.7)),
                ),
              ],
              // 배지를 달던 자리다. 쓸 수 있는 다섯 줄을 맨 위 '조작' 카드에
              // 따로 모은 뒤로는, 배지가 답하던 질문("어디서 바꿀 수 있나")에
              // 그 카드가 먼저 답한다. 남겨 두면 '제어 정보 · 제어' 처럼
              // 같은 말이 두 번 된다. 테두리로만 구분한다.
              if (widget.collapsible) ...[
                const Spacer(),
                Icon(
                  expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 20,
                  color: context.colors.textSecondary,
                ),
              ],
            ],
            ),
          ),
          // 톡 나타나고 톡 사라지면 접힌 것이 펼쳐졌다기보다 다른 화면으로
          // 바뀐 것처럼 보인다. 높이가 자라는 동안 눈이 따라갈 수 있다.
          AnimatedSize(
            duration: Motion.of(context, Motion.normal),
            curve: Motion.enter,
            alignment: Alignment.topCenter,
            child: !expanded
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      ...fields.entries.map((entry) => _EditableRowItem(
            key: ValueKey(entry.key), // label을 키값으로 설정하여 위젯 재사용성 보장
            label: deviceKeys ? DeviceLabels.of(context, entry.key) : entry.key,
            fieldKey: entry.key,
            value: entry.value,
            view: view,
            // Only live readings get the LED face. A card whose keys are
            // already human labels (deviceKeys: false) holds identifiers,
            // not measurements — a seven-segment display would imply a gauge.
            ledAllowed: deviceKeys,
                      )),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// 접히는 카드일 때만 눌리게 한다. 안 접히는 카드에 잉크 번짐이 생기면
/// 눌러도 되는 줄로 읽힌다.
class _MaybeTappable extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  const _MaybeTappable({required this.enabled, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: child),
      ),
    );
  }
}

/// A single read-only reading row in a detail card.
class _EditableRowItem extends StatelessWidget {
  final String label;
  final String fieldKey;
  final String value;
  final MonitoringViewSettings view;

  /// False on the static info card, where numbers are identifiers.
  final bool ledAllowed;

  const _EditableRowItem({
    super.key,
    required this.label,
    required this.fieldKey,
    required this.value,
    required this.view,
    required this.ledAllowed,
  });

  @override
  Widget build(BuildContext context) {
    final useLed = ledAllowed && view.usesLedFor(value);

    // 뜻을 아는 참/거짓 항목은 ON/OFF 대신 그 뜻을 적는다. '제상용 전자변: ON'
    // 은 이름과 값을 알려주지만, 냉동 설비를 모르는 사람에게는 지금 좋은
    // 상황인지 나쁜 상황인지까지는 말해 주지 않는다. '제상 중' 은 말해 준다.
    final meaning = FieldMeaning.forKey(fieldKey);
    final isOn = meaning == null ? null : RoomStatus.asSwitch(value);
    final shown = isOn == null ? value : meaning!.word(context, isOn);
    final tone = isOn == null ? Tone.neutral : meaning!.toneFor(isOn);
    final toneColor = switch (tone) {
      Tone.bad => context.colors.error,
      // 정상이라고 초록을 칠하지는 않는다. 쉰 줄이 전부 초록이면 정작 빨간
      // 줄이 묻힌다 — 나쁜 소식에만 색을 쓴다.
      Tone.good || Tone.neutral => context.colors.textPrimary,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        key: ValueKey(shown), // 실시간 값이 변할 때 텍스트 업데이트
        initialValue: shown,
        readOnly: true,
        style: TextStyle(
          // Only the reading scales; the label stays put so the row keeps
          // its shape as the numbers grow. 뜻을 적은 '말'은 예외다 —
          // 숫자 크기 설정은 제어판 숫자용이고, 말까지 키우면 '운전 중'
          // 같은 긴 낱말이 칸을 넘어 잘린다.
          fontSize: isOn == null ? view.valueFontSize : 15,
          fontWeight: isOn == null ? FontWeight.w600 : FontWeight.w700,
          color: toneColor,
          fontFamily: useLed ? MonitoringViewSettings.ledFontFamily : null,
          // DSEG7 is a fixed seven-segment grid, so a little tracking
          // keeps the digits from reading as one block.
          letterSpacing: useLed ? 1 : null,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 12, color: context.colors.textSecondary),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          fillColor: context.colors.background,
        ),
      ),
    );
  }
}
