import 'package:flutter/material.dart';
import 'package:idcs/services/common/social_auth_service.dart';
import 'package:idcs/components/shared/async_action_button.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/l10n/l10n_context.dart';

/// Box #1: 일반 로그인 박스 (이메일/비밀번호 입력 + 제출)
class StandardLoginBox extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final Future<void> Function() onLoginPressed;

  const StandardLoginBox({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onLoginPressed,
  });

  @override
  State<StandardLoginBox> createState() => _StandardLoginBoxState();
}

class _StandardLoginBoxState extends State<StandardLoginBox> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: context.l10n.fieldEmail,
            hintText: 'name@example.com',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: widget.passwordController,
          obscureText: _obscurePassword,
          onSubmitted: (_) => widget.onLoginPressed(),
          decoration: InputDecoration(
            labelText: context.l10n.fieldPassword,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: context.l10n.showPassword,
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: context.colors.textSecondary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 20),
        AsyncActionButton(label: context.l10n.login, onPressed: widget.onLoginPressed),
      ],
    );
  }
}

/// Box #2: 소셜 로그인 박스
class SocialLoginBox extends StatelessWidget {
  final Function(String) onSocialLoginPressed;

  const SocialLoginBox({super.key, required this.onSocialLoginPressed});

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
              child: Text(context.l10n.orDivider, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => onSocialLoginPressed('google'),
          icon: const _ProviderBadge(
            label: 'G',
            background: Color(0xFF4285F4),
          ),
          label: Text(context.l10n.continueWithGoogle),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.colors.textPrimary,
            side: BorderSide(color: context.colors.outline),
            alignment: Alignment.centerLeft,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => onSocialLoginPressed('apple'),
          icon: const _ProviderBadge(
            label: '',
            background: Colors.black,
            icon: Icons.apple,
          ),
          label: Text(context.l10n.continueWithApple),
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

/// Box #3: 로그인 상태 유지 체크박스
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
    return InkWell(
      onTap: () => onChanged(!isChecked),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(value: isChecked, onChanged: onChanged),
          const SizedBox(width: 4),
          Text(context.l10n.keepSignedIn, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
