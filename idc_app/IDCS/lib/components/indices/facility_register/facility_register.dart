import 'package:flutter/material.dart';

/// Box #2: 시설 접근 코드 입력 및 등록 박스
class FacilityInputBox extends StatelessWidget {
  final TextEditingController codeController;
  final VoidCallback onSubmit;
  final String collapseMessage;

  const FacilityInputBox({
    super.key, required this.codeController, required this.onSubmit, required this.collapseMessage
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: 100, child: Text('시설 접근 코드', style: TextStyle(color: Colors.amber))),
              Expanded(
                child: TextField(
                  controller: codeController,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onSubmit, child: const Text('버튼(submit) 시설 등록')),
          if (collapseMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 2)),
              child: Text(collapseMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black)),
            ),
          ]
        ],
      ),
    );
  }
}

/// Box #3: 등록된 시설 리스트 및 해제 박스
class FacilityListEditBox extends StatelessWidget {
  final List<dynamic> facilities;
  final Function(int) onUnlink;

  const FacilityListEditBox({super.key, required this.facilities, required this.onUnlink});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('시설 리스트', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (facilities.isEmpty)
            const Text('등록된 시설이 없습니다.', style: TextStyle(color: Colors.grey)),
          ...facilities.map((fac) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                      child: Text(fac['name']),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => onUnlink(fac['id']),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
                    child: const Text('해제', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}