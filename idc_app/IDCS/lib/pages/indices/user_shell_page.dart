// 경로: lib/pages/indices/user_shell_page.dart
// 명세: 유저(시설 미선택) 레벨 3개 섹션(홈/알람/내 정보)을 위한 하단 네비게이션 셸.
//       각 탭 화면 안에 반복해서 내비게이션 목록을 넣던 기존 방식(GlobalNavigationBox)을
//       대체한다. 시설 등록/통합 소요기록처럼 자주 쓰지 않는 화면은 탭이 아니라
//       해당 탭 콘텐츠 안의 버튼으로 진입하는 풀스크린 push 화면으로 유지한다.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/l10n/l10n_context.dart';

class UserShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const UserShellPage({super.key, required this.navigationShell});

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
        destinations: [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: context.l10n.navHome),
          // 개괄 모니터링. 설민이 추가한 탭을 번역해서 가져왔다. 아이콘은
          // '내 정보' 와 같은 사람 모양이었는데, 탭 두 개가 같은 그림이면
          // 어느 쪽인지 알 수 없어 여러 칸이 보이는 모양으로 바꿨다.
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: context.l10n.navOverview),
          NavigationDestination(icon: Icon(Icons.notifications_none_rounded), selectedIcon: Icon(Icons.notifications_rounded), label: context.l10n.navAlarm),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: context.l10n.profileTitle),
        ],
      ),
    );
  }
}
