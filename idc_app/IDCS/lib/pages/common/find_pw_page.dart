// 경로: lib/pages/common/find_pw_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:idcs/services/common/find_pw/auth_api_service.dart';

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
      appBar: AppBar(title: const Text('비밀번호 찾기 페이지')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Box #1: 이메일 입력
            _buildBoxContainer(
              isActive: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInputRow('이메일 입력', _emailController, isEnabled: _currentStep == 1),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _currentStep == 1 ? _handleEmailSubmit : null,
                    child: const Text('버튼(submit) 연동 계정 확인하기'),
                  ),
                  if (_box1Message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_box1Message, style: const TextStyle(color: Colors.purple)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Box #2: 코드 입력 (AnimatedSize로 Collapse 효과 부여)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: _currentStep >= 2
                  ? _buildBoxContainer(
                isActive: _currentStep == 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInputRow('코드 입력', _codeController, isEnabled: _currentStep == 2),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _currentStep == 2 ? _handleCodeSubmit : null,
                      child: const Text('버튼(submit) 입력 코드 확인'),
                    ),
                    const SizedBox(height: 8),
                    Text('남은 시간: ${_formatTime(_remainingSeconds)}',
                        style: const TextStyle()),
                    if (_box2Message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(_box2Message, style: const TextStyle()),
                      ),
                  ],
                ),
              )
                  : const SizedBox.shrink(), // 단계가 아니면 보이지 않음
            ),
            SizedBox(height: _currentStep >= 2 ? 16 : 0),

            // Box #3: 새 비밀번호 입력
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: _currentStep >= 3
                  ? _buildBoxContainer(
                isActive: _currentStep == 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInputRow('새 비밀번호', _pwController, isObscure: true),
                    const SizedBox(height: 8),
                    _buildInputRow('재입력', _pwConfirmController, isObscure: true),
                    const SizedBox(height: 12),
                    if (_box3Message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(_box3Message, style: const TextStyle()),
                      ),
                    ElevatedButton(
                      onPressed: _handlePasswordReset,
                      child: const Text('버튼(submit) 비밀번호 다시 설정하기'),
                    ),
                  ],
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // 공통 UI 빌더 헬퍼
  Widget _buildBoxContainer({required Widget child, required bool isActive}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
      ),
      padding: const EdgeInsets.all(12.0),
      // 비활성 박스는 반투명 처리
      child: Opacity(opacity: isActive ? 1.0 : 0.5, child: child),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller, {bool isObscure = false, bool isEnabled = true}) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13))),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            enabled: isEnabled,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}