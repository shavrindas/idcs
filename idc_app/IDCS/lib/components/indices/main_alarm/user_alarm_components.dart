import 'package:flutter/material.dart';
import 'package:idcs/components/shared/alarm_row.dart';

/// Box #2: 통합 알람 박스 (순수 목록 표시 및 이벤트 전달)
class UserAlarmBox extends StatelessWidget {
  final List<GroupedAlarm> alarms;
  final Function(int) onFacilityPressed;
  final bool isSearching;

  const UserAlarmBox({
    super.key,
    required this.alarms,
    required this.onFacilityPressed,
    this.isSearching = false,
  });

  @override
  Widget build(BuildContext context) {
    if (alarms.isEmpty) {
      return EmptyListState(
        icon: Icons.notifications_off_outlined,
        message: isSearching ? '검색 결과가 없습니다.' : '조회할 수 있는 알람이 없습니다.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: alarms.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final group = alarms[index];
        final representative = group.alarm;

        return GroupedAlarmTile(
          group: group,
          title: representative['alarm_name'] ?? '알람 이름 없음',
          subtitle:
              '${representative['facility_name'] ?? '시설 이름 없음'} · ${representative['room_name'] ?? '룸 이름 없음'}',
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
