// 경로: lib/components/signup/signup_components.dart
import 'package:flutter/material.dart';
import 'package:idcs/services/common/social_auth_service.dart';
import 'package:idcs/theme/app_theme.dart';

/// Box #1: 일반 계정 생성 박스
class StandardSignupBox extends StatefulWidget {
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
  State<StandardSignupBox> createState() => _StandardSignupBoxState();
}

class _StandardSignupBoxState extends State<StandardSignupBox> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: '이메일',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: widget.passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: '비밀번호',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: '비밀번호 표시',
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: context.colors.textSecondary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: widget.nameController,
          decoration: const InputDecoration(
            labelText: '이름',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: widget.phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: '전화번호 (선택)',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: widget.onSignupPressed,
          child: const Text('계정 생성'),
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
    // On web the plugin cannot run this sign-in flow at all, so showing the
    // buttons would only offer a dead end.
    if (!SocialAuthService.isSupported) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('또는', style: Theme.of(context).textTheme.bodyMedium),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => onSocialSignupPressed('google'),
          icon: const _ProviderBadge(
            label: 'G',
            background: Color(0xFF4285F4),
          ),
          label: const Text('Google로 계속하기'),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.colors.textPrimary,
            side: BorderSide(color: context.colors.outline),
            alignment: Alignment.centerLeft,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => onSocialSignupPressed('apple'),
          icon: const _ProviderBadge(
            label: '',
            background: Colors.black,
            icon: Icons.apple,
          ),
          label: const Text('Apple로 계속하기'),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.colors.textPrimary,
            side: BorderSide(color: context.colors.outline),
            alignment: Alignment.centerLeft,
          ),
        ),
      ],
    );
  }
}

class _ProviderBadge extends StatelessWidget {
  final String label;
  final Color background;
  final IconData? icon;

  const _ProviderBadge({required this.label, required this.background, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: icon != null
          ? Icon(icon, size: 14, color: context.colors.onPrimary)
          : Text(
              label,
              style: TextStyle(color: context.colors.onPrimary, fontSize: 13, fontWeight: FontWeight.w700),
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
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: context.colors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: context.colors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '애플 계정의 이메일 정보가 누락되었습니다.\n원활한 서비스 이용을 위해 이메일을 직접 입력해주세요.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textPrimary, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: fallbackEmailController,
            decoration: const InputDecoration(
              labelText: '이메일',
              hintText: 'name@example.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onCancel, child: const Text('취소')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onSubmit,
                child: const Text('입력 완료'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
