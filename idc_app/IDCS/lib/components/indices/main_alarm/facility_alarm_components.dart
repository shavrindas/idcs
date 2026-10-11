import 'package:flutter/material.dart';
import 'package:idcs/components/shared/alarm_row.dart';
import 'package:idcs/l10n/l10n_context.dart';

/// Box #2: 시설 알람 박스 (순수 목록 표시 역할)
class FacilityAlarmBox extends StatelessWidget {
  final List<GroupedAlarm> alarms;
  final bool isSearching;

  const FacilityAlarmBox({
    super.key,
    required this.alarms,
    this.isSearching = false,
  });

  @override
  Widget build(BuildContext context) {
    if (alarms.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyListState(
          icon: Icons.notifications_off_outlined,
          message: isSearching ? context.l10n.searchNoResults : context.l10n.alarmsNone,
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
          title: group.alarm['alarm_name'] ?? context.l10n.alarmNameMissing,
          subtitle: group.alarm['room_name'] ?? context.l10n.roomNameMissing,
        );
      },
    );
  }
}
