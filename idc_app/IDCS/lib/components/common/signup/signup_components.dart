// 경로: lib/components/signup/signup_components.dart
import 'package:flutter/material.dart';

/// Box #1: 일반 계정 생성 박스
class StandardSignupBox extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final VoidCallback onSignupPressed;

  const StandardSignupBox({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.nameController,
    required this.phoneController,
    required this.onSignupPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputRow('이메일(필수)', emailController),
          const SizedBox(height: 8),
          _buildInputRow('비밀번호(필수)', passwordController, isObscure: true),
          const SizedBox(height: 8),
          _buildInputRow('아이디/이름(필수)', nameController),
          const SizedBox(height: 8),
          _buildInputRow('전화번호', phoneController),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onSignupPressed,
            child: const Text('버튼(submit) 계정 생성'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller, {bool isObscure = false}) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13))),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

/// Box #2: 외부 프로바이더 사용 계정 생성 박스
class SocialSignupBox extends StatelessWidget {
  final Function(String) onSocialSignupPressed;

  const SocialSignupBox({super.key, required this.onSocialSignupPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () => onSocialSignupPressed('google'),
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(24),
            ),
            child: const Text('google'),
          ),
          ElevatedButton(
            onPressed: () => onSocialSignupPressed('apple'),
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


/// Box #3: 애플 로그인 이메일 누락 시 방어 팝업(콜랩스 박스)
class AppleEmailFallbackBox extends StatelessWidget {
  final TextEditingController fallbackEmailController;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const AppleEmailFallbackBox({
    super.key,
    required this.fallbackEmailController,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orangeAccent), // 방어 코드/입력 요청 의미
        color: Colors.orange.withOpacity(0.05),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '애플 계정의 이메일 정보가 누락되었습니다.\n원활한 서비스 이용을 위해 이메일을 직접 입력해주세요.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 80, child: Text('이메일', style: TextStyle(fontSize: 13))),
              Expanded(
                child: TextField(
                  controller: fallbackEmailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    hintText: 'example@domain.com',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onCancel, child: const Text('취소')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onSubmit,
                child: const Text('입력 완료 및 계정 생성'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}