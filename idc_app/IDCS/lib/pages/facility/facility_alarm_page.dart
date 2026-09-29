import 'package:flutter/material.dart';
import 'package:idcs/components/indices/main_alarm/facility_alarm_components.dart';
import 'package:idcs/components/shared/alarm_row.dart';
import 'package:idcs/services/common/alarm/alarm_api_service.dart';
import 'package:idcs/theme/app_theme.dart';

class FacilityAlarmPage extends StatefulWidget {
  final String userId;
  final String facilityId;

  const FacilityAlarmPage({
    super.key,
    required this.userId,
    required this.facilityId,
  });

  @override
  State<FacilityAlarmPage> createState() => _FacilityAlarmPageState();
}

class _FacilityAlarmPageState extends State<FacilityAlarmPage> {
  bool _isLoading = true;
  List<dynamic> _alarms = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 💡 검색 필터 기준 상태 변수 추가 ('name' 또는 'room')
  String _searchTarget = 'name';

  AlarmStatusFilter _statusFilter = AlarmStatusFilter.all;
  bool _grouped = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final alarms = await AlarmApiService.getFacilitiesAlarms(widget.facilityId);
      setState(() {
        _alarms = alarms;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('권한 조회 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchedAlarms = filterAlarmsByStatus(_alarms, _statusFilter).where((alarm) {
      final query = _searchQuery.toLowerCase();
      if (query.isEmpty) return true;

      if (_searchTarget == 'room') {
        final room = (alarm['room_name'] ?? '').toString().toLowerCase();
        return room.contains(query);
      } else {
        final name = (alarm['alarm_name'] ?? '').toString().toLowerCase();
        return name.contains(query);
      }
    }).toList();

    // 묶어서 보기가 꺼져 있으면 건마다 count 1로 그대로 보여준다.
    final displayAlarms = _grouped
        ? groupAlarms(searchedAlarms)
        : searchedAlarms.map((a) => GroupedAlarm([a])).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('알람')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 검색창과 드롭다운을 가로 배치
            Row(
              children: [
                // 1. 검색 입력창
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      // 선택된 필터 기준에 따라 힌트 문구 변경
                      hintText: _searchTarget == 'name' ? '알람 명으로 검색...' : '룸 이름으로 검색...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                          : null,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // 2. 오른쪽 필터 선택 드롭다운
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.outline),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _searchTarget,
                      icon: const Icon(Icons.expand_more_rounded, size: 20, color: AppColors.textSecondary),
                      isDense: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'name',
                          child: Text('알람 명', style: TextStyle(fontSize: 14)),
                        ),
                        DropdownMenuItem(
                          value: 'room',
                          child: Text('룸 ID', style: TextStyle(fontSize: 14)),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _searchTarget = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            AlarmFilterBar(
              statusFilter: _statusFilter,
              onStatusChanged: (val) => setState(() => _statusFilter = val),
              grouped: _grouped,
              onGroupedChanged: (val) => setState(() => _grouped = val),
            ),
            const SizedBox(height: 8),

            // 3. 필터링된 알람 데이터 전달
            FacilityAlarmBox(
              alarms: displayAlarms,
              isSearching: _searchQuery.isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }
}