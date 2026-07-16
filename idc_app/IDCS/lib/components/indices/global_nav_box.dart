import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/common/opening/open_nav.dart';
import 'package:idcs/services/common/user_api_service.dart';
import 'package:idcs/main.dart'; // AuthService 접근용

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
  String _userName = '로딩중...';

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
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // [추가] 계정 정보 및 로그아웃 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '로그인 정보 : ID ${widget.userId} / $_userName',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent),
                ),
              ),
              ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                child: const Text('로그아웃', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const Divider(color: Colors.grey, height: 24),

          const Text(
            '네비게이션',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          const SizedBox(height: 12),

          NavigationBox(
              title: '계정 수정 페이지로 이동',
              onPressed: () => context.push('/personal/${widget.userId}')
          ),
          const SizedBox(height: 8),
          NavigationBox(
              title: '설정 페이지로 이동',
              onPressed: () => context.push('/settings/${widget.userId}')
          ),
          const SizedBox(height: 8),

          if (!widget.isAdmin) ...[
            NavigationBox(
                title: '시설 등록 페이지로 이동',
                onPressed: () => context.push('/facility_register/${widget.userId}')
            ),
            const SizedBox(height: 8),
          ],

          NavigationBox(
              title: '메인 색인 페이지로 이동',
              onPressed: widget.onStateInitialize
          ),
          const SizedBox(height: 8),
          NavigationBox(
              title: '메인 알람 페이지로 이동',
              onPressed: () => context.push('/main_alarm/${widget.userId}')
          ),

          if (widget.isAdmin) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.purpleAccent, width: 2),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NavigationBox(
                      title: '통합 소요 기록 페이지로 이동',
                      onPressed: () => context.push('/total_board/${widget.userId}')
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'collapse 출력 : (대상 : 관리자 계정)',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}