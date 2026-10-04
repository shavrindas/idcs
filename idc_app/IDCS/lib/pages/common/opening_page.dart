// ===============================================================
// 경로 : lib/pages/common/opening_page.dart
// 명세 : 오프닝 페이지 (스플래시 / 환영 화면)
// ===============================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_logo.dart';

class OpeningPage extends StatelessWidget {
  const OpeningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 72),

              // 브랜드 로고
              const Center(child: AppMonogram(size: 92)),
              const SizedBox(height: 28),

              const Center(child: AppWordmark(fontSize: 26)),
              const SizedBox(height: 10),
              Text(
                '냉동창고 실시간 관제 · 모니터링 시스템',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 96),

              // 주요 액션
              ElevatedButton(
                onPressed: () => context.push('/login'),
                child: const Text('로그인'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/signup'),
                child: const Text('회원가입'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
