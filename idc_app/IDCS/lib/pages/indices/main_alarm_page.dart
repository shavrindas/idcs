import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/indices/main_alarm/user_alarm_components.dart';
import 'package:idcs/components/shared/alarm_row.dart';
import 'package:idcs/services/common/alarm/alarm_api_service.dart';
import 'package:idcs/theme/app_theme.dart';
import '../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';

class MainAlarmPage extends StatefulWidget {
  final String userId;
  const MainAlarmPage({super.key, required this.userId});

  @override
  State<MainAlarmPage> createState() => _MainAlarmPageState();
}

class _MainAlarmPageState extends State<MainAlarmPage> {
  bool _isLoading = true;
  List<dynamic> _alarms = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 💡 검색 대상 상태 변수 ('name', 'room', 'facility')
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
      final alarms = await AlarmApiService.getUserAlarms(widget.userId);
      setState(() {
        _alarms = alarms;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.permissionLoadFailed(describeApiError(e)))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void onPressed(int facilityId) {
    context.push('/facility/${widget.userId}/$facilityId/monitoring');
  }

  @override
  Widget build(BuildContext context) {
    // 💡 선택된 검색 기준(_searchTarget)별 필터링 조건
    final searchedAlarms = filterAlarmsByStatus(_alarms, _statusFilter).where((alarm) {
      final query = _searchQuery.toLowerCase();
      if (query.isEmpty) return true;

      if (_searchTarget == 'facility') {
        final facility = (alarm['facility_name'] ?? '').toString().toLowerCase();
        return facility.contains(query);
      } else if (_searchTarget == 'room') {
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

    // 선택된 필터 기준에 따른 힌트 문구
    String getHintText() {
      switch (_searchTarget) {
        case 'facility':
          return context.l10n.alarmSearchByFacility;
        case 'room':
          return context.l10n.alarmSearchByRoom;
        case 'name':
        default:
          return context.l10n.alarmSearchByName;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.alarmsAllTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 검색창 + 필터 드롭다운 레이아웃
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: getHintText(),
                                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                        tooltip: context.l10n.actionSearchClear,
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

                            // 필터 옵션 드롭다운 (알람 명 / 룸 이름 / 시설 이름)
                            Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                border: Border.all(color: context.colors.outline),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _searchTarget,
                                  icon: Icon(Icons.expand_more_rounded, size: 20, color: context.colors.textSecondary),
                                  isDense: true,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'name',
                                      child: Text(context.l10n.alarmFieldName, style: TextStyle(fontSize: 14)),
                                    ),
                                    DropdownMenuItem(
                                      value: 'room',
                                      child: Text(context.l10n.alarmFieldRoom, style: TextStyle(fontSize: 14)),
                                    ),
                                    DropdownMenuItem(
                                      value: 'facility',
                                      child: Text(context.l10n.alarmFieldFacility, style: TextStyle(fontSize: 14)),
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
                      ],
                    ),
                  ),
                ),
                // Box #2: 통합 알람 박스
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: UserAlarmBox(
                    alarms: displayAlarms,
                    onFacilityPressed: onPressed,
                    isSearching: _searchQuery.isNotEmpty,
                  ),
                ),
              ],
            ),
    );
  }
}
