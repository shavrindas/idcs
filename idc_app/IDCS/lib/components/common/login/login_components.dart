import 'package:flutter/material.dart';

/// Box #1: 일반 로그인 박스
class StandardLoginBox extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLoginPressed;

  const StandardLoginBox({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onLoginPressed,
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
              const SizedBox(width: 60, child: Text('이메일')),
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
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 60, child: Text('비밀번호')),
              Expanded(
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
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
            onPressed: onLoginPressed,
            child: const Text('버튼(submit) 로그인'),
          ),
        ],
      ),
    );
  }
}

/// Box #2: 소셜 로그인 박스
class SocialLoginBox extends StatelessWidget {
  final Function(String) onSocialLoginPressed;

  const SocialLoginBox({super.key, required this.onSocialLoginPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () => onSocialLoginPressed('google'),
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(24),
            ),
            child: const Text('google'),
          ),
          ElevatedButton(
            onPressed: () => onSocialLoginPressed('apple'),
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(24),
            ),
            child: const Text('apple'),
          ),
        ],
      ),
    );
  }
}

/// Box #3: 로그인 상태 유지 체크박스 박스
class KeepLoginStateBox extends StatelessWidget {
  final bool isChecked;
  final ValueChanged<bool?> onChanged;

  const KeepLoginStateBox({
    super.key,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Checkbox(
            value: isChecked,
            onChanged: onChanged,
          ),
          const Text('로그인 상태 유지하기'),
        ],
      ),
    );
  }
}