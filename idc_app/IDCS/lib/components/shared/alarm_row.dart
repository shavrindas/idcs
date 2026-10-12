// 경로: lib/components/shared/alarm_row.dart
// 명세: 알람 목록 행과 목록 가공(상태 필터·반복 묶음) — user_alarm/facility_alarm 두 화면에서 공유
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:idcs/components/facility/monitoring/device_labels.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/l10n/l10n_context.dart';

/// 알람 목록 상태 필터.
enum AlarmStatusFilter { all, active, ended }

/// 반복 발생한 알람을 한 줄로 묶은 결과.
/// [members]는 최신순이며, 펼쳤을 때 개별 발생 건을 보여주는 데 쓴다.
class GroupedAlarm {
  final List<dynamic> members;

  const GroupedAlarm(this.members);

  /// 목록에 대표로 보여줄 건 (가장 최근 발생).
  dynamic get alarm => members.first;

  int get count => members.length;
}

/// 진행 여부로 목록을 거른다.
List<dynamic> filterAlarmsByStatus(List<dynamic> alarms, AlarmStatusFilter filter) {
  switch (filter) {
    case AlarmStatusFilter.all:
      return alarms;
    case AlarmStatusFilter.active:
      return alarms.where(isAlarmActive).toList();
    case AlarmStatusFilter.ended:
      return alarms.where((a) => !isAlarmActive(a)).toList();
  }
}

/// 같은 지점(role_id)에서 같은 이름으로 반복 발생한 알람을 한 줄로 묶는다.
/// 서버가 최신순으로 내려주므로 먼저 만난 건을 대표로 두고 건수만 센다.
List<GroupedAlarm> groupAlarms(List<dynamic> alarms) {
  final Map<String, List<dynamic>> groups = {};
  final List<String> order = [];

  for (final alarm in alarms) {
    final key = '${alarm['role_id']}|${alarm['alarm_name']}';
    if (!groups.containsKey(key)) {
      groups[key] = [];
      order.add(key);
    }
    groups[key]!.add(alarm);
  }

  return order.map((key) => GroupedAlarm(groups[key]!)).toList();
}

/// 알람이 아직 진행 중인지 판단한다.
/// DB의 severity는 point_role_table에 해당 컬럼이 없어 항상 'a'로 저장되므로
/// 구분에 쓸 수 없다. 대신 services/alarm.py와 같은 기준(end_time 경과 여부)을 쓴다.
bool isAlarmActive(dynamic alarm) {
  final endTime = DateTime.tryParse(alarm['end_time']?.toString() ?? '');
  if (endTime == null) return alarm['is_triggered'] == true;
  return endTime.isAfter(DateTime.now());
}

/// 알람 이름을 사람이 읽을 수 있는 형태로 바꾼다.
///
/// 서버는 "25.emergency_locked" 처럼 호실 ID 와 장비 필드명을 붙여서 내려준다.
/// 앞의 숫자는 바로 아래 줄에 호실 이름으로 이미 적혀 있어 중복이고, 뒤쪽은
/// 제어판에서 쓰는 것과 같은 키라서 DeviceLabels 가 그대로 번역할 수 있다.
String alarmDisplayName(BuildContext context, dynamic rawName) {
  final raw = rawName?.toString() ?? '';
  if (raw.isEmpty) return context.l10n.alarmNameMissing;

  final dot = raw.indexOf('.');
  final key = dot == -1 ? raw : raw.substring(dot + 1);
  return DeviceLabels.of(context, key);
}

/// 서버가 내려주는 ISO 시간 문자열을 목록에서 읽기 쉬운 형태로 바꾼다.
String formatAlarmTime(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return DateFormat('MM/dd HH:mm').format(parsed.toLocal());
}

/// 알람 상태를 아이콘 대신 좌측 색상 바로 표현하는 리스트 행.
class AlarmRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timestamp;
  final bool isActive;

  /// 같은 알람이 반복 발생했을 때 묶인 건수. 1이면 배지를 숨긴다.
  final int count;
  final VoidCallback? onTap;

  /// 묶인 건을 펼칠 수 있는 행이면 화살표를 보여준다.
  final bool isExpandable;
  final bool isExpanded;

  const AlarmRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.isActive,
    this.count = 1,
    this.onTap,
    this.isExpandable = false,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = isActive ? context.colors.error : context.colors.textSecondary.withValues(alpha: 0.4);

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: context.colors.cardShadow),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
            // 좌측 색상 바는 Stack으로 높이를 맞춘다. IntrinsicHeight를 쓰면 텍스트 높이
            // 반올림 때문에 1px 오버플로가 생긴다.
            child: Stack(
              children: [
                Positioned(left: 0, top: 0, bottom: 0, width: 3, child: ColoredBox(color: accent)),
                Padding(
                  padding: const EdgeInsets.only(left: 17, right: 14, top: 12, bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: context.colors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (count > 1) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '×$count',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isActive ? context.l10n.alarmStatusActive : context.l10n.alarmStatusEnded,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent),
                          ),
                          if (timestamp.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(timestamp, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                          ],
                        ],
                      ),
                      if (isExpandable)
                        Icon(
                          isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          size: 20,
                          color: context.colors.textSecondary,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 묶인 알람 한 덩어리. 2건 이상이면 눌러서 개별 발생 건을 펼쳐볼 수 있다.
class GroupedAlarmTile extends StatefulWidget {
  final GroupedAlarm group;
  final String title;

  /// 대표 행에 보여줄 부제 (시설·호실 등).
  final String subtitle;

  /// 개별 건을 눌렀을 때 동작. 묶이지 않은 단일 알람의 탭에도 쓰인다.
  final void Function(dynamic alarm)? onAlarmTap;

  const GroupedAlarmTile({
    super.key,
    required this.group,
    required this.title,
    required this.subtitle,
    this.onAlarmTap,
  });

  @override
  State<GroupedAlarmTile> createState() => _GroupedAlarmTileState();
}

class _GroupedAlarmTileState extends State<GroupedAlarmTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final isGrouped = group.count > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AlarmRow(
          title: widget.title,
          subtitle: widget.subtitle,
          timestamp: formatAlarmTime(group.alarm['timestamp']?.toString() ?? ''),
          isActive: isAlarmActive(group.alarm),
          count: group.count,
          isExpandable: isGrouped,
          isExpanded: _expanded,
          // 묶인 행은 펼치기/접기, 단일 행은 원래 동작을 그대로 한다.
          onTap: isGrouped
              ? () => setState(() => _expanded = !_expanded)
              : (widget.onAlarmTap == null ? null : () => widget.onAlarmTap!(group.alarm)),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 6),
            child: Column(
              children: group.members
                  .map(
                    (alarm) => _OccurrenceRow(
                      alarm: alarm,
                      onTap: widget.onAlarmTap == null ? null : () => widget.onAlarmTap!(alarm),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

/// 펼쳤을 때 보이는 개별 발생 건 한 줄.
class _OccurrenceRow extends StatelessWidget {
  final dynamic alarm;
  final VoidCallback? onTap;

  const _OccurrenceRow({required this.alarm, this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = isAlarmActive(alarm);
    final color = active ? context.colors.error : context.colors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                formatAlarmTime(alarm['timestamp']?.toString() ?? ''),
                style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
              ),
            ),
            Text(
              active ? context.l10n.alarmStatusActive : context.l10n.alarmStatusEnded,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// 상태 필터 칩과 '묶어서 보기' 토글. 두 알람 화면이 함께 쓴다.
class AlarmFilterBar extends StatelessWidget {
  final AlarmStatusFilter statusFilter;
  final ValueChanged<AlarmStatusFilter> onStatusChanged;
  final bool grouped;
  final ValueChanged<bool> onGroupedChanged;

  const AlarmFilterBar({
    super.key,
    required this.statusFilter,
    required this.onStatusChanged,
    required this.grouped,
    required this.onGroupedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            children: [
              _chip(context, context.l10n.alarmStatusAll, AlarmStatusFilter.all),
              _chip(context, context.l10n.alarmStatusActive, AlarmStatusFilter.active),
              _chip(context, context.l10n.alarmStatusEnded, AlarmStatusFilter.ended),
            ],
          ),
        ),
        Text(context.l10n.alarmGroupToggle, style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
        Switch(value: grouped, onChanged: onGroupedChanged),
      ],
    );
  }

  Widget _chip(BuildContext context, String label, AlarmStatusFilter value) {
    final selected = statusFilter == value;
    return ChoiceChip(
      showCheckmark: false,
      label: Text(label),
      selected: selected,
      onSelected: (_) => onStatusChanged(value),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? context.colors.onPrimary : context.colors.textPrimary,
      ),
      selectedColor: context.colors.primary,
      backgroundColor: context.colors.background,
      side: BorderSide(color: selected ? context.colors.primary : context.colors.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    );
  }
}

/// 목록 계열 화면 공용 빈 상태 표시.
class EmptyListState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyListState({super.key, required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.colors.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: context.colors.textSecondary.withValues(alpha: 0.6), size: 28),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
