import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 클립보드 사용을 위해 추가
import 'package:go_router/go_router.dart';
import 'package:idcs/components/indices/account_edit/account_edit_components.dart';
import 'package:idcs/components/indices/settings/settings_sections.dart';
import 'package:idcs/services/common/user_api_service.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/main.dart'; // AuthService 접근용
import '../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/components/shared/app_toast.dart';

class PersonalPage extends StatefulWidget {
  final String userId;

  const PersonalPage({super.key, required this.userId});

  @override
  State<PersonalPage> createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  final TextEditingController _currentPwController = TextEditingController();
  final TextEditingController _newPwController = TextEditingController();

  bool _isAdmin = false;
  bool _isLoading = true;
  List<dynamic> _linkedProviders = [];

  String _name = '';
  String _phone = '';
  String _userCode = ''; // 👈 유저 코드 상태 추가


  /// 소셜로만 가입한 계정은 비밀번호가 없어 변경 UI를 숨긴다.
  bool _hasPassword = true;
  String _pwCollapseMessage = '';

  /// 이 계정이 어떤 방식으로 로그인하는지. 이미 로그인한 사용자에게
  /// '연동하기'를 권하는 대신 현재 상태만 보여준다.
  String _loginMethodLabel(BuildContext context) {
    final providers = _linkedProviders
        .map((p) => p.toString())
        .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
        .toList();
    final email = context.l10n.loginMethodEmail;
    if (providers.isEmpty) return email;
    return _hasPassword ? '$email · ${providers.join(' · ')}' : providers.join(' · ');
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // 권한 정보 및 기본 프로필 조회
      final role = await UserApiService.getUserRole(widget.userId);
      final profile = await UserApiService.getUserProfile(widget.userId);

      if (mounted) {
        setState(() {
          _isAdmin = (role == 'ADMIN' || role == 'DEVELOPER');
          _name = profile['name'] ?? '';
          _phone = profile['phone_number'] ?? '';
          _userCode = profile['user_code'] ?? ''; 
          _linkedProviders = profile['linked_providers'] ?? [];
          _hasPassword = profile['has_password'] ?? true;
        });
      }
    } catch (e) {
      if (mounted) AppToast.error(context, describeApiError(context, e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 수정 모드에서 저장. 실제로 바뀐 값만 서버에 보낸다.
  /// 실패하면 예외를 그대로 올려 수정 모드가 닫히지 않게 한다.
  Future<void> _handleSaveProfile(String name, String phone) async {
    var changed = 0;

    if (name != _name) {
      await UserApiService.updateName(widget.userId, name);
      changed++;
    }
    if (phone != _phone) {
      await UserApiService.updatePhone(widget.userId, phone);
      changed++;
    }

    if (!mounted) return;

    if (changed == 0) {
      AppToast.warning(context, context.l10n.profileNoChanges);
      return;
    }

    setState(() {
      _name = name;
      _phone = phone;
    });
    AppToast.success(context, context.l10n.profileSaved);
  }

  Future<void> _handleUpdatePassword() async {
    final currentPw = _currentPwController.text.trim();
    final newPw = _newPwController.text.trim();

    if (currentPw.isEmpty || newPw.isEmpty) {
      setState(() => _pwCollapseMessage = context.l10n.passwordAllRequired);
      return;
    }
    if (currentPw == newPw) {
      setState(() => _pwCollapseMessage = context.l10n.passwordSameAsOld);
      return;
    }

    try {
      await UserApiService.updatePassword(widget.userId, currentPw, newPw);
      if (!mounted) return;
      setState(() {
        _pwCollapseMessage = context.l10n.profileSaved;
        _currentPwController.clear();
        _newPwController.clear();
      });
      AppToast.success(context, context.l10n.profileSaved);
    } catch (e) {
      setState(() => _pwCollapseMessage = context.l10n.errorPrefix(describeApiError(context, e)));
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.setUserId(null);
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _handleWithdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.withdrawConfirmTitle),
        content: Text(context.l10n.withdrawConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.l10n.actionCancel)),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: Text(context.l10n.withdrawConfirmAction),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await UserApiService.withdraw(widget.userId);
      await AuthService.setUserId(null);
      if (!mounted) return;
      AppToast.success(context, context.l10n.withdrawDone);
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, describeApiError(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 프로필 정보 카드 (유저 코드 및 복사 기능 파라미터가 ProfileInfoBox 내부 컴포넌트 규격에 맞게 전달되도록 함)
                  ProfileInfoBox(
                    userId: widget.userId,
                    name: _name,
                    phone: _phone,
                    userCode: _userCode, 
                    loginMethod: _loginMethodLabel(context),
                    onSave: _handleSaveProfile,
                    onCopyUserCode: _userCode.isEmpty ? null : () {
                      Clipboard.setData(ClipboardData(text: _userCode));
                      AppToast.success(context, '유저 코드가 복사되었습니다.');
                    },
                  ),
                  const SizedBox(height: 16),

                  const AppSettingsSections(),
                  const SizedBox(height: 16),

                  if (_hasPassword) ...[
                    PasswordChangeBox(
                      currentPwController: _currentPwController,
                      newPwController: _newPwController,
                      collapseMessage: _pwCollapseMessage,
                      onSubmit: _handleUpdatePassword,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_isAdmin) ...[
                    _LinkCard(
                      title: context.l10n.profileTotalBoard,
                      icon: Icons.assignment_outlined,
                      onPressed: () => context.push('/total_board/${widget.userId}'),
                    ),
                    const SizedBox(height: 16),
                  ],

                  OutlinedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(context.l10n.actionLogout),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _handleWithdraw,
                      style: TextButton.styleFrom(
                        foregroundColor: context.colors.textSecondary,
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      child: Text(context.l10n.withdrawTitle),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }
}

/// 다른 화면으로 넘어가는 줄 카드 (설정, 관리자 전용 통합 소요 기록 등)
class _LinkCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPressed;

  const _LinkCard({required this.title, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: context.colors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.colors.textPrimary),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.colors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}