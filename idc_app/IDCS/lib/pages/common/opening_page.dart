// ===============================================================
// 경로 : lib/pages/common/opening_page.dart
// 명세 : 오프닝 페이지 (스플래시 / 환영 화면)
// ===============================================================
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';

import 'package:idcs/components/common/opening/open_nav.dart';
import 'package:idcs/components/common/opening/open_inj_static.dart';
import 'package:idcs/components/common/opening/open_inj_text.dart';

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
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.ac_unit_rounded, color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'IDCool Systems',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
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

              // 개발자 전용 도구 (디버그 빌드에서만 노출)
              if (kDebugMode) const _DeveloperToolsPanel(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeveloperToolsPanel extends StatefulWidget {
  const _DeveloperToolsPanel();

  @override
  State<_DeveloperToolsPanel> createState() => _DeveloperToolsPanelState();
}

class _DeveloperToolsPanelState extends State<_DeveloperToolsPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18),
          label: const Text('개발자 도구 (DEBUG 전용)'),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          AuthInjectionBox(
            title: '권한 주입 계정(admin)',
            userIdToInject: 1,
          ),
          const SizedBox(height: 12),
          AuthInjectionBox(
            title: '권한 주입 계정(user_4)',
            userIdToInject: 4,
          ),
          const SizedBox(height: 12),
          const CustomAuthInjectionBox(),
          const SizedBox(height: 12),
          NavigationBox(
            title: '시설 목록 페이지로 이동',
            onPressed: () => context.push('/facilities_list/${AuthService.getCurrentUserId()}'),
          ),
        ],
      ],
    );
  }
}
