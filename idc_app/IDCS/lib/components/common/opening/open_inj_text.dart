// 경로 : lib/components/common/opening/open_inj_text.dart
// 명세 : 직접 입력한 ID로 권한을 주입하는 박스 (DEBUG 전용 개발자 도구)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/theme/app_theme.dart';
import '../../../main.dart';

class CustomAuthInjectionBox extends StatefulWidget {
  const CustomAuthInjectionBox({super.key});

  @override
  State<CustomAuthInjectionBox> createState() => CustomAuthInjectionBoxState();
}

class CustomAuthInjectionBoxState extends State<CustomAuthInjectionBox> {
  final TextEditingController _idController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

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
              final int? id = int.tryParse(_idController.text.trim());

              if (id != null) {
                // 1. 전역 로그인 상태(AuthService) 업데이트
                AuthService.setUserId(id);

                // 2. 입력받은 id를 파라미터로 하여 메인 색인 페이지로 이동
                context.go('/index/$id/home');
              } else {
                // 숫자가 아니거나 비어있을 경우 경고창
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('유효한 유저 ID(숫자)를 입력해주세요.')),
                );
              }
            },
            child: const Text('버튼(이동)'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _idController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '권한 주입 계정(user_입력)',
                border: UnderlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}