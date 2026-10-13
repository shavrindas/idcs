// 경로: lib/pages/common/signup_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/common/signup/signup_components.dart';
import 'package:idcs/services/common/signup/auth_api_service.dart';
import 'package:idcs/services/common/social_auth_service.dart';
import '../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/components/shared/app_toast.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// 비밀번호를 한 번 더 받는다. 오타가 나면 계정이 그대로 잠기는데, 지금은
  /// 비밀번호 재설정도 서버에서 열려 있지 않아 되돌릴 방법이 없다.
  final TextEditingController _passwordConfirmController = TextEditingController();

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
    _passwordConfirmController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _fallbackEmailController.dispose();
    super.dispose();
  }

  /// 너무 짧은 비밀번호를 막는 최소 길이. 서버가 따로 규칙을 두고 있지 않아
  /// 여기서만 거른다.
  static const int _minPasswordLength = 8;

  /// 완전한 이메일 검증은 보내 봐야 알 수 있다. 여기서는 오타로 흔한
  /// '@ 가 없다' / '점이 없다' 정도만 걸러 헛걸음을 줄인다.
  static bool _looksLikeEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

  // API 연동: 일반 계정 생성 처리
  Future<void> _handleGeneralSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    final l10n = context.l10n;

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      AppToast.warning(context, l10n.signupMissingFields);
      return;
    }

    // 서버에 다녀와서야 알게 되는 것들을 먼저 거른다. 특히 비밀번호 오타는
    // 서버가 잡아 줄 수 없다.
    if (!_looksLikeEmail(email)) {
      AppToast.warning(context, l10n.signupEmailInvalid);
      return;
    }
    if (password.length < _minPasswordLength) {
      AppToast.warning(context, l10n.signupPasswordTooShort(_minPasswordLength));
      return;
    }
    if (password != _passwordConfirmController.text.trim()) {
      AppToast.warning(context, l10n.signupPasswordMismatch);
      return;
    }

    try {
      await AuthApiService.signupGeneral(
        email: email,
        password: password,
        name: name,
        phoneNumber: phone,
      );

      // The await above may have outlived this screen.
      if (!mounted) return;
      // 서버가 내려주는 문구는 한국어로 고정돼 있어, 앱을 영어로 쓰는 사람에게도
      // 한국어가 그대로 떴다. 결과가 정해져 있는 자리는 앱이 제 말로 알린다.
      AppToast.success(context, l10n.signupSuccess);
      // 가입 성공 시 로그인 페이지로 이동
      context.go('/login');
    } catch (e) {
      // The await above may have outlived this screen.
      if (!mounted) return;
      AppToast.error(context, describeApiError(context, e));
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
      AppToast.error(context, describeApiError(context, e));
    }
  }

  // API 연동: 애플 폴백 박스(Box 3)에서 직접 입력 완료 시 실행
  Future<void> _handleAppleFallbackSubmit() async {
    final email = _fallbackEmailController.text.trim();
    if (email.isEmpty) {
      AppToast.warning(context, context.l10n.signupEmailRequired);
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
      await AuthApiService.signupSocial(
        provider: provider,
        providerId: providerId,
        email: email,
        name: name,
      );

      // The await above may have outlived this screen.
      if (!mounted) return;
      AppToast.success(context, context.l10n.signupSuccess);
      context.go('/login');
    } catch (e) {
      // The await above may have outlived this screen.
      if (!mounted) return;
      AppToast.error(context, describeApiError(context, e));
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
                passwordConfirmController: _passwordConfirmController,
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