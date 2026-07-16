import 'package:flutter/material.dart';
import 'package:idcs/components/indices/global_nav_box.dart';
import 'package:idcs/components/indices/account_edit/account_edit_components.dart';
import 'package:idcs/services/common/user_api_service.dart';

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
          _nameController.text = profile['name'];
          _phoneController.text = profile['phone_number'];
          _linkedProviders = profile['linked_providers'] ?? [];
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _handleUpdatePhone() async {
    try {
      final msg = await UserApiService.updatePhone(widget.userId, _phoneController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
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
      appBar: AppBar(title: const Text('계정 수정 페이지')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Box #1
            GlobalNavigationBox(
              userId: widget.userId,
              isAdmin: _isAdmin,
              onStateInitialize: _loadInitialData,
            ),
            const SizedBox(height: 16),

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

            // Box #4
            PasswordEditBox(
              currentPwController: _currentPwController,
              newPwController: _newPwController,
              collapseMessage: _pwCollapseMessage,
              onSubmit: _handleUpdatePassword,
            ),
            const SizedBox(height: 16),

            // Box #5
            SocialLinkBox(
              linkedProviders: _linkedProviders,
              onLinkPressed: _handleSocialLink,
            ),
          ],
        ),
      ),
    );
  }
}