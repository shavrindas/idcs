import 'package:flutter/material.dart';
import 'package:idcs/components/shared/alarm_row.dart';
import 'package:idcs/l10n/l10n_context.dart';

/// Box #2: 시설 알람 박스 (순수 목록 표시 역할)
class FacilityAlarmBox extends StatelessWidget {
  final List<GroupedAlarm> alarms;
  final bool isSearching;

  /// '진행중'만 보고 있는지. 비어 있을 때 '볼 알람이 없다'가 아니라
  /// '지금 울리는 게 없다'고 안심시켜 주기 위해 필요하다.
  final bool showingActiveOnly;

  const FacilityAlarmBox({
    super.key,
    required this.alarms,
    this.isSearching = false,
    this.showingActiveOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (alarms.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyListState(
          icon: Icons.notifications_off_outlined,
          // 검색이 빈손인 것과 '지금 울리는 게 없다'는 다른 소식이다.
          good: !isSearching && showingActiveOnly,
          message: isSearching
              ? context.l10n.searchNoResults
              : showingActiveOnly
                  ? context.l10n.alarmsNoneActive
                  : context.l10n.alarmsNone,
        ),
      );
    }

    // 알람은 계속 쌓이므로 화면에 보이는 만큼만 만드는 Sliver 목록을 쓴다.
    return SliverList.separated(
      itemCount: alarms.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final group = alarms[index];

        return GroupedAlarmTile(
          group: group,
          title: alarmDisplayName(context, group.alarm['alarm_name']),
          subtitle: group.alarm['room_name'] ?? context.l10n.roomNameMissing,
        );
      },
    );
  }
}
