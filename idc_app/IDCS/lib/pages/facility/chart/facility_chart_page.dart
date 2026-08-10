// ===============================================================
// 경로: lib/pages/facility/chart/facility_chart_page.dart
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
  late DateTime _startTime;
  late DateTime _endTime;

  int? _selectedGroupId;
  List<Map<String, dynamic>> _availableGroups = [];

  bool _isLoading = false;
  Map<String, dynamic>? _chartData;

  final GlobalKey<ChartCanvasBoxState> _chartCanvasKey = GlobalKey<ChartCanvasBoxState>();
  bool _isPanMode = true;

  @override
  void initState() {
    super.initState();
    _endTime = DateTime.now();
    _startTime = _endTime.subtract(const Duration(hours: 12));
    _loadGroupsAndChart();
  }

  String _calculateScale() {
    final diff = _endTime.difference(_startTime);
    if (diff.inHours < 3) return '10s';
    if (diff.inDays < 1) return '1m';
    if (diff.inDays < 10) return '5m';
    return '1h';
  }

  Future<void> _loadGroupsAndChart() async {
    setState(() => _isLoading = true);
    try {
      final groups = await ChartApiService.getChartGroups(int.parse(widget.facilityId), 1);
      if (mounted) {
        setState(() {
          _availableGroups = List<Map<String, dynamic>>.from(groups);
          bool shouldResetGroup = _selectedGroupId == null || !_availableGroups.any((g) => g['group_id'] == _selectedGroupId);
          if (shouldResetGroup && _availableGroups.isNotEmpty) {
            _selectedGroupId = _availableGroups.first['group_id'];
          } else if (_availableGroups.isEmpty) {
            _selectedGroupId = null;
          }
        });
        if (_selectedGroupId != null) {
          await _fetchChartData();
        } else {
          setState(() { _chartData = null; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('그룹 로드 오류: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchChartData() async {
    if (_selectedGroupId == null) return;
    setState(() => _isLoading = true);

    try {
      final selectedGroup = _availableGroups.firstWhere((g) => g['group_id'] == _selectedGroupId);
      final List<dynamic> rawRoleIds = selectedGroup['role_ids'] ?? [];

      // 💡 타입 에러 해결: 안전하게 파싱 후 int 타입만 필터링하여 리스트화
      final List<int> roleIdsToFetch = rawRoleIds
          .map((e) => int.tryParse(e.toString()))
          .whereType<int>()
          .toList();

      if (roleIdsToFetch.isEmpty) {
        setState(() { _chartData = null; _isLoading = false; });
        return;
      }

      final autoScale = _calculateScale();

      final result = await ChartApiService.getHistoricalData(
        facilityId: int.parse(widget.facilityId),
        roomId: 1,
        scale: autoScale,
        startTime: _startTime,
        endTime: _endTime,
        roleIds: roleIdsToFetch,
      );

      if (mounted) {
        setState(() => _chartData = result);
        _chartCanvasKey.currentState?.resetViewport();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('차트 오류: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateTime(bool isStart) async {
    final DateTime initialDate = isStart ? _startTime : _endTime;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      // 💡 요구사항 반영: 과거 조회 가능 최대 한계치 지정
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (pickedTime != null && mounted) {
        setState(() {
          final newDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
          if (isStart) {
            _startTime = newDateTime;
          } else {
            _endTime = newDateTime;
          }
        });
      }
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
            ChartSearchScopeBox(
              startTime: _startTime,
              endTime: _endTime,
              autoScale: _calculateScale(),
              onSelectStartTime: () => _selectDateTime(true),
              onSelectEndTime: () => _selectDateTime(false),
              onSearch: _fetchChartData,
            ),
            const SizedBox(height: 16),
            ChartSeriesBox(
              availableGroups: _availableGroups,
              selectedGroupId: _selectedGroupId,
              onGroupSelected: (groupId) {
                setState(() => _selectedGroupId = groupId);
                _fetchChartData();
              },
            ),
            const SizedBox(height: 16),
            ChartToolBox(
              isPanMode: _isPanMode,
              onTogglePanMode: () => setState(() => _isPanMode = !_isPanMode),
              onResetViewport: () => _chartCanvasKey.currentState?.resetViewport(),
            ),
            const SizedBox(height: 8),
            // 💡 데이터가 없어도 검색 범위를 알 수 있도록 전달
            ChartCanvasBox(
              key: _chartCanvasKey,
              chartData: _chartData,
              isLoading: _isLoading,
              isPanMode: _isPanMode,
              searchedStartTime: _startTime,
              searchedEndTime: _endTime,
            ),
          ],
        ),
      ),
    );
  }
}