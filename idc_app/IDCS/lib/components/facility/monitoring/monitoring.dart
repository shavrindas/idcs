import 'package:flutter/material.dart';
import 'package:idcs/components/facility/monitoring/device_labels.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/l10n/l10n_context.dart';

class MonitoringCard extends StatelessWidget {
  final String title;
  final Map<String, String> fields; // 평평한 1층짜리 딕셔너리 (속성명: 속성값)

  /// 확인 버튼을 눌렀을 때 입력값을 전달받을 콜백.
  /// 실제로 보냈으면 true 를 돌려준다 — 그때만 입력칸을 비운다.
  final bool Function(String label, String inputValue)? OnConfirm;

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
    this.OnConfirm,
  });

  @override
  Widget build(BuildContext context) {
    // 제어 가능한(OnConfirm이 있는) 카드는 정적 정보 카드보다 시각적으로 한 단계 부각시킨다.
    final bool isControl = OnConfirm != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        // Letting the backdrop show through is the whole point of the opacity
        // setting; at 1.0 this is the solid card the panel has always had.
        color: context.colors.surface.withValues(alpha: view.panelOpacity),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isControl ? context.colors.primary.withValues(alpha: 0.18) : context.colors.outline),
        boxShadow: isControl ? context.colors.softShadow : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textSecondary, letterSpacing: 0.3),
              ),
              if (isControl) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(context.l10n.panelControlBadge, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.primary)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // 독립된 StatefulWidget으로 개별 Row 생성
          ...fields.entries.map((entry) => _EditableRowItem(
            key: ValueKey(entry.key), // label을 키값으로 설정하여 위젯 재사용성 보장
            label: deviceKeys ? DeviceLabels.of(context, entry.key) : entry.key,
            fieldKey: entry.key,
            value: entry.value,
            view: view,
            // Only live readings get the LED face. 시설 기본 정보 is the one card
            // without 제어, and its numbers are identifiers (시설/호실/관리자 ID),
            // not measurements — a seven-segment display would imply a gauge.
            ledAllowed: isControl,
            onConfirm: OnConfirm,
          )),
        ],
      ),
    );
  }
}

// 입력 상태를 유지하기 위해 개별 Row를 StatefulWidget으로 분리
class _EditableRowItem extends StatefulWidget {
  final String label;

  /// What the control write addresses — the server's field name.
  final String fieldKey;
  final String value;
  final MonitoringViewSettings view;

  /// False on the static info card, where numbers are identifiers.
  final bool ledAllowed;
  final bool Function(String label, String inputValue)? onConfirm;

  const _EditableRowItem({
    super.key,
    required this.label,
    required this.fieldKey,
    required this.value,
    required this.view,
    required this.ledAllowed,
    this.onConfirm,
  });

  @override
  State<_EditableRowItem> createState() => _EditableRowItemState();
}

class _EditableRowItemState extends State<_EditableRowItem> {
  // State 내부에서 컨트롤러를 선언하여 부모가 re-build되어도 입력값이 유지됨
  late final TextEditingController _inputController;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위한 자원 해제
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final useLed = widget.ledAllowed && widget.view.usesLedFor(widget.value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. 기존 읽기 전용 필드 (실시간 웹소켓 값 표시)
          Expanded(
            flex: 4,
            child: TextFormField(
              key: ValueKey(widget.value), // 실시간 값이 변할 때 텍스트 업데이트
              initialValue: widget.value,
              readOnly: true,
              style: TextStyle(
                // Only the reading scales; the label stays put so the row keeps
                // its shape as the numbers grow.
                fontSize: widget.view.valueFontSize,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
                fontFamily: useLed ? MonitoringViewSettings.ledFontFamily : null,
                // DSEG7 is a fixed seven-segment grid, so a little tracking
                // keeps the digits from reading as one block.
                letterSpacing: useLed ? 1 : null,
              ),
              decoration: InputDecoration(
                labelText: widget.label,
                labelStyle: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                fillColor: context.colors.background,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 2. 작성 가능한 텍스트 필드 (입력 중인 값 유지)
          if (widget.onConfirm != null) ...[
            Expanded(
              flex: 4,
              child: TextField(
                controller: _inputController,
                style: const TextStyle(fontSize: 14),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (widget.onConfirm == null) return;
                  if (widget.onConfirm!(widget.fieldKey, _inputController.text)) {
                    _inputController.clear();
                  }
                },
                decoration: InputDecoration(
                  hintText: context.l10n.panelInputHint,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 3. 확인 버튼
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  // 보내지 못했을 때(값이 비었거나 연결이 끊겼을 때)는 입력을
                  // 그대로 둬야 한다. 지워 버리면 다시 처음부터 쳐야 한다.
                  final sent = widget.onConfirm!(widget.fieldKey, _inputController.text);
                  if (sent) _inputController.clear();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(64, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                ),
                child: Text(context.l10n.panelConfirm, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
