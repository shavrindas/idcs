// ===============================================================
// 경로: lib/pages/facility/chart/facility_chart_page.dart
// ===============================================================
import 'package:flutter/material.dart';
import 'package:idcs/components/facility/chart/chart_components.dart';
import 'package:idcs/components/facility/monitoring/device_labels.dart';
import 'package:idcs/components/facility/chart/chart_limits_dialog.dart';
import 'package:idcs/services/chart/chart_api_service.dart';
import 'package:idcs/services/chart/chart_limits.dart';
import 'package:idcs/services/common/facility_api_service.dart';
import '../../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/components/shared/app_toast.dart';

class FacilityChartPage extends StatefulWidget {
  final String userId;
  final String facilityId;

  const FacilityChartPage({super.key, required this.userId, required this.facilityId});

  @override
  State<FacilityChartPage> createState() => _FacilityChartPageState();
}

class _FacilityChartPageState extends State<FacilityChartPage> {
  // 1. 필터 상태 (dataType 완전 제거)
  String _currentScale = '5m';
  String _currentTimeRange = '1d';

  // 2. 조회 대상 호실 상태
  List<dynamic> _rooms = [];
  int? _selectedRoomId;

  /// 이 기기에 직접 적어 둔 기준값 (role_name -> 상·하한).
  /// 서버 포인트 롤의 상·하한이 비어 있는 동안 차트 기준선을 그리는 데 쓴다.
  Map<String, RoleLimit> _manualLimits = {};

  /// 호실의 전체 포인트 롤.
  ///
  /// 맵핑 그룹(웹 어드민이 만든 시설-호실-포인트롤 묶음)은 앱에서는 쓰지
  /// 않는다 — 온도가 아닌 제어·설정 롤까지 섞여 들어와 "기록 없음" 항목만
  /// 늘어나던 문제가 있었다. 앱은 그 호실의 [temp_] 로 시작하는 롤만 걸러
  /// 쓴다.
  List<dynamic> _roles = [];

  /// 실제로 차트에 그릴 롤. 온도 롤 중 읽을 수 있는 개수까지 자동으로 채워지고,
  /// 개별로 끄고 켤 수 있다.
  Set<int> _visibleRoleIds = {};

  // 4. 차트 렌더링 상태
  bool _isLoading = false;
  Map<String, dynamic>? _chartData;
  bool _showTargetLines = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  // 0단계: 시설의 호실 목록 조회 후 첫 호실을 기본 선택한다.
  // (예전에는 호실이 1번으로 고정되어 있어 1번 호실이 없는 시설에서는 차트가 아예 뜨지 않았다)
  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);

    try {
      final rooms = await FacilityApiService.getFacilityRooms(widget.facilityId);

      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _selectedRoomId = rooms.isEmpty
            ? null
            : (rooms.first['id'] is int
                ? rooms.first['id']
                : int.tryParse(rooms.first['id'].toString()));
      });

      if (_selectedRoomId != null) {
        await _loadRolesAndChart();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, context.l10n.roomQueryFailed(describeApiError(context, e)));
        setState(() => _isLoading = false);
      }
    }
  }

  /// role_name이 "temp_"로 시작하는 롤만 걸러낸다 — 앱 차트가 보여줄 대상은
  /// 이것뿐이다.
  List<dynamic> get _tempRoles => _roles
      .where((r) => (r['role_name']?.toString() ?? '').toLowerCase().startsWith('temp_'))
      .toList();

  Set<int> _tempRoleIds() => _tempRoles
      .map((r) => r['role_id'] is int ? r['role_id'] as int : int.tryParse(r['role_id'].toString()))
      .whereType<int>()
      .toSet();

  // 1단계: 호실의 포인트 롤 조회 후 온도 롤만 추려 자동 선택
  Future<void> _loadRolesAndChart() async {
    final int? roomId = _selectedRoomId;
    if (roomId == null) return;

    setState(() => _isLoading = true);

    try {
      final facilityId = int.parse(widget.facilityId);
      final roles = await ChartApiService.getPointRoles(facilityId, roomId);

      if (mounted) {
        setState(() {
          _roles = roles;
          // 읽을 수 있는 개수까지만 온도 롤을 자동으로 켠다.
          _visibleRoleIds = _cappedAuto(_tempRoleIds());
        });

        if (_visibleRoleIds.isNotEmpty) {
          await _fetchChartData();
        } else {
          setState(() {
            _chartData = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, context.l10n.groupLoadFailed(describeApiError(context, e)));
        setState(() => _isLoading = false);
      }
    }
  }

  /// 자동 선택에서 먼저 집을 항목.
  ///
  /// 차트를 여는 이유는 대부분 "온도가 어땠나" 하나다. 등록 순서대로 앞에서
  /// 자르면 이름순으로 앞에 오는 제어 플래그(control_cffan1 …)만 켜져, 정작
  /// 보려던 고내온도가 빠진 차트가 열린다.
  static const List<String> _autoPriority = [
    'temp_pv',
    'temp_sv',
    'temp_hey',
    'equipment_temp1',
    'equipment_press1',
    'equipment_press2',
    'inverter_hz',
    'inverter_kw',
  ];

  /// 자동으로 켤 항목을 읽을 수 있는 개수까지만 줄인다.
  ///
  /// 웹 어드민에서 만든 그룹에는 호실의 롤이 50개 넘게 묶여 있는 경우가 있다.
  /// 그대로 그리면 차트가 실오라기 뭉치가 되어 아무것도 읽히지 않는다.
  /// 위 우선순위를 먼저 채우고, 모자라면 호실의 롤 순서(= 등록 순서)로 메운다
  /// — Set 의 순서에 기대면 같은 그룹을 다시 열 때마다 다른 선이 뜰 수 있다.
  Set<int> _cappedAuto(Set<int> ids) {
    if (ids.length <= readableSeriesLimit) return ids;

    final candidates = _roles.where((r) {
      final id = r['role_id'] is int ? r['role_id'] as int : int.tryParse(r['role_id'].toString());
      return id != null && ids.contains(id);
    }).toList();

    // 롤 목록을 못 받은 경우에도 개수는 지킨다.
    if (candidates.isEmpty) return ids.take(readableSeriesLimit).toSet();

    int rank(dynamic role) {
      final index = _autoPriority.indexOf(role['role_name']?.toString() ?? '');
      return index == -1 ? _autoPriority.length : index;
    }

    // 같은 순위끼리는 원래 순서를 지켜야 하므로 안정 정렬이 필요하다. Dart 의
    // List.sort 는 안정성을 보장하지 않아, 원래 위치를 2차 기준으로 넣는다.
    final indexed = [for (var i = 0; i < candidates.length; i++) (i, candidates[i])];
    indexed.sort((a, b) {
      final byRank = rank(a.$2).compareTo(rank(b.$2));
      return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
    });

    return indexed
        .take(readableSeriesLimit)
        .map((e) => e.$2['role_id'] is int
            ? e.$2['role_id'] as int
            : int.parse(e.$2['role_id'].toString()))
        .toSet();
  }

  void _toggleRole(int roleId, bool visible) {
    setState(() {
      final next = Set<int>.from(_visibleRoleIds);
      visible ? next.add(roleId) : next.remove(roleId);
      _visibleRoleIds = next;
    });
    _fetchChartData();
  }

  // 2단계: 선택된 항목(role_ids)으로 차트 API 호출
  Future<void> _fetchChartData() async {
    final int? roomId = _selectedRoomId;
    if (roomId == null) return;

    setState(() => _isLoading = true);

    try {
      final List<int> roleIdsToFetch = _visibleRoleIds.toList();

      if (roleIdsToFetch.isEmpty) {
        setState(() {
          _chartData = null;
          _isLoading = false;
        });
        return;
      }

      // 파라미터에서 dataType 완전 제거됨
      final result = await ChartApiService.getHistoricalData(
        facilityId: int.parse(widget.facilityId),
        roomId: roomId,
        scale: _currentScale,
        timeRange: _currentTimeRange,
        roleIds: roleIdsToFetch,
      );

      // 서버가 준 상·하한이 비어 있는 항목에만 직접 적어 둔 값을 끼워 넣는다.
      // 여기서 섞어 두면 차트를 그리는 쪽은 그 값이 어디서 왔는지 몰라도 된다.
      final limits = await ChartLimits.load(roomId.toString());
      ChartLimits.apply(result, limits);

      if (mounted) {
        setState(() {
          _chartData = result;
          _manualLimits = limits;
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, context.l10n.chartFailed(describeApiError(context, e)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 지금 그려진 시리즈를 모아 기준값 창을 연다.
  Future<void> _editLimits() async {
    final roomId = _selectedRoomId;
    if (roomId == null) return;

    final datasets = _chartData?['data']?['datasets'];
    final series = <({String roleName, String label})>[
      if (datasets is List)
        for (final ds in datasets)
          if (ds is Map && ds['role_name'] != null)
            (
              roleName: ds['role_name'].toString(),
              label: (ds['display_name']?.toString().isNotEmpty ?? false)
                  ? ds['display_name'].toString()
                  : DeviceLabels.of(context, ds['role_name'].toString()),
            ),
    ];

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => ChartLimitsDialog(
        roomId: roomId.toString(),
        series: series,
        current: _manualLimits,
      ),
    );

    if (saved != true || !mounted) return;
    AppToast.info(context, context.l10n.chartLimitsSaved);
    await _fetchChartData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.chartPageTitle)),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Box 1
            ChartFilterBox(
              // currentDataType: _currentDataType 파라미터 완전 제거
              currentScale: _currentScale,
              currentTimeRange: _currentTimeRange,
              onScaleChanged: (val) => setState(() => _currentScale = val),
              onTimeRangeChanged: (val) => setState(() => _currentTimeRange = val),
              onApply: _fetchChartData,
              rooms: _rooms,
              selectedRoomId: _selectedRoomId,
              onRoomChanged: (roomId) {
                setState(() {
                  _selectedRoomId = roomId;
                  _chartData = null;
                });
                // 호실이 바뀌면 그 호실의 롤부터 다시 불러와야 한다.
                _loadRolesAndChart();
              },
            ),
            const SizedBox(height: 16),

            // 차트를 조건 바로 아래에 둔다. 이 화면을 여는 이유는 그래프를
            // 보는 것 하나인데, 항목 고르기와 기준선 스위치가 그 앞을 막고
            // 있어서 들어오자마자 스크롤부터 해야 했다. 둘 다 한 번 맞춰 두면
            // 그대로 두는 것들이라 그래프 아래로 내린다.
            ChartCanvasBox(
              chartData: _chartData,
              isLoading: _isLoading,
              showTargetLines: _showTargetLines,
            ),
            const SizedBox(height: 16),

            ChartSeriesBox(
              roles: _tempRoles,
              visibleRoleIds: _visibleRoleIds,
              onRoleToggled: _toggleRole,
            ),
            const SizedBox(height: 16),

            ChartToolBox(
              showTargetLines: _showTargetLines,
              onToggleTargetLines: (val) => setState(() => _showTargetLines = val),
              chartData: _chartData,
              onEditLimits: _editLimits,
            ),
            const SizedBox(height: 16),

            ChartStatsBox(chartData: _chartData),
          ],
        ),
      ),
    );
  }
}