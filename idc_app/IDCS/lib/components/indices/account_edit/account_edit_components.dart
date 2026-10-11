import 'package:flutter/material.dart';
import 'package:idcs/components/shared/async_action_button.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/l10n/l10n_context.dart';

/// 내 정보 카드.
///
/// 예전에는 이름·전화번호가 각각 입력칸과 저장 버튼을 달고 항상 열려 있었다.
/// 평소에 바꿀 일이 거의 없는 값인데 화면이 늘 '수정 중'처럼 보이고,
/// 지금 값이 무엇인지 읽기도 어려웠다. 평소엔 읽기 전용으로 두고
/// 수정 버튼을 눌렀을 때만 입력칸이 열리도록 한다.
class ProfileInfoBox extends StatefulWidget {
  final String name;
  final String phone;

  /// 이 계정이 어떤 방식으로 로그인하는지 (예: '이메일', 'Google').
  final String loginMethod;

  /// 바뀐 값만 저장한다. 실패하면 예외를 던져 수정 모드를 유지한다.
  final Future<void> Function(String name, String phone) onSave;

  const ProfileInfoBox({
    super.key,
    required this.name,
    required this.phone,
    required this.loginMethod,
    required this.onSave,
  });

  @override
  State<ProfileInfoBox> createState() => _ProfileInfoBoxState();
}

class _ProfileInfoBoxState extends State<ProfileInfoBox> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startEditing() {
    _nameController.text = widget.name;
    _phoneController.text = widget.phone;
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    await widget.onSave(_nameController.text.trim(), _phoneController.text.trim());
    if (mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return _EditCard(
      title: context.l10n.profileTitle,
      child: _editing ? _buildEditing(context) : _buildReading(context),
    );
  }

  Widget _buildReading(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoRow(icon: Icons.badge_outlined, label: context.l10n.fieldName, value: widget.name.isEmpty ? '-' : widget.name),
        _InfoRow(icon: Icons.phone_outlined, label: context.l10n.fieldPhone, value: widget.phone.isEmpty ? '-' : widget.phone),
        // 이미 로그인한 사용자에게 '연동하기'를 권하는 대신, 지금 어떤 방식으로
        // 로그인하는지만 알려준다.
        _InfoRow(icon: Icons.login_rounded, label: context.l10n.loginMethod, value: widget.loginMethod),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _startEditing,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(context.l10n.actionEdit),
        ),
      ],
    );
  }

  Widget _buildEditing(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: context.l10n.fieldName, prefixIcon: Icon(Icons.badge_outlined)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: context.l10n.fieldPhone, prefixIcon: Icon(Icons.phone_outlined)),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _editing = false),
                child: Text(context.l10n.actionCancel),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: AsyncActionButton(label: context.l10n.actionSave, onPressed: _save)),
          ],
        ),
      ],
    );
  }
}

/// 읽기 모드에서 쓰는 한 줄 (라벨 - 값).
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.colors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 76,
            child: Text(label, style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 비밀번호 변경. 자주 쓰는 기능이 아니라 평소엔 접어두고 눌렀을 때만 펼친다.
class PasswordChangeBox extends StatefulWidget {
  final TextEditingController currentPwController;
  final TextEditingController newPwController;
  final String collapseMessage;
  final Future<void> Function() onSubmit;

  const PasswordChangeBox({
    super.key,
    required this.currentPwController,
    required this.newPwController,
    required this.collapseMessage,
    required this.onSubmit,
  });

  @override
  State<PasswordChangeBox> createState() => _PasswordChangeBoxState();
}

class _PasswordChangeBoxState extends State<PasswordChangeBox> {
  bool _expanded = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  Widget build(BuildContext context) {
    return _EditCard(
      title: context.l10n.passwordSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 18, color: context.colors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.passwordChange,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 20,
                    color: context.colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
            TextField(
              controller: widget.currentPwController,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: context.l10n.fieldCurrentPassword,
                suffixIcon: IconButton(
                  tooltip: context.l10n.showPassword,
                  icon: Icon(_obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: context.colors.textSecondary),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: widget.newPwController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: context.l10n.fieldNewPassword,
                suffixIcon: IconButton(
                  tooltip: context.l10n.showPassword,
                  icon: Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: context.colors.textSecondary),
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
            AsyncActionButton(label: context.l10n.passwordChange, onPressed: widget.onSubmit),
          ],
        ],
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
            context.l10n.withdrawTitle,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.error),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.withdrawNote,
            style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onWithdraw,
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.error,
              side: BorderSide(color: context.colors.error.withValues(alpha: 0.5)),
            ),
            child: Text(context.l10n.withdrawTitle),
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
