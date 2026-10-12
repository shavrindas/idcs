import 'package:flutter/material.dart';
import 'package:idcs/components/shared/alarm_row.dart';
import 'package:idcs/l10n/l10n_context.dart';

/// Box #2: 통합 알람 박스 (순수 목록 표시 및 이벤트 전달)
class UserAlarmBox extends StatelessWidget {
  final List<GroupedAlarm> alarms;
  final Function(int) onFacilityPressed;
  final bool isSearching;

  /// '진행중'만 보고 있는지. 비어 있을 때 '볼 알람이 없다'가 아니라
  /// '지금 울리는 게 없다'고 안심시켜 주기 위해 필요하다.
  final bool showingActiveOnly;

  const UserAlarmBox({
    super.key,
    required this.alarms,
    required this.onFacilityPressed,
    this.isSearching = false,
    this.showingActiveOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (alarms.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyListState(
          icon: Icons.notifications_off_outlined,
          message: isSearching
              ? context.l10n.searchNoResults
              : showingActiveOnly
                  ? context.l10n.alarmsNoneActive
                  : context.l10n.alarmsNone,
        ),
      );
    }

    // 알람은 계속 쌓여서 한 유저에 100건이 넘는다. shrinkWrap을 쓰면 화면 밖까지
    // 전부 미리 만들어지므로, 보이는 만큼만 만드는 Sliver 목록으로 둔다.
    return SliverList.separated(
      itemCount: alarms.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final group = alarms[index];
        final representative = group.alarm;

        return GroupedAlarmTile(
          group: group,
          title: alarmDisplayName(context, representative['alarm_name']),
          subtitle:
              '${representative['facility_name'] ?? context.l10n.facilityNameMissing} · ${representative['room_name'] ?? context.l10n.roomNameMissing}',
          onAlarmTap: (alarm) {
            final facilityId = alarm['facility_id'] is int
                ? alarm['facility_id']
                : int.tryParse(alarm['facility_id']?.toString() ?? '0') ?? 0;
            onFacilityPressed(facilityId);
          },
        );
      },
    );
  }
}
