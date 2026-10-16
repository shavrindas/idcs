import 'package:flutter/material.dart';
import 'package:idcs/components/indices/main_alarm/facility_alarm_components.dart';
import 'package:idcs/components/shared/alarm_row.dart';
import 'package:idcs/components/shared/skeleton.dart';
import 'package:idcs/services/common/alarm/alarm_api_service.dart';
import 'package:idcs/theme/app_theme.dart';
import '../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/components/shared/app_toast.dart';

class FacilityAlarmPage extends StatefulWidget {
  final String userId;
  final String facilityId;

  const FacilityAlarmPage({super.key, required this.userId, required this.facilityId});

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

  // 목록을 열었을 때 궁금한 것은 '지금 뭔가 울리고 있나'다. 끝난 알람 100여 건
  // 사이에서 그 답을 찾게 두지 않는다.
  AlarmStatusFilter _statusFilter = AlarmStatusFilter.active;
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
        AppToast.error(context, context.l10n.permissionLoadFailed(describeApiError(context, e)));
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
        return alarmNameMatches(context, alarm, query);
      }
    }).toList();

    // 묶어서 보기가 꺼져 있으면 건마다 count 1로 그대로 보여준다.
    final displayAlarms = _grouped
        ? groupAlarms(searchedAlarms)
        : searchedAlarms.map((a) => GroupedAlarm([a])).toList();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navAlarm)),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 검색창은 실제로 가로를 다 쓰고, 칩 줄은 아니다.
                  SizedBox(width: double.infinity, child: SkeletonBox(height: 48, radius: 14)),
                  SizedBox(height: 14),
                  SkeletonBox(width: 250, height: 34, radius: 9),
                  SizedBox(height: 18),
                  SizedBox(width: double.infinity, child: AlarmListSkeleton()),
                ],
              ),
            )
          // 알람 목록에는 당겨서 새로고침이 없었다. 이 화면을 여는 이유가
          // "방금 뭐 울렸나"인데, 다시 보려면 탭을 나갔다 들어와야 했다.
          : RefreshIndicator(
              onRefresh: _fetchUserData,
              child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
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
                                  hintText: _searchTarget == 'name' ? context.l10n.alarmSearchByAlarmOrRoom : context.l10n.alarmSearchByRoom,
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

                            // 2. 오른쪽 필터 선택 드롭다운
                            Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                boxShadow: context.colors.cardShadow,
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
                                      child: Text(context.l10n.alarmFieldRoomId, style: TextStyle(fontSize: 14)),
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
                          counts: {
                            AlarmStatusFilter.all: _alarms.length,
                            AlarmStatusFilter.active: _alarms.where(isAlarmActive).length,
                            AlarmStatusFilter.ended: _alarms.where((a) => !isAlarmActive(a)).length,
                          },
                          statusFilter: _statusFilter,
                          onStatusChanged: (val) => setState(() => _statusFilter = val),
                          grouped: _grouped,
                          onGroupedChanged: (val) => setState(() => _grouped = val),
                        ),
                      ],
                    ),
                  ),
                ),
                // 3. 필터링된 알람 데이터 전달
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: FacilityAlarmBox(
                    alarms: displayAlarms,
                    isSearching: _searchQuery.isNotEmpty,
                    showingActiveOnly: _statusFilter == AlarmStatusFilter.active,
                  ),
                ),
              ],
            ),
            ),
    );
  }
}
