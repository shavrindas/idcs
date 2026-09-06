import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';

/// Box #2: 아이디(username) 수정 박스
class UsernameEditBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

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
          ElevatedButton(onPressed: onSubmit, child: const Text('이름 저장')),
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
          ElevatedButton(onPressed: onSubmit, child: const Text('전화번호 저장')),
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
  final VoidCallback onSubmit;

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
                icon: Icon(_obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textSecondary),
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
                icon: Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textSecondary),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
          ),
          if (widget.collapseMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.collapseMessage,
              style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 14),
          ElevatedButton(onPressed: widget.onSubmit, child: const Text('비밀번호 변경')),
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
    return _EditCard(
      title: '연동 계정',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onLinkPressed('google'),
                  icon: Container(
                    width: 20, height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Color(0xFF4285F4), shape: BoxShape.circle),
                    child: const Text('G', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  label: const Text('Google'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onLinkPressed('apple'),
                  icon: Container(
                    width: 20, height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                    child: const Icon(Icons.apple, color: Colors.white, size: 13),
                  ),
                  label: const Text('Apple'),
                ),
              ),
            ],
          ),
          if (linkedProviders.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '연동됨: ${linkedProviders.join(', ')}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
