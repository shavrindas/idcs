// ===============================================================
// 경로: lib/pages/facility/chart/facility_chart_page.dart
// ===============================================================
import 'package:flutter/material.dart';
import 'package:idcs/components/facility/chart/chart_components.dart';
import 'package:idcs/services/chart/chart_api_service.dart';
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
  String _currentScale = '1m';
  String _currentTimeRange = '1d';

  // 2. 조회 대상 호실 상태
  List<dynamic> _rooms = [];
  int? _selectedRoomId;

  // 3. 데이터 포인트 선택 상태
  int? _selectedGroupId;
  List<Map<String, dynamic>> _availableGroups = []; // _allGroups 변수도 불필요하여 제거

  /// 호실의 전체 포인트 롤. 그룹에 어떤 항목이 묶여 있는지 이름으로 보여주는 데 쓴다.
  List<dynamic> _roles = [];

  /// 실제로 차트에 그릴 롤. 그룹을 고르면 채워지고, 개별로 끄고 켤 수 있다.
  Set<int> _visibleRoleIds = {};

  /// 그룹과 무관하게 항목을 직접 고르는 모드.
  bool _directMode = false;

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
        await _loadGroupsAndChart();
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

  // 1단계: 전체 그룹 목록 조회 (타입 필터링 제거)
  Future<void> _loadGroupsAndChart() async {
    final int? roomId = _selectedRoomId;
    if (roomId == null) return;

    setState(() => _isLoading = true);

    try {
      // 웹 어드민에서 생성된 그룹 리스트와, 호실의 전체 포인트 롤을 함께 불러온다.
      // 그룹 API는 role_id만 주기 때문에 이름을 보여주려면 롤 목록이 필요하다.
      final facilityId = int.parse(widget.facilityId);
      final results = await Future.wait([
        ChartApiService.getChartGroups(facilityId, roomId),
        ChartApiService.getPointRoles(facilityId, roomId),
      ]);

      if (mounted) {
        setState(() {
          // 필터링 없이 바로 화면에 렌더링할 그룹 목록에 할당
          _availableGroups = List<Map<String, dynamic>>.from(results[0]);
          _roles = results[1];

          // 선택된 그룹이 없거나 기존 선택 그룹이 삭제된 경우, 첫 번째 그룹 자동 선택
          bool shouldResetGroup = _selectedGroupId == null ||
              !_availableGroups.any((g) => g['group_id'] == _selectedGroupId);

          if (shouldResetGroup && _availableGroups.isNotEmpty) {
            _selectedGroupId = _availableGroups.first['group_id'];
          } else if (_availableGroups.isEmpty) {
            _selectedGroupId = null;
          }

          // 직접 선택 모드였다면 보고 있던 항목을 그대로 둔다 — 호실이 바뀌어
          // 없어진 롤만 떨어진다. 그룹 모드면 그룹의 항목을 읽을 수 있는
          // 개수까지만 켠다.
          _visibleRoleIds = _directMode
              ? _visibleRoleIds.intersection(_allRoleIds())
              : _cappedAuto(_roleIdsOfGroup(_selectedGroupId));
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

  Set<int> _allRoleIds() => _roles
      .map((r) => r['role_id'] is int ? r['role_id'] as int : int.tryParse(r['role_id'].toString()))
      .whereType<int>()
      .toSet();

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

  Set<int> _roleIdsOfGroup(int? groupId) {
    final group = _availableGroups.where((g) => g['group_id'] == groupId).firstOrNull;
    return (group?['role_ids'] as List?)?.whereType<int>().toSet() ?? <int>{};
  }

  void _selectGroup(int groupId) {
    setState(() {
      _directMode = false;
      _selectedGroupId = groupId;
      _visibleRoleIds = _cappedAuto(_roleIdsOfGroup(groupId));
    });
    _fetchChartData();
  }

  void _enterDirectMode() {
    // 호실의 모든 항목을 한꺼번에 켜면(42개까지 나온다) 눈금 범위가 뭉개져 차트를 읽을 수 없다.
    // 그래서 보고 있던 선택을 그대로 두고, 목록만 전체로 펼친다.
    setState(() => _directMode = true);
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

      if (mounted) {
        setState(() {
          _chartData = result;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.chartPageTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
                // 호실이 바뀌면 그 호실에 등록된 그룹부터 다시 불러와야 한다.
                _loadGroupsAndChart();
              },
            ),
            const SizedBox(height: 16),

            // Box 2
            ChartSeriesBox(
              availableGroups: _availableGroups,
              selectedGroupId: _selectedGroupId,
              onGroupSelected: _selectGroup,
              directMode: _directMode,
              onDirectModeSelected: _enterDirectMode,
              roles: _roles,
              visibleRoleIds: _visibleRoleIds,
              onRoleToggled: _toggleRole,
            ),
            const SizedBox(height: 16),

            // Box 4
            ChartToolBox(
              showTargetLines: _showTargetLines,
              onToggleTargetLines: (val) => setState(() => _showTargetLines = val),
              chartData: _chartData,
            ),
            const SizedBox(height: 8),

            // Box 3
            ChartCanvasBox(
              chartData: _chartData,
              isLoading: _isLoading,
              showTargetLines: _showTargetLines,
            ),
            const SizedBox(height: 16),

            ChartStatsBox(chartData: _chartData),
          ],
        ),
      ),
    );
  }
}