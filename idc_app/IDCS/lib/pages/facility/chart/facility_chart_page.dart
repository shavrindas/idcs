// ===============================================================
// 경로: lib/pages/facility/chart/facility_chart_page.dart
// 명세: 차트 시각화 및 필터링 제어 페이지
// ===============================================================
import 'package:flutter/material.dart';
import 'package:idcs/components/facility/chart/chart_components.dart';
import 'package:idcs/services/chart/chart_api_service.dart';

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

  // 2. 데이터 포인트 선택 상태
  int? _selectedGroupId;
  List<Map<String, dynamic>> _availableGroups = [];

  // 3. 차트 렌더링 상태
  bool _isLoading = false;
  Map<String, dynamic>? _chartData;

  // 💡 4. 차트 뷰포트 및 도구 제어 상태 추가
  final GlobalKey<ChartCanvasBoxState> _chartCanvasKey = GlobalKey<ChartCanvasBoxState>();
  bool _isPanMode = true; // 기본적으로 줌/이동 가능 상태(Pan 모드)로 시작

  @override
  void initState() {
    super.initState();
    _loadGroupsAndChart();
  }

  // 1단계: 전체 그룹 목록 조회 (타입 필터링 제거)
  Future<void> _loadGroupsAndChart() async {
    setState(() => _isLoading = true);

    try {
      final int roomId = 1; // 임시: 1번 호실 기준

      // 웹 어드민에서 생성된 그룹 리스트 호출
      final groups = await ChartApiService.getChartGroups(int.parse(widget.facilityId), roomId);

      if (mounted) {
        setState(() {
          // 필터링 없이 바로 화면에 렌더링할 그룹 목록에 할당
          _availableGroups = List<Map<String, dynamic>>.from(groups);

          // 선택된 그룹이 없거나 기존 선택 그룹이 삭제된 경우, 첫 번째 그룹 자동 선택
          bool shouldResetGroup = _selectedGroupId == null ||
              !_availableGroups.any((g) => g['group_id'] == _selectedGroupId);

          if (shouldResetGroup && _availableGroups.isNotEmpty) {
            _selectedGroupId = _availableGroups.first['group_id'];
          } else if (_availableGroups.isEmpty) {
            _selectedGroupId = null;
          }
        });

        // 그룹이 선택되었다면 차트 데이터 조회로 넘어감
        if (_selectedGroupId != null) {
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('그룹 로드 오류: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  // 2단계: 선택된 그룹 내부의 role_ids를 추출하여 차트 API 호출
  Future<void> _fetchChartData() async {
    if (_selectedGroupId == null) return;

    setState(() => _isLoading = true);

    try {
      final int roomId = 1;

      final selectedGroup = _availableGroups.firstWhere((g) => g['group_id'] == _selectedGroupId);
      final List<dynamic> rawRoleIds = selectedGroup['role_ids'] ?? [];

      final List<int> roleIdsToFetch = rawRoleIds
          .where((e) => e != null)
          .map((e) => e as int)
          .toList();

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
        // 새 데이터를 불러왔을 때 뷰포트 초기화
        _chartCanvasKey.currentState?.resetViewport();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('차트 오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('시설 ${widget.facilityId} 데이터 차트')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Box 1
            ChartFilterBox(
              currentScale: _currentScale,
              currentTimeRange: _currentTimeRange,
              onScaleChanged: (val) => setState(() => _currentScale = val),
              onTimeRangeChanged: (val) => setState(() => _currentTimeRange = val),
              onApply: _fetchChartData,
            ),
            const SizedBox(height: 16),

            // Box 2
            ChartSeriesBox(
              availableGroups: _availableGroups,
              selectedGroupId: _selectedGroupId,
              onGroupSelected: (groupId) {
                setState(() {
                  _selectedGroupId = groupId;
                });
                _fetchChartData();
              },
            ),
            const SizedBox(height: 16),

            // 💡 Box 4: 도구 상태 주입 및 메서드 연동
            ChartToolBox(
              isPanMode: _isPanMode,
              onTogglePanMode: () {
                setState(() => _isPanMode = !_isPanMode);
              },
              onResetViewport: () {
                _chartCanvasKey.currentState?.resetViewport();
              },
            ),
            const SizedBox(height: 8),

            // 💡 Box 3: Key 할당 및 제어 상태 주입
            ChartCanvasBox(
              key: _chartCanvasKey,
              chartData: _chartData,
              isLoading: _isLoading,
              isPanMode: _isPanMode,
            ),
          ],
        ),
      ),
    );
  }
}