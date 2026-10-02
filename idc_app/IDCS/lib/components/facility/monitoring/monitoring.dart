import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';

class MonitoringCard extends StatelessWidget {
  final String title;
  final Map<String, String> fields; // 평평한 1층짜리 딕셔너리 (속성명: 속성값)

  // 확인 버튼을 눌렀을 때 입력값을 전달받을 콜백
  final Function(String label, String inputValue)? OnConfirm;

  const MonitoringCard({
    super.key,
    required this.title,
    required this.fields,
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
        color: context.colors.surface,
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
                  child: Text('제어', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.primary)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // 독립된 StatefulWidget으로 개별 Row 생성
          ...fields.entries.map((entry) => _EditableRowItem(
            key: ValueKey(entry.key), // label을 키값으로 설정하여 위젯 재사용성 보장
            label: entry.key,
            value: entry.value,
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
  final String value;
  final Function(String label, String inputValue)? onConfirm;

  const _EditableRowItem({
    super.key,
    required this.label,
    required this.value,
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
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
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
                decoration: const InputDecoration(
                  hintText: '입력',
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
                  final inputText = _inputController.text;
                  widget.onConfirm!(widget.label, inputText);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(64, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                ),
                child: const Text('확인', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
