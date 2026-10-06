import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/indices/account_edit/account_edit_components.dart';
import 'package:idcs/services/common/user_api_service.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/main.dart'; // AuthService 접근용
import '../../services/common/api_client.dart';

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

  /// 소셜로만 가입한 계정은 비밀번호가 없어 변경 UI를 숨긴다.
  bool _hasPassword = true;
  String _pwCollapseMessage = '';

  /// 이 계정이 어떤 방식으로 로그인하는지. 이미 로그인한 사용자에게
  /// '연동하기'를 권하는 대신 현재 상태만 보여준다.
  String get _loginMethod {
    final providers = _linkedProviders
        .map((p) => p.toString())
        .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
        .toList();
    if (providers.isEmpty) return '이메일';
    return _hasPassword ? '이메일 · ${providers.join(' · ')}' : providers.join(' · ');
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

  /// 수정 모드에서 저장. 실제로 바뀐 값만 서버에 보낸다.
  /// 실패하면 예외를 그대로 올려 수정 모드가 닫히지 않게 한다.
  Future<void> _handleSaveProfile(String name, String phone) async {
    final List<String> messages = [];

    if (name != _name) {
      messages.add(await UserApiService.updateName(widget.userId, name));
    }
    if (phone != _phone) {
      messages.add(await UserApiService.updatePhone(widget.userId, phone));
    }

    if (!mounted) return;

    if (messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('변경된 내용이 없습니다.')));
      return;
    }

    setState(() {
      _name = name;
      _phone = phone;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messages.join(' / '))));
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
      setState(() => _pwCollapseMessage = '오류: ${describeApiError(e)}');
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
                          _name.isEmpty ? '이름 없음' : _name,
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

            // 앱 설정(화면 테마·알람)은 계정 정보와 성격이 달라 별도 화면으로 모았다.
            _LinkCard(
              title: '설정',
              subtitle: '화면 테마, 알람 소리·진동',
              icon: Icons.settings_outlined,
              onPressed: () => context.push('/settings'),
            ),
            const SizedBox(height: 16),

            if (_isAdmin) ...[
              _LinkCard(
                title: '통합 소요 기록',
                icon: Icons.assignment_outlined,
                onPressed: () => context.push('/total_board/${widget.userId}'),
              ),
              const SizedBox(height: 16),
            ],

            // 이름·전화번호·로그인 방식. 평소엔 읽기 전용, 수정 버튼으로 연다.
            ProfileInfoBox(
              name: _name,
              phone: _phone,
              loginMethod: _loginMethod,
              onSave: _handleSaveProfile,
            ),
            const SizedBox(height: 16),

            // 소셜로만 가입한 계정은 비밀번호 자체가 없으므로 숨긴다
            if (_hasPassword) ...[
              PasswordChangeBox(
                currentPwController: _currentPwController,
                newPwController: _newPwController,
                collapseMessage: _pwCollapseMessage,
                onSubmit: _handleUpdatePassword,
              ),
              const SizedBox(height: 16),
            ],

            WithdrawBox(onWithdraw: _handleWithdraw),
          ],
        ),
      ),
    );
  }
}

/// 다른 화면으로 넘어가는 줄 카드 (설정, 관리자 전용 통합 소요 기록 등)
class _LinkCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onPressed;

  const _LinkCard({required this.title, this.subtitle, required this.icon, required this.onPressed});

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
            border: Border.all(color: context.colors.outline),
          ),
          child: Row(
            children: [
              Icon(icon, color: context.colors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.colors.textPrimary)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                    ],
                  ],
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