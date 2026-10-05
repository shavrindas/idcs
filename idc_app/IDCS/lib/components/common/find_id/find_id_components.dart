// 경로: lib/components/common/find_id/find_id_components.dart
import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          onSubmitted: (_) => onSubmit(),
          decoration: const InputDecoration(
            labelText: '이메일',
            hintText: 'name@example.com',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onSubmit,
          child: const Text('가입 여부 확인하기'),
        ),

        // 결과 영역: isExpanded가 true일 때만 노출
        if (isExpanded) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.colors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: context.colors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    resultMessage,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
