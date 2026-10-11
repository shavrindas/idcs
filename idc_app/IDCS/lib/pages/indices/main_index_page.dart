import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/indices/main_index/main_index_components.dart';
import 'package:idcs/components/shared/alarm_row.dart';
import 'package:idcs/services/common/alarm/alarm_api_service.dart';
import 'package:idcs/services/common/facility_api_service.dart';
import 'package:idcs/services/common/facility_shortcut.dart';
import 'package:idcs/services/common/user_api_service.dart';
import '../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';

class MainIndexPage extends StatefulWidget {
  final String userId;

  const MainIndexPage({super.key, required this.userId});

  @override
  State<MainIndexPage> createState() => _MainIndexPageState();
}

class _MainIndexPageState extends State<MainIndexPage> {
  bool _isAdmin = false;
  bool _isLoading = true;

  /// Set once this screen has handed over to a sole facility.
  bool _jumped = false;
  List<FacilitySummary> _facilities = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // 1. 유저 데이터(권한 등)를 불러오는 초기화 함수
  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true; // 로딩 상태 활성화
    });

    try {
      final role = await UserApiService.getUserRole(widget.userId);
      final facilities = await FacilityApiService.getFacilities(widget.userId);
      final summaries = await _buildSummaries(facilities);
      if (!mounted) return;
      setState(() {
        // ADMIN이거나 DEVELOPER인 경우 관리자 박스 노출
        _isAdmin = (role == 'ADMIN' || role == 'DEVELOPER');
        _facilities = summaries;
      });
      _maybeOpenOnlyFacility(summaries);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.permissionLoadFailed(describeApiError(context, e)))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // 로딩 상태 해제
        });
      }
    }
  }

  /// With a single facility, the 내 시설 list is a one-item screen the user has to
  /// tap through every time, so open that facility straight away — on launch and
  /// whenever 홈 is opened again.
  ///
  /// It uses `go`, not `push`: the stack is replaced, so back from the facility
  /// leaves the app instead of returning here and bouncing straight back in.
  /// The facility shell then carries the only way to 내 정보, which is why
  /// [FacilityShortcut.isSoleFacility] is set before navigating.
  void _maybeOpenOnlyFacility(List<FacilitySummary> summaries) {
    final sole = summaries.length == 1;
    FacilityShortcut.markSoleFacility(sole);
    if (!sole || _jumped || !mounted) return;
    // Guard against a second jump from pull-to-refresh on this same screen.
    _jumped = true;
    context.go('/facility/${widget.userId}/${summaries.first.id}/monitoring');
  }

  /// Combines the facility list with the user's alarms and each facility's room
  /// count, so a card can show real state instead of just a name.
  ///
  /// The alarm list covers every facility the user belongs to, so one request is
  /// enough; room counts need one request per facility and are fetched in
  /// parallel. A failed room request only drops that one count — the card still
  /// renders, since the alarm state matters more than the room total.
  Future<List<FacilitySummary>> _buildSummaries(List<dynamic> facilities) async {
    final activeCounts = <int, int>{};
    try {
      final alarms = await AlarmApiService.getUserAlarms(widget.userId);
      for (final alarm in alarms.where(isAlarmActive)) {
        final facilityId = alarm['facility_id'];
        if (facilityId is int) {
          activeCounts[facilityId] = (activeCounts[facilityId] ?? 0) + 1;
        }
      }
    } catch (_) {
      // Leave the counts empty; cards then read as 정상 rather than blocking the screen.
    }

    final roomCounts = await Future.wait(
      facilities.map((fac) async {
        try {
          final rooms = await FacilityApiService.getFacilityRooms(fac['id'].toString());
          return rooms.length;
        } catch (_) {
          return null;
        }
      }),
    );

    return [
      for (var i = 0; i < facilities.length; i++)
        FacilitySummary(
          id: facilities[i]['id'],
          name: facilities[i]['name'] ?? '',
          roomCount: roomCounts[i],
          activeAlarmCount: activeCounts[facilities[i]['id']] ?? 0,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.facilitiesTitle),
        actions: [
          // 관리자는 웹 콘솔에서 시설을 관리하므로, 코드 등록은 일반 유저에게만 노출
          if (!_isAdmin)
            IconButton(
              icon: const Icon(Icons.add_business_outlined),
              tooltip: context.l10n.facilityRegister,
              onPressed: () => context.push('/facility_register/${widget.userId}'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // 데이터 로딩 중 처리
          : RefreshIndicator(
              onRefresh: _fetchUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: FacilitySummaryList(
                  facilities: _facilities,
                  onFacilityPressed: (facilityId) {
                    // 터치 시 시설 라우팅용 nav 페이지로 이동
                    context.push('/facility/${widget.userId}/$facilityId/monitoring');
                  },
                ),
              ),
            ),
    );
  }
}
