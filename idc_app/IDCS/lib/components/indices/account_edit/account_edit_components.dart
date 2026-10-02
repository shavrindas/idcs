import 'package:flutter/material.dart';
import 'package:idcs/components/shared/async_action_button.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/theme/theme_controller.dart';

/// Box #2: 아이디(username) 수정 박스
class UsernameEditBox extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function() onSubmit;

  const UsernameEditBox({super.key, required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return _EditCard(
      title: '이름',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_outlined)),
          ),
          const SizedBox(height: 14),
          AsyncActionButton(label: '이름 저장', onPressed: onSubmit),
        ],
      ),
    );
  }
}

/// Box #3: 전화번호 수정 박스
class PhoneEditBox extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function() onSubmit;

  const PhoneEditBox({super.key, required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return _EditCard(
      title: '전화번호',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined)),
          ),
          const SizedBox(height: 14),
          AsyncActionButton(label: '전화번호 저장', onPressed: onSubmit),
        ],
      ),
    );
  }
}

/// Box #4: 비밀번호 수정 박스
class PasswordEditBox extends StatefulWidget {
  final TextEditingController currentPwController;
  final TextEditingController newPwController;
  final String collapseMessage;
  final Future<void> Function() onSubmit;

  const PasswordEditBox({
    super.key,
    required this.currentPwController,
    required this.newPwController,
    required this.collapseMessage,
    required this.onSubmit,
  });

  @override
  State<PasswordEditBox> createState() => _PasswordEditBoxState();
}

class _PasswordEditBoxState extends State<PasswordEditBox> {
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  Widget build(BuildContext context) {
    return _EditCard(
      title: '비밀번호 변경',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: widget.currentPwController,
            obscureText: _obscureCurrent,
            decoration: InputDecoration(
              labelText: '기존 비밀번호',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: '비밀번호 표시',
                icon: Icon(_obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: context.colors.textSecondary),
                onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.newPwController,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              labelText: '새 비밀번호',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: '비밀번호 표시',
                icon: Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: context.colors.textSecondary),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
          ),
          if (widget.collapseMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.collapseMessage,
              style: TextStyle(color: context.colors.primary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 14),
          AsyncActionButton(label: '비밀번호 변경', onPressed: widget.onSubmit),
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

  bool _isLinked(String provider) =>
      linkedProviders.any((p) => p.toString().toLowerCase() == provider);

  @override
  Widget build(BuildContext context) {
    return _EditCard(
      title: '연동 계정',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProviderRow(
            label: 'Google',
            isLinked: _isLinked('google'),
            onPressed: () => onLinkPressed('google'),
            badge: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0xFF4285F4), shape: BoxShape.circle),
              child: const Text('G', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          _ProviderRow(
            label: 'Apple',
            isLinked: _isLinked('apple'),
            onPressed: () => onLinkPressed('apple'),
            badge: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              child: const Icon(Icons.apple, color: Colors.white, size: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// 프로바이더 한 줄. 이미 연동된 계정은 '연동됨'으로 표시하고 버튼을 없앤다.
class _ProviderRow extends StatelessWidget {
  final String label;
  final bool isLinked;
  final Widget badge;
  final VoidCallback onPressed;

  const _ProviderRow({
    required this.label,
    required this.isLinked,
    required this.badge,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        children: [
          badge,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
            ),
          ),
          if (isLinked)
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: context.colors.success, size: 17),
                const SizedBox(width: 5),
                Text(
                  '연동됨',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.success),
                ),
              ],
            )
          else
            TextButton(onPressed: onPressed, child: const Text('연동하기')),
        ],
      ),
    );
  }
}

/// 화면 테마(밝게/어둡게/시스템 설정) 선택 박스.
class ThemeModeBox extends StatelessWidget {
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  const ThemeModeBox({super.key, required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _EditCard(
      title: '화면 테마',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: ThemeMode.values.map((mode) {
          final selected = current == mode;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            onTap: () => onChanged(mode),
            leading: Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: selected ? context.colors.primary : context.colors.textSecondary,
              size: 20,
            ),
            title: Text(
              ThemeController.labelOf(mode),
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: context.colors.textPrimary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 계정 탈퇴 박스. 되돌릴 수 없는 동작이라 다른 카드와 분리해 경고색으로 표시한다.
class WithdrawBox extends StatelessWidget {
  final VoidCallback onWithdraw;

  const WithdrawBox({super.key, required this.onWithdraw});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '계정 탈퇴',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.error),
          ),
          const SizedBox(height: 8),
          Text(
            '탈퇴하면 계정 정보와 시설 소속 정보가 모두 삭제되며 되돌릴 수 없습니다.',
            style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onWithdraw,
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.error,
              side: BorderSide(color: context.colors.error.withValues(alpha: 0.5)),
            ),
            child: const Text('계정 탈퇴'),
          ),
        ],
      ),
    );
  }
}

class _EditCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _EditCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textSecondary)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
