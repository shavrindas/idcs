import 'package:flutter/material.dart';
import 'package:idcs/components/shared/alarm_row.dart';

/// Box #2: 시설 알람 박스 (순수 목록 표시 역할)
class FacilityAlarmBox extends StatelessWidget {
  final List<dynamic> alarms;
  final bool isSearching;

  const FacilityAlarmBox({
    super.key,
    required this.alarms,
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
        final alarm = alarms[index];
        final bool hasAlarm = false;
        final rawTime = alarm['timestamp']?.toString() ?? '';

        return AlarmRow(
          title: alarm['alarm_name'] ?? '알람 이름 없음',
          subtitle: alarm['room_name'] ?? '호실 이름 없음',
          timestamp: rawTime,
          hasAlarm: hasAlarm,
        );
      },
    );
  }
}
