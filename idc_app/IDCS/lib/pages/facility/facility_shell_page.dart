// 경로: lib/pages/facility/facility_shell_page.dart
// 명세: 시설 내부 5개 섹션(모니터링/차트/소요기록/메신저/알람)을 위한
//       하단 네비게이션 셸. 각 섹션은 독립된 라우트를 유지하며,
//       세부 화면(채팅방, 게시글 등)으로 이동할 때는 이 셸 위로 풀스크린 push된다.
//
//       go_router의 StatefulShellRoute는 브랜치마다 별도의 내부 Navigator를 두므로,
//       탭 루트 화면(모니터링/차트 등)의 AppBar가 자동으로 만들어주는 뒤로가기는
//       셸 바깥(유저 홈)이 아니라 그 브랜치 내부 스택만 본다 — 즉 셸에 처음 들어오면
//       뒤로 갈 방법이 전혀 없었다. 그래서 셸 자체에 "어느 시설에 들어와 있는지"와
//       "홈으로 돌아가기"를 보여주는 얇은 바를 하나 두고, 실제 라우터 pop을 호출한다.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/services/common/facility_api_service.dart';
import 'package:idcs/theme/app_theme.dart';

class FacilityShellPage extends StatefulWidget {
  final String userId;
  final String facilityId;
  final StatefulNavigationShell navigationShell;

  const FacilityShellPage({
    super.key,
    required this.userId,
    required this.facilityId,
    required this.navigationShell,
  });

  @override
  State<FacilityShellPage> createState() => _FacilityShellPageState();
}

class _FacilityShellPageState extends State<FacilityShellPage> {
  String? _facilityName;

  @override
  void initState() {
    super.initState();
    _loadFacilityName();
  }

  Future<void> _loadFacilityName() async {
    try {
      final facilities = await FacilityApiService.getFacilities(widget.userId);
      final match = facilities.firstWhere(
        (f) => f['id'].toString() == widget.facilityId,
        orElse: () => null,
      );
      if (mounted && match != null) {
        setState(() => _facilityName = match['name']);
      }
    } catch (_) {
      // 이름을 못 불러와도 시설 ID로 대체 표시하므로 별도 에러 처리는 생략
    }
  }

  void _backToHome() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/index/${widget.userId}/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: '내 시설 목록으로',
          onPressed: _backToHome,
        ),
        title: Text(_facilityName ?? '시설 ${widget.facilityId}'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
      ),
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) => widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sensors_outlined), selectedIcon: Icon(Icons.sensors_rounded), label: '모니터링'),
          NavigationDestination(icon: Icon(Icons.show_chart_rounded), label: '차트'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment_rounded), label: '소요기록'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: '메신저'),
          NavigationDestination(icon: Icon(Icons.notifications_none_rounded), selectedIcon: Icon(Icons.notifications_rounded), label: '알람'),
        ],
      ),
    );
  }
}
