import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/indices/account_edit/account_edit_components.dart';
import 'package:idcs/services/common/user_api_service.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/theme/theme_controller.dart';
import 'package:idcs/main.dart'; // AuthService 접근용

class PersonalPage extends StatefulWidget {
  final String userId;

  const PersonalPage({super.key, required this.userId});

  @override
  State<PersonalPage> createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _currentPwController = TextEditingController();
  final TextEditingController _newPwController = TextEditingController();

  bool _isAdmin = false;
  bool _isLoading = true;
  List<dynamic> _linkedProviders = [];

  /// 소셜로만 가입한 계정은 비밀번호가 없어 변경 UI를 숨긴다.
  bool _hasPassword = true;
  String _pwCollapseMessage = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
          _nameController.text = profile['name'] ?? '';
          _phoneController.text = profile['phone_number'] ?? '';
          _linkedProviders = profile['linked_providers'] ?? [];
          _hasPassword = profile['has_password'] ?? true;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUpdateName() async {
    try {
      final msg = await UserApiService.updateName(widget.userId, _nameController.text.trim());
      if (!mounted) return;
      setState(() {}); // 상단 프로필 카드에 바뀐 이름을 바로 반영
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _handleUpdatePhone() async {
    try {
      final msg = await UserApiService.updatePhone(widget.userId, _phoneController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _handleUpdatePassword() async {
    final currentPw = _currentPwController.text.trim();
    final newPw = _newPwController.text.trim();

    if (currentPw.isEmpty || newPw.isEmpty) {
      setState(() => _pwCollapseMessage = '비밀번호를 모두 입력해주세요.');
      return;
    }
    if (currentPw == newPw) {
      setState(() => _pwCollapseMessage = '새 비밀번호가 기존 비밀번호와 동일합니다.');
      return;
    }

    try {
      final msg = await UserApiService.updatePassword(widget.userId, currentPw, newPw);
      if (!mounted) return;
      setState(() {
        _pwCollapseMessage = '성공적으로 변경되었습니다.';
        _currentPwController.clear();
        _newPwController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      setState(() => _pwCollapseMessage = '오류: $e');
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
        title: const Text('정말 탈퇴하시겠습니까?'),
        content: const Text('계정 정보와 시설 소속 정보가 모두 삭제되며 되돌릴 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: const Text('탈퇴하기'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final msg = await UserApiService.withdraw(widget.userId);
      await AuthService.setUserId(null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _handleSocialLink(String provider) async {
    if (_linkedProviders.contains(provider)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미 $provider 계정과 연동되어 있습니다.')));
      return;
    }
    // TODO: 소셜 로그인 SDK 호출 후 연동 API(AuthApiService.linkSocial 등) 트리거 로직 작성
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$provider 연동은 백엔드 /link-social API로 연결해야 합니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 정보')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 계정 요약 + 로그아웃
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.outline),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.person_rounded, color: context.colors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text.isEmpty ? '이름 없음' : _nameController.text,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: context.colors.textPrimary),
                        ),
                        Text('ID ${widget.userId}', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                      ],
                    ),
                  ),
                  TextButton(onPressed: _handleLogout, child: const Text('로그아웃')),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_isAdmin) ...[
              _AdminLinkCard(
                title: '통합 소요 기록',
                icon: Icons.assignment_outlined,
                onPressed: () => context.push('/total_board/${widget.userId}'),
              ),
              const SizedBox(height: 16),
            ],

            // Box #2
            UsernameEditBox(
              controller: _nameController,
              onSubmit: _handleUpdateName,
            ),
            const SizedBox(height: 16),

            // Box #3
            PhoneEditBox(
              controller: _phoneController,
              onSubmit: _handleUpdatePhone,
            ),
            const SizedBox(height: 16),

            // Box #4 — 소셜로만 가입한 계정은 비밀번호 자체가 없으므로 숨긴다
            if (_hasPassword) ...[
              PasswordEditBox(
                currentPwController: _currentPwController,
                newPwController: _newPwController,
                collapseMessage: _pwCollapseMessage,
                onSubmit: _handleUpdatePassword,
              ),
              const SizedBox(height: 16),
            ],

            // Box #5
            SocialLinkBox(
              linkedProviders: _linkedProviders,
              onLinkPressed: _handleSocialLink,
            ),
            const SizedBox(height: 16),

            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.mode,
              builder: (context, mode, _) => ThemeModeBox(
                current: mode,
                onChanged: ThemeController.set,
              ),
            ),
            const SizedBox(height: 16),

            WithdrawBox(onWithdraw: _handleWithdraw),
          ],
        ),
      ),
    );
  }
}

/// 관리자 전용 화면으로 이동하는 카드 (평소엔 탭이 아니라 여기서만 노출)
class _AdminLinkCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPressed;

  const _AdminLinkCard({required this.title, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: context.colors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.colors.textPrimary)),
              ),
              Icon(Icons.chevron_right_rounded, color: context.colors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}