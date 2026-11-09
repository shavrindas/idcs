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
import 'package:idcs/components/shared/glass_nav_bar.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/services/common/user_api_service.dart';

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
  bool _canManageEmployees = false; // 권한 상태

  @override
  void initState() {
    super.initState();
    _loadFacilityData();
  }

  Future<void> _loadFacilityData() async {
    try {
      final facilities = await FacilityApiService.getFacilities(widget.userId);
      final match = facilities.firstWhere(
        (f) => f['id'].toString() == widget.facilityId,
        orElse: () => null,
      );

      final role = await UserApiService.getUserRole(widget.userId);
      final isAdmin = (role == 'ADMIN' || role == 'DEVELOPER');
      final isUserAdmin = match != null && match['user_admin_id']?.toString() == widget.userId;

      if (mounted) {
        setState(() {
          _facilityName = match?['name'];
          _canManageEmployees = isAdmin || isUserAdmin;
        });
      }
    } catch (_) {}
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
    final watching = widget.navigationShell.currentIndex == 0 &&
        MediaQuery.orientationOf(context) == Orientation.landscape;

    if (watching) {
      return Scaffold(body: widget.navigationShell);
    }

    // 기본 탭 4개 구성
    final List<GlassNavItem> navItems = [
      GlassNavItem(icon: Icons.sensors_outlined, selectedIcon: Icons.sensors_rounded, label: context.l10n.navMonitoring),
      GlassNavItem(icon: Icons.notifications_none_rounded, selectedIcon: Icons.notifications_rounded, label: context.l10n.navAlarm),
      GlassNavItem(icon: Icons.show_chart_rounded, label: context.l10n.navChart),
      GlassNavItem(icon: Icons.assignment_outlined, selectedIcon: Icons.assignment_rounded, label: context.l10n.navBoard),
    ];

    // 권한이 있으면 5번째 탭 추가
    if (_canManageEmployees) {
      navItems.add(
        GlassNavItem(icon: Icons.people_outline_rounded, selectedIcon: Icons.people_rounded, label: context.l10n.navEmployees)
      );
    }

    return Scaffold(
      appBar: AppBar(
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
        backgroundColor: null,
        foregroundColor: context.colors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: context.l10n.navMessenger,
            onPressed: () => context.push(
              '/facility_chat/${widget.userId}/${widget.facilityId}',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.l10n.settingsTitle,
            onPressed: () => context.push('/index/${widget.userId}/profile'),
          ),
        ],
      ),
      body: widget.navigationShell,
      extendBody: true,
      bottomNavigationBar: GlassNavBar(
        // 현재 라우터의 브랜치 인덱스가 탭 아이템 범위를 벗어나는 경우 방어 로직
        selectedIndex: widget.navigationShell.currentIndex < navItems.length 
            ? widget.navigationShell.currentIndex 
            : 0, 
        onSelected: (index) {
            // 선택된 탭 인덱스로 브랜치 전환
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
        },
        items: navItems,
      ),
    );
  }
}