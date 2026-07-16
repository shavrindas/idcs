
import 'package:flutter/material.dart';

/// Box #2: 아이디(username) 수정 박스
class UsernameEditBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const UsernameEditBox({super.key, required this.controller, required this.onSubmit});

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
              const SizedBox(width: 120, child: Text('아이디(username)', style: TextStyle(color: Colors.amber))),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onSubmit, child: const Text('버튼(submit) 계정 수정')),
        ],
      ),
    );
  }
}

/// Box #3: 전화번호 수정 박스
class PhoneEditBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const PhoneEditBox({super.key, required this.controller, required this.onSubmit});

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
              const SizedBox(width: 120, child: Text('전화번호', style: TextStyle(color: Colors.amber))),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onSubmit, child: const Text('버튼(submit) 계정 수정')),
        ],
      ),
    );
  }
}

/// Box #4: 비밀번호 수정 박스
class PasswordEditBox extends StatelessWidget {
  final TextEditingController currentPwController;
  final TextEditingController newPwController;
  final String collapseMessage;
  final VoidCallback onSubmit;

  const PasswordEditBox({
    super.key,
    required this.currentPwController,
    required this.newPwController,
    required this.collapseMessage,
    required this.onSubmit,
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
              const SizedBox(width: 120, child: Text('기존 비밀번호 입력', style: TextStyle(color: Colors.amber))),
              Expanded(
                child: TextField(
                  controller: currentPwController,
                  obscureText: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 120, child: Text('새 비밀번호 입력', style: TextStyle(color: Colors.amber))),
              Expanded(
                child: TextField(
                  controller: newPwController,
                  obscureText: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Collapse 영역 (비밀번호 동일 여부 등 안내)
          if (collapseMessage.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 2)),
              child: Text(collapseMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black)),
            ),
          ElevatedButton(onPressed: onSubmit, child: const Text('버튼(submit) 비밀번호 다시 설정하기')),
        ],
      ),
    );
  }
}

/// Box #5: 외부 프로바이더 연동 박스
class SocialLinkBox extends StatelessWidget {
  final List<dynamic> linkedProviders;
  final Function(String) onLinkPressed;

  const SocialLinkBox({
    super.key,
    required this.linkedProviders,
    required this.onLinkPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => onLinkPressed('google'),
                style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(24)),
                child: const Text('google'),
              ),
              ElevatedButton(
                onPressed: () => onLinkPressed('apple'),
                style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(24)),
                child: const Text('apple'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 연동된 계정이 있을 경우 Collapse 출력
          if (linkedProviders.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 2)),
              child: Text(
                'collapse 출력 : (이미 [${linkedProviders.join('|')}]로 연동된 계정)',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }
}