import 'package:flutter/material.dart';

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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 12),
            // 💡 독립된 StatefulWidget으로 개별 Row 생성
            ...fields.entries.map((entry) => _EditableRowItem(
              key: ValueKey(entry.key), // label을 키값으로 설정하여 위젯 재사용성 보장
              label: entry.key,
              value: entry.value,
              onConfirm: OnConfirm,
            )),
          ],
        ),
      ),
    );
  }
}

// 💡 입력 상태를 유지하기 위해 개별 Row를 StatefulWidget으로 분리
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
  // 💡 State 내부에서 컨트롤러를 선언하여 부모가 re-build되어도 입력값이 유지됨
  late final TextEditingController _inputController;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    // 💡 메모리 누수 방지를 위한 자원 해제
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: widget.label,
                labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey[300]!)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey[200]!)),
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
                decoration: InputDecoration(
                  hintText: '입력',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Colors.blue)),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 3. 확인 버튼
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  final inputText = _inputController.text;
                  widget.onConfirm!(widget.label, inputText);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
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