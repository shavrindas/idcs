// ===============================================================
// 경로: lib/pages/facility/chart/facility_chart_page.dart
// 명세: 시설 데이터 차트 조회 페이지 (진짜 그룹 매핑 연동)
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
  // 1. 필터 상태
  String _currentDataType = 'temp';
  String _currentScale = '1m';
  String _currentTimeRange = '1d';

  // 2. 데이터 포인트 선택 상태 (진짜 그룹 리스트)
  int? _selectedGroupId;
  List<Map<String, dynamic>> _allGroups = [];
  List<Map<String, dynamic>> _availableGroups = [];

  // 3. 차트 렌더링 상태
  bool _isLoading = false;
  Map<String, dynamic>? _chartData;

  @override
  void initState() {
    super.initState();
    _loadGroupsAndChart(); // 초기 구동 시 그룹 목록부터 불러오기
  }

  // 1단계: 전체 그룹 목록 조회 및 데이터 타입에 맞춰 필터링
  Future<void> _loadGroupsAndChart() async {
    setState(() => _isLoading = true);

    try {
      final int roomId = 1; // 임시: 라우터 연동 전까지 1번 호실 기준

      // 웹 어드민에서 생성된 그룹 리스트 호출
      final groups = await ChartApiService.getChartGroups(int.parse(widget.facilityId), roomId);

      if (mounted) {
        setState(() {
          _allGroups = List<Map<String, dynamic>>.from(groups);
          _filterGroupsByDataType();
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

  // 데이터 타입(temp, gear 등) 변경 시 해당 그룹만 화면(Box 2)에 노출되도록 필터링
  void _filterGroupsByDataType() {
    _availableGroups = _allGroups.where((g) => g['data_type'] == _currentDataType).toList();

    // 선택된 그룹이 새 데이터 타입 목록에 없으면 가장 첫 번째 그룹으로 자동 선택
    bool shouldResetGroup = _selectedGroupId == null || !_availableGroups.any((g) => g['group_id'] == _selectedGroupId);

    if (shouldResetGroup && _availableGroups.isNotEmpty) {
      _selectedGroupId = _availableGroups.first['group_id'];
    } else if (_availableGroups.isEmpty) {
      _selectedGroupId = null;
    }
  }

  // 2단계: 선택된 그룹 내부의 role_ids를 추출하여 차트 API 호출
  Future<void> _fetchChartData() async {
    if (_selectedGroupId == null) return;

    setState(() => _isLoading = true);

    try {
      final int roomId = 1;

      // 현재 선택된 그룹에서 매핑된 role_ids 추출
      final selectedGroup = _availableGroups.firstWhere((g) => g['group_id'] == _selectedGroupId);
      final List<dynamic> rawRoleIds = selectedGroup['role_ids'] ?? [];

      // JSON Array의 Null 값 방어 처리
      final List<int> roleIdsToFetch = rawRoleIds
          .where((e) => e != null)
          .map((e) => e as int)
          .toList();

      // 그룹에 매핑된 센서가 없다면 빈 캔버스로 처리
      if (roleIdsToFetch.isEmpty) {
        setState(() {
          _chartData = null;
          _isLoading = false;
        });
        return;
      }

      // 추출한 배열을 백엔드 파라미터로 넘겨 실제 데이터 조회
      final result = await ChartApiService.getHistoricalData(
        facilityId: int.parse(widget.facilityId),
        roomId: roomId,
        dataType: _currentDataType,
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
              currentDataType: _currentDataType,
              currentScale: _currentScale,
              currentTimeRange: _currentTimeRange,
              onDataTypeChanged: (val) {
                setState(() {
                  _currentDataType = val;
                  _filterGroupsByDataType(); // 타입 변경 시 로컬에서 칩 목록 재정렬
                });

                if (_selectedGroupId != null) {
                  _fetchChartData();
                } else {
                  setState(() => _chartData = null);
                }
              },
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
                _fetchChartData(); // 그룹 칩을 터치하면 바로 새로운 차트 로드
              },
            ),
            const SizedBox(height: 16),

            // Box 4
            const ChartToolBox(),
            const SizedBox(height: 8),

            // Box 3
            ChartCanvasBox(
              chartData: _chartData,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}