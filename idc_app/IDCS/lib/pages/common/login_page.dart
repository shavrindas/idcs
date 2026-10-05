// ===============================================================
// 경로 : lib/pages/common/login_page.dart
// 명세 : 로그인 페이지
// ===============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:idcs/components/common/login/login_components.dart';
import 'package:idcs/main.dart';
import 'package:idcs/services/common/login/auth_api_service.dart';
import 'package:idcs/services/common/social_auth_service.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/theme/app_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 로그인 상태 유지 여부를 상위에서 관리
  bool _keepLogin = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // API 연동: 일반 로그인 처리
  Future<void> _handleGeneralLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 비밀번호를 모두 입력해주세요.')),
      );
      return;
    }

    try {
      final result = await AuthApiService.loginGeneral(
        email: email,
        password: password,
        keepLogin: _keepLogin,
      );

      // 1. AuthService에 발급받은 user_id 저장 (이 시점에 isLoggedIn이 true가 됨)
      final userId = result['user_id'];
      await AuthService.setUserId(userId, persist: _keepLogin);

      // [비동기 컨텍스트 방어 로직] 화면이 파괴되지 않았는지 확인
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );

      // 2. 메인 색인 페이지로 라우팅 (이제 리다이렉트에 걸리지 않고 정상 이동!)
      context.go('/index/$userId/home');

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // API 연동: 소셜 로그인 처리
  Future<void> _handleSocialLogin(String provider) async {
    try {
      Map<String, String>? socialData;

      if (provider == 'google') {
        socialData = await SocialAuthService.signInWithGoogle();
      } else if (provider == 'apple') {
        socialData = await SocialAuthService.signInWithApple();
      }

      if (socialData == null) {
        return; // 로그인 취소
      }

      // 백엔드로 소셜 로그인 API 호출
      final result = await AuthApiService.loginSocial(
        provider: socialData['provider']!,
        providerId: socialData['provider_id']!,
        keepLogin: _keepLogin,
      );

      final userId = result['user_id'];
      await AuthService.setUserId(userId, persist: _keepLogin);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );

      context.go('/index/$userId/home');

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppWordmark(fontSize: 17)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text('다시 만나서 반가워요', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                '계정 정보를 입력하고 로그인해주세요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              StandardLoginBox(
                emailController: _emailController,
                passwordController: _passwordController,
                onLoginPressed: _handleGeneralLogin,
              ),

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  KeepLoginStateBox(
                    isChecked: _keepLogin,
                    onChanged: (bool? value) {
                      setState(() {
                        _keepLogin = value ?? false;
                      });
                    },
                  ),
                  TextButton(
                    onPressed: () => context.push('/find_pw'),
                    child: const Text('비밀번호 찾기'),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              SocialLoginBox(
                onSocialLoginPressed: _handleSocialLogin,
              ),

              const SizedBox(height: 40),

              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '계정이 없으신가요? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.push('/signup'),
                      child: Text(
                        '회원가입',
                        style: TextStyle(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '  ·  ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.push('/find_id'),
                      child: Text(
                        '아이디 찾기',
                        style: TextStyle(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
