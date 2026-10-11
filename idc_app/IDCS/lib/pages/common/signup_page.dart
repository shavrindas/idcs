// 경로: lib/pages/common/signup_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/common/signup/signup_components.dart';
import 'package:idcs/services/common/signup/auth_api_service.dart';
import 'package:idcs/services/common/social_auth_service.dart';
import '../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // --- Box 3 (애플 폴백) 관련 상태 변수 ---
  bool _showAppleFallback = false;
  String _pendingAppleProviderId = '';
  String _pendingAppleName = '';
  final TextEditingController _fallbackEmailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // API 연동: 일반 계정 생성 처리
  Future<void> _handleGeneralSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.signupMissingFields)),
      );
      return;
    }

    try {
      final result = await AuthApiService.signupGeneral(
        email: email,
        password: password,
        name: name,
        phoneNumber: phone,
      );

      // The await above may have outlived this screen.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      // 가입 성공 시 로그인 페이지로 이동
      context.go('/login');
    } catch (e) {
      // The await above may have outlived this screen.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeApiError(context, e))),
      );
    }
  }

  // API 연동: 소셜 계정 생성 처리
  Future<void> _handleSocialSignup(String provider) async {
    // Read before awaiting: context may no longer be valid further down.
    final l10n = context.l10n;
    try {
      Map<String, String>? socialData;

      if (provider == 'google') {
        socialData = await SocialAuthService.signInWithGoogle();
      } else if (provider == 'apple') {
        socialData = await SocialAuthService.signInWithApple();
      }

      if (socialData == null) return;

      // 이메일 누락 방어 로직 (Box 3 트리거)
      if (socialData['email'] == null || socialData['email']!.isEmpty) {
        if (provider == 'apple') {
          setState(() {
            _showAppleFallback = true; // Box 3 열기
            _pendingAppleProviderId = socialData!['provider_id']!;
            _pendingAppleName = socialData['name']!.isEmpty ? l10n.appleDefaultName : socialData['name']!;
          });
          return; // 여기서 흐름을 멈추고 유저의 수동 입력을 기다립니다.
        } else {
          throw Exception(l10n.signupEmailUnavailable);
        }
      }

      // 정상적으로 이메일이 있는 경우 바로 통신
      await _submitSocialSignup(
        provider: socialData['provider']!,
        providerId: socialData['provider_id']!,
        email: socialData['email']!,
        name: socialData['name']!.isEmpty
            ? (socialData['provider'] == 'apple' ? l10n.appleDefaultName : l10n.googleDefaultName)
            : socialData['name']!,
      );

    } catch (e) {
      // The await above may have outlived this screen.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeApiError(context, e))));
    }
  }

  // API 연동: 애플 폴백 박스(Box 3)에서 직접 입력 완료 시 실행
  Future<void> _handleAppleFallbackSubmit() async {
    final email = _fallbackEmailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.signupEmailRequired)),
      );
      return;
    }

    await _submitSocialSignup(
      provider: 'apple',
      providerId: _pendingAppleProviderId,
      email: email,
      name: _pendingAppleName,
    );
  }

  // 중복되는 소셜 통신 로직 분리
  Future<void> _submitSocialSignup({
    required String provider,
    required String providerId,
    required String email,
    required String name
  }) async {
    try {
      final result = await AuthApiService.signupSocial(
        provider: provider,
        providerId: providerId,
        email: email,
        name: name,
      );

      // The await above may have outlived this screen.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      context.go('/login');
    } catch (e) {
      // The await above may have outlived this screen.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeApiError(context, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(context.l10n.signupTitle, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                context.l10n.signupSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              StandardSignupBox(
                emailController: _emailController,
                passwordController: _passwordController,
                nameController: _nameController,
                phoneController: _phoneController,
                onSignupPressed: _handleGeneralSignup, // 기존 로직
              ),
              const SizedBox(height: 20),

              SocialSignupBox(
                onSocialSignupPressed: _handleSocialSignup,
              ),

              // Box #3: _showAppleFallback이 true일 때만 화면에 노출됨
              if (_showAppleFallback) ...[
                const SizedBox(height: 16),
                AppleEmailFallbackBox(
                  fallbackEmailController: _fallbackEmailController,
                  onSubmit: _handleAppleFallbackSubmit,
                  onCancel: () {
                    setState(() {
                      _showAppleFallback = false; // 취소 시 다시 닫음
                      _fallbackEmailController.clear();
                    });
                  },
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}