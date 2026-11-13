import 'package:flutter/material.dart';
import 'package:idcs/components/indices/main_alarm/facility_alarm_components.dart';
import 'package:idcs/components/shared/alarm_row.dart';
import 'package:idcs/components/shared/skeleton.dart';
import 'package:idcs/services/common/alarm/alarm_api_service.dart';
import 'package:idcs/services/common/facility_api_service.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/components/facility/monitoring/alarm_control_panel.dart';
import 'package:idcs/services/common/api_client.dart';
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

  /// 검색 필터 기준 ('name' 또는 'room').
  String _searchTarget = 'name';

  AlarmStatusFilter _statusFilter = AlarmStatusFilter.active;
  bool _grouped = true;

  @override
  void initState() {
    super.initState();
    _loadPointRoles();
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
        AppToast.error(context, context.l10n.errorOccurred(describeApiError(context, e)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<ParentNode> _treeNodes = [];
  bool _isTreeLoading = true;

  Future<void> _loadPointRoles() async {
    setState(() {
      _isTreeLoading = true;
    });

    try {
      final rooms = await FacilityApiService.getFacilityRooms(widget.facilityId);
      List<ParentNode> loadedParents = [];

      for (var room in rooms) {
        final roomId = room["id"];
        if (roomId == null) continue;

        // 방 이름 (부모 타이틀) 추출 - room_name 혹은 name 필드 활용
        final roomName = room["room_name"]?.toString() ?? room["name"]?.toString() ?? '알 수 없는 구역';

        final roles = await FacilityApiService.getFacilityPointRoleMeta(roomId.toString());
        List<ChildNode> loadedChildren = [];

        for (var r in roles) {
          if (r is! Map) continue;

          final roleName = r["role_name"]?.toString();
          if (roleName == null || roleName.trim().isEmpty) {
            continue;
          }
          final roleId = r["id"]?.toString();
          if (roleId == null || roleId.trim().isEmpty) {
            continue;
          }

          final displayName = r["display_name"]?.toString() ?? '';
          final shortName = r["short_name"]?.toString() ?? '';
          final target = r["target_value"]?.toString().trim() ?? '';
          final low = r["target_low_limit"]?.toString().trim() ?? '';
          final high = r["target_high_limit"]?.toString().trim() ?? '';

          debugPrint("add $roleName : $low");
          debugPrint("add $roleName : $high");

          // 조건에 맞으면 건너뛰기
          if (target.isEmpty && low.isEmpty && high.isEmpty) {
            continue;
          }

          bool isActive = r["is_current"];

          loadedChildren.add(
            ChildNode(
              roleId: roleId,
              roleName: roleName,
              displayName: displayName.isNotEmpty ? displayName : roleName,
              shortName: shortName,
              target: target,
              isActive: isActive,
              onTap: () {},
              onToggle: (value) async {
                try {
                  await FacilityApiService.toggleIsCurrent(roleId, value);

                  setState(() {
                    for (var parent in _treeNodes) {
                      for (var child in parent.children) {
                        if (child.roleId == roleId) {
                          child.isActive = value;
                        }
                      }
                    }
                  });

                } catch (e) {
                  debugPrint("토글 실패: $e");
                  AppToast.error(context, "상태 변경에 실패했습니다.");
                }
              },
            ),
          );
        }

        // 자식 포인트가 존재하는 방만 부모 목록에 추가
        if (loadedChildren.isNotEmpty) {
          loadedParents.add(
            ParentNode(
              parentName: roomName,
              children: loadedChildren,
            ),
          );
        }
      }

      // ★ [핵심 수정 부분] 가공된 데이터를 상태 변수에 대입하여 화면을 갱신합니다!
      setState(() {
        _treeNodes = loadedParents;
      });

    } catch (e, stackTrace) {
      debugPrint("포인트 롤 로드 중 에러 발생: $e");
      debugPrint("스택 트레이스: $stackTrace");
    } finally {
      setState(() {
        _isTreeLoading = false;
      });
    }
  }

  List<GroupedAlarm> get _recentlyEnded =>
      groupAlarms(_alarms.where((a) => !isAlarmActive(a)).toList()).take(4).toList();

  @override
  Widget build(BuildContext context) {
    // 탭 컨트롤러를 사용하여 2개의 탭(예: 알람 내역 탭 / 다른 화면 탭)을 관리합니다.
    return DefaultTabController(
      length: 2, // 탭 개수 (필요에 따라 늘릴 수 있습니다)
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.navAlarm),
          // AppBar 하단에 탭바 배치
          bottom: TabBar(
            tabs: const [
              Tab(text: '알람 목록'), // 첫 번째 탭 캡션
              Tab(text: '알람 설정'), // 두 번째 탭 캡션 (원하시는 이름으로 변경 가능)
            ],
            labelColor: context.colors.textPrimary,
            unselectedLabelColor: context.colors.textSecondary,
            indicatorColor: context.colors.primary,
          ),
        ),
        body: _isLoading
            ? const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: double.infinity, child: SkeletonBox(height: 48, radius: 14)),
              SizedBox(height: 14),
              SkeletonBox(width: 250, height: 34, radius: 9),
              SizedBox(height: 18),
              SizedBox(width: double.infinity, child: AlarmListSkeleton()),
            ],
          ),
        )
            : TabBarView(
          children: [
            // --- [첫 번째 탭: 기존 알람 목록 화면] ---
            RefreshIndicator(
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
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
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
                          const SizedBox(height: 12),
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
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(context).padding.bottom),
                    sliver: FacilityAlarmBox(
                      alarms: _grouped ? groupAlarms(
                        filterAlarmsByStatus(_alarms, _statusFilter).where((alarm) {
                          final query = _searchQuery.toLowerCase();
                          if (query.isEmpty) return true;
                          if (_searchTarget == 'room') {
                            return (alarm['room_name'] ?? '').toString().toLowerCase().contains(query);
                          } else {
                            return alarmNameMatches(context, alarm, query);
                          }
                        }).toList(),
                      ) : filterAlarmsByStatus(_alarms, _statusFilter).where((alarm) {
                        final query = _searchQuery.toLowerCase();
                        if (query.isEmpty) return true;
                        if (_searchTarget == 'room') {
                          return (alarm['room_name'] ?? '').toString().toLowerCase().contains(query);
                        } else {
                          return alarmNameMatches(context, alarm, query);
                        }
                      }).map((a) => GroupedAlarm([a])).toList(),
                      isSearching: _searchQuery.isNotEmpty,
                      showingActiveOnly: _statusFilter == AlarmStatusFilter.active,
                      recentlyEnded: _recentlyEnded,
                    ),
                  ),
                ],
              ),
            ),

            // --- [두 번째 탭: 누르면 전환되는 새로운 화면/컨텐츠] ---
            FacilityTreeViewTab(
              parentNodes: _treeNodes,
              isLoading: _isTreeLoading,
            )
          ],
        ),
      ),
    );
  }
}