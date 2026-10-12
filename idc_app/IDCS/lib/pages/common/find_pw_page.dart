// 경로: lib/pages/common/find_pw_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:idcs/services/common/find_pw/auth_api_service.dart';
import 'package:idcs/theme/app_theme.dart';
import '../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/components/shared/app_toast.dart';

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
          _box2Message = context.l10n.resetTimedOut;
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
      setState(() => _box1Message = describeApiError(context, e));
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
        _box2Message = context.l10n.resetCodeVerified;
        _timer?.cancel();
        _currentStep = 3; // Box 3 열기
      });
    } catch (e) {
      setState(() => _box2Message = describeApiError(context, e));
    }
  }

  // Box #3 제출 로직
  Future<void> _handlePasswordReset() async {
    final pw1 = _pwController.text;
    final pw2 = _pwConfirmController.text;

    if (pw1.isEmpty || pw2.isEmpty) return;
    if (pw1 != pw2) {
      setState(() => _box3Message = context.l10n.resetPasswordMismatch);
      return;
    }

    try {
      final res = await AuthApiService.resetPassword(_resetToken, pw1);
      // The await above may have outlived this screen.
      if (!mounted) return;
      AppToast.success(context, res['message']);
      context.go('/login'); // 완료 시 로그인 페이지 이동
    } catch (e) {
      setState(() => _box3Message = describeApiError(context, e));
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
              Text(context.l10n.resetPasswordTitle, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                context.l10n.resetPasswordSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),

              // Step #1: 이메일 입력
              _buildStepCard(
                step: 1,
                title: context.l10n.resetStepEmail,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInputRow(
                      icon: Icons.mail_outline_rounded,
                      hint: context.l10n.fieldEmail,
                      controller: _emailController,
                      isEnabled: _currentStep == 1,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _currentStep == 1 ? _handleEmailSubmit : null,
                      child: Text(context.l10n.resetSendCode),
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
                        title: context.l10n.resetStepCode,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInputRow(
                              icon: Icons.pin_outlined,
                              hint: context.l10n.fieldVerificationCode,
                              controller: _codeController,
                              isEnabled: _currentStep == 2,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 16, color: context.colors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  context.l10n.resetTimeLeft(_formatTime(_remainingSeconds)),
                                  style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _currentStep == 2 ? _handleCodeSubmit : null,
                              child: Text(context.l10n.resetVerifyCode),
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
                        title: context.l10n.resetStepNewPassword,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInputRow(
                              icon: Icons.lock_outline_rounded,
                              hint: context.l10n.fieldNewPassword,
                              controller: _pwController,
                              isObscure: _obscurePw,
                              onToggleObscure: () => setState(() => _obscurePw = !_obscurePw),
                            ),
                            const SizedBox(height: 10),
                            _buildInputRow(
                              icon: Icons.lock_outline_rounded,
                              hint: context.l10n.fieldConfirmPassword,
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
                              child: Text(context.l10n.resetPasswordTitle),
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
              tooltip: context.l10n.showPassword,
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
