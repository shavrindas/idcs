import 'package:flutter/material.dart';

class MonitoringCard extends StatelessWidget {
  final String title;
  final Map<String, String> fields; // 💡 평평한 1층짜리 딕셔너리 (속성명: 속성값)

  const MonitoringCard({
    super.key,
    required this.title,
    required this.fields,
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
            // 1층 딕셔너리를 돌면서 텍스트 필드를 바로 생성
            ...fields.entries.map((entry) => _buildReadOnlyField(
              label: entry.key,
              value: entry.value,
            )),
          ],
        ),
      ),
    );
  }

  // 기존 출력 형태 스타일 완벽 유지
  Widget _buildReadOnlyField({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        key: ValueKey(value), // 값 변경 시 실시간 반영을 위한 키
        initialValue: value,
        readOnly: true,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey[200]!)),
        ),
      ),
    );
  }
}