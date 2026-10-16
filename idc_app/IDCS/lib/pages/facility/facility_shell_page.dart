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
import 'package:idcs/services/common/facility_shortcut.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/l10n/l10n_context.dart';

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
    // 모니터링 탭을 눕히면 호실 하나를 지켜보는 화면이 된다. 가로 높이는
    // 세로의 절반도 안 되는데 앱바와 탭 줄이 그중 3분의 1을 먹어서, 정작
    // 멀리서 읽으라고 키운 숫자가 들어갈 자리가 없다. 그 화면에서만 걷어낸다.
    // 차트·소요기록·알람은 가로에서도 평소대로 둔다 — 그쪽은 눕혀도 하는 일이
    // 달라지지 않으니 길을 없애면 갇힌다.
    final watching = widget.navigationShell.currentIndex == 0 &&
        MediaQuery.orientationOf(context) == Orientation.landscape;

    if (watching) {
      return Scaffold(body: widget.navigationShell);
    }

    return Scaffold(
      appBar: AppBar(
        // 시설이 하나뿐인 계정은 이 셸이 홈이라 돌아갈 목록이 없다. 대신 그 경우에만
        // 내 정보로 가는 버튼을 둔다 — 없으면 설정·로그아웃에 닿을 길이 사라진다.
        leading: FacilityShortcut.isSoleFacility
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: context.l10n.backToFacilities,
                onPressed: _backToHome,
              ),
        automaticallyImplyLeading: false,
        title: Text(_facilityName ?? context.l10n.facilityFallbackName(widget.facilityId)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        actions: [
          // 메신저와 내 정보는 아래 탭이 아니라 여기에 둔다. 아래 네 칸은
          // '설비를 본다'는 한 가지 일로 묶이고, 이 둘은 그 일과 상관없이
          // 언제든 열리는 화면이다.
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: context.l10n.navMessenger,
            onPressed: () => context.push(
              '/facility_chat/${widget.userId}/${widget.facilityId}',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: context.l10n.profileTitle,
            onPressed: () => context.push('/index/${widget.userId}/profile'),
          ),
        ],
      ),
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) => widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(icon: Icon(Icons.sensors_outlined), selectedIcon: Icon(Icons.sensors_rounded), label: context.l10n.navMonitoring),
          NavigationDestination(icon: Icon(Icons.show_chart_rounded), label: context.l10n.navChart),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment_rounded), label: context.l10n.navBoard),
          NavigationDestination(icon: Icon(Icons.notifications_none_rounded), selectedIcon: Icon(Icons.notifications_rounded), label: context.l10n.navAlarm),
        ],
      ),
    );
  }
}
