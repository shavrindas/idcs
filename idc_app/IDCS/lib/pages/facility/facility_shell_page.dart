// 경로: lib/pages/facility/facility_shell_page.dart
// 명세: 시설 내부 5개 섹션(모니터링/차트/소요기록/메신저/알람)을 위한
//       하단 네비게이션 셸. 각 섹션은 독립된 라우트를 유지하며,
//       세부 화면(채팅방, 게시글 등)으로 이동할 때는 이 셸 위로 풀스크린 push된다.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FacilityShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const FacilityShellPage({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
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
