// 경로 : lib/components/common/opening/open_inj_static.dart
// 명세 : Box #3, #4 — 고정 ID 권한 주입 박스 (DEBUG 전용 개발자 도구)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/theme/app_theme.dart';
import '../../../main.dart';

class AuthInjectionBox extends StatelessWidget {
  final String title;
  final int userIdToInject;

  const AuthInjectionBox({
    super.key,
    required this.title,
    required this.userIdToInject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.outline),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: () {
              // 1. 전역 로그인 상태(AuthService) 업데이트
              AuthService.setUserId(userIdToInject);

              // 2. GoRouter를 활용하여 메인 색인 페이지로 이동 (id 파라미터 전달)
              context.go('/index/$userIdToInject/home');
            },
            child: const Text('버튼(이동)'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title),
          ),
        ],
      ),
    );
  }
}