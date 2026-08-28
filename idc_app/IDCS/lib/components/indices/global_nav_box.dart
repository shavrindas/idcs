import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/common/opening/open_nav.dart';
import 'package:idcs/services/common/user_api_service.dart';
import 'package:idcs/main.dart'; // AuthService 접근용
import 'package:idcs/theme/app_theme.dart';

class GlobalNavigationBox extends StatefulWidget {
  final String userId;
  final bool isAdmin;
  final VoidCallback onStateInitialize;

  const GlobalNavigationBox({
    super.key,
    required this.userId,
    required this.isAdmin,
    required this.onStateInitialize,
  });

  @override
  State<GlobalNavigationBox> createState() => _GlobalNavigationBoxState();
}

class _GlobalNavigationBoxState extends State<GlobalNavigationBox> {
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final profile = await UserApiService.getUserProfile(widget.userId);
      if (mounted) {
        setState(() {
          _userName = profile['name'] ?? '알 수 없음';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _userName = '이름 조회 실패');
    }
  }

  void _handleLogout() {
    // 로그아웃 처리: 전역 상태 초기화 후 로그인 페이지로 이동
    AuthService.setUserId(null);
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 계정 정보 및 로그아웃 영역
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName.isEmpty ? '불러오는 중...' : _userName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    Text('ID ${widget.userId}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              TextButton(onPressed: _handleLogout, child: const Text('로그아웃')),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _SectionLabel('네비게이션'),
        const SizedBox(height: 10),

        NavigationBox(
          title: '계정 수정',
          icon: Icons.person_outline_rounded,
          onPressed: () => context.push('/personal/${widget.userId}'),
        ),
        const SizedBox(height: 8),
        NavigationBox(
          title: '설정',
          icon: Icons.settings_outlined,
          onPressed: () => context.push('/settings/${widget.userId}'),
        ),
        const SizedBox(height: 8),

        if (!widget.isAdmin) ...[
          NavigationBox(
            title: '시설 등록',
            icon: Icons.add_business_outlined,
            onPressed: () => context.push('/facility_register/${widget.userId}'),
          ),
          const SizedBox(height: 8),
        ],

        NavigationBox(
          title: '메인 색인',
          icon: Icons.dashboard_outlined,
          onPressed: () => context.push('/main_index/${widget.userId}'),
        ),
        const SizedBox(height: 8),

        NavigationBox(
          title: '알람',
          icon: Icons.notifications_none_rounded,
          onPressed: () => context.push('/main_alarm/${widget.userId}'),
        ),

        if (widget.isAdmin) ...[
          const SizedBox(height: 20),
          _SectionLabel('관리자', color: AppColors.primary),
          const SizedBox(height: 10),
          NavigationBox(
            title: '통합 소요 기록',
            icon: Icons.assignment_outlined,
            onPressed: () => context.push('/total_board/${widget.userId}'),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionLabel(this.text, {this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.4),
    );
  }
}
