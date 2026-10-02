// 경로: lib/pages/common/find_pw_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:idcs/services/common/find_pw/auth_api_service.dart';
import 'package:idcs/theme/app_theme.dart';

class FindPwPage extends StatefulWidget {
  const FindPwPage({super.key});

  @override
  State<FindPwPage> createState() => _FindPwPageState();
}

class _FindPwPageState extends State<FindPwPage> {
  // 단계 제어 (1: 이메일, 2: 코드 입력, 3: 새 비밀번호 설정)
  int _currentStep = 1;

  // 상태 변수
  String _jwtToken = '';       // Box 1에서 발급받은 코드 확인용 JWT
  String _resetToken = '';     // Box 2에서 발급받은 비밀번호 변경용 JWT
  String _box1Message = '';
  String _box2Message = '';
  String _box3Message = '';

  // 컨트롤러
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _pwController = TextEditingController();
  final _pwConfirmController = TextEditingController();

  bool _obscurePw = true;
  bool _obscurePwConfirm = true;

  // 타이머 관련
  Timer? _timer;
  int _remainingSeconds = 300; // 5분

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _pwController.dispose();
    _pwConfirmController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = 300;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _box2Message = '입력 시간이 초과되었습니다.';
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // Box #1 제출 로직
  Future<void> _handleEmailSubmit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    try {
      final res = await AuthApiService.requestPasswordCode(email);
      setState(() {
        _jwtToken = res['token'];
        // 개발용 콘솔에만 찍히도록 백엔드에서 준 dev_code 표시 가능 (테스트용)
        _box1Message = res['message'] + " (Test Code: ${res['dev_code']})";
        _currentStep = 2; // Box 2 열기
      });
      _startTimer();
    } catch (e) {
      setState(() => _box1Message = e.toString());
    }
  }

  // Box #2 제출 로직
  Future<void> _handleCodeSubmit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _remainingSeconds <= 0) return;

    try {
      final res = await AuthApiService.verifyPasswordCode(_jwtToken, code);
      setState(() {
        _resetToken = res['reset_token'];
        _box2Message = '코드 인증 성공!';
        _timer?.cancel();
        _currentStep = 3; // Box 3 열기
      });
    } catch (e) {
      setState(() => _box2Message = e.toString());
    }
  }

  // Box #3 제출 로직
  Future<void> _handlePasswordReset() async {
    final pw1 = _pwController.text;
    final pw2 = _pwConfirmController.text;

    if (pw1.isEmpty || pw2.isEmpty) return;
    if (pw1 != pw2) {
      setState(() => _box3Message = '비밀번호가 일치하지 않습니다.');
      return;
    }

    try {
      final res = await AuthApiService.resetPassword(_resetToken, pw1);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      context.go('/login'); // 완료 시 로그인 페이지 이동
    } catch (e) {
      setState(() => _box3Message = e.toString());
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
              Text('비밀번호 재설정', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                '이메일 인증 후 새 비밀번호를 설정해주세요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),

              // Step #1: 이메일 입력
              _buildStepCard(
                step: 1,
                title: '이메일 인증',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInputRow(
                      icon: Icons.mail_outline_rounded,
                      hint: '이메일',
                      controller: _emailController,
                      isEnabled: _currentStep == 1,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _currentStep == 1 ? _handleEmailSubmit : null,
                      child: const Text('인증 코드 받기'),
                    ),
                    if (_box1Message.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildMessage(_box1Message),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Step #2: 코드 입력
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: _currentStep >= 2
                    ? _buildStepCard(
                        step: 2,
                        title: '인증 코드 입력',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInputRow(
                              icon: Icons.pin_outlined,
                              hint: '인증 코드',
                              controller: _codeController,
                              isEnabled: _currentStep == 2,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 16, color: context.colors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  '남은 시간 ${_formatTime(_remainingSeconds)}',
                                  style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _currentStep == 2 ? _handleCodeSubmit : null,
                              child: const Text('코드 확인'),
                            ),
                            if (_box2Message.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _buildMessage(_box2Message),
                            ],
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              SizedBox(height: _currentStep >= 2 ? 16 : 0),

              // Step #3: 새 비밀번호 입력
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: _currentStep >= 3
                    ? _buildStepCard(
                        step: 3,
                        title: '새 비밀번호 설정',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInputRow(
                              icon: Icons.lock_outline_rounded,
                              hint: '새 비밀번호',
                              controller: _pwController,
                              isObscure: _obscurePw,
                              onToggleObscure: () => setState(() => _obscurePw = !_obscurePw),
                            ),
                            const SizedBox(height: 10),
                            _buildInputRow(
                              icon: Icons.lock_outline_rounded,
                              hint: '비밀번호 재입력',
                              controller: _pwConfirmController,
                              isObscure: _obscurePwConfirm,
                              onToggleObscure: () => setState(() => _obscurePwConfirm = !_obscurePwConfirm),
                            ),
                            if (_box3Message.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _buildMessage(_box3Message),
                            ],
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _handlePasswordReset,
                              child: const Text('비밀번호 재설정'),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // 단계 카드 공통 UI
  Widget _buildStepCard({required int step, required String title, required Widget child}) {
    final bool isActive = step == _currentStep;
    final bool isDone = step < _currentStep;

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isActive ? context.colors.primary : context.colors.outline, width: isActive ? 1.4 : 1),
      ),
      child: Opacity(
        opacity: isActive || isDone ? 1.0 : 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _StepBadge(isActive: isActive, isDone: isDone, number: step),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Text(
      message,
      style: TextStyle(color: context.colors.primary, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
    );
  }

  Widget _buildInputRow({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    bool isEnabled = true,
    bool? isObscure,
    VoidCallback? onToggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure ?? false,
      enabled: isEnabled,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: onToggleObscure == null
            ? null
            : IconButton(
              tooltip: '비밀번호 표시',
                icon: Icon(
                  isObscure! ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: context.colors.textSecondary,
                ),
                onPressed: onToggleObscure,
              ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final bool isActive;
  final bool isDone;
  final int number;

  const _StepBadge({required this.isActive, required this.isDone, required this.number});

  @override
  Widget build(BuildContext context) {
    final Color background = isDone
        ? context.colors.primary
        : isActive
            ? context.colors.primary
            : context.colors.outline;

    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: isDone
          ? Icon(Icons.check, size: 14, color: context.colors.onPrimary)
          : Text(
              '$number',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? context.colors.onPrimary : context.colors.textSecondary,
              ),
            ),
    );
  }
}
