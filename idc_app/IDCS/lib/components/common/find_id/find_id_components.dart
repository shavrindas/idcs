// 경로: lib/components/common/find_id/find_id_components.dart
import 'package:flutter/material.dart';

/// Box #1: 아이디(이메일) 가입 여부 확인 박스
class FindIdBox extends StatelessWidget {
  final TextEditingController emailController;
  final VoidCallback onSubmit;
  final String resultMessage;
  final bool isExpanded; // collapse 출력을 제어할 상태값

  const FindIdBox({
    super.key,
    required this.emailController,
    required this.onSubmit,
    required this.resultMessage,
    required this.isExpanded,
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
              const SizedBox(width: 80, child: Text('이메일 입력')),
              Expanded(
                child: TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onSubmit,
            child: const Text('버튼(submit) 연동 계정 확인하기'),
          ),

          // Collapse 영역: isExpanded가 true일 때만 노출
          if (isExpanded) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.purpleAccent, width: 2), // 이미지의 보라색 테두리 반영
              ),
              child: Text(
                resultMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ]
        ],
      ),
    );
  }
}