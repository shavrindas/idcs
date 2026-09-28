// 경로: lib/components/shared/alarm_row.dart
// 명세: 알람 목록 행 — user_alarm/facility_alarm 두 화면에서 공유
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:idcs/theme/app_theme.dart';

/// 알람이 아직 진행 중인지 판단한다.
/// DB의 severity는 point_role_table에 해당 컬럼이 없어 항상 'a'로 저장되므로
/// 구분에 쓸 수 없다. 대신 services/alarm.py와 같은 기준(end_time 경과 여부)을 쓴다.
bool isAlarmActive(dynamic alarm) {
  final endTime = DateTime.tryParse(alarm['end_time']?.toString() ?? '');
  if (endTime == null) return alarm['is_triggered'] == true;
  return endTime.isAfter(DateTime.now());
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

  const AlarmRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.isActive,
    this.count = 1,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = isActive ? AppColors.error : AppColors.textSecondary.withValues(alpha: 0.4);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outline),
          ),
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
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
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
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                          isActive ? '진행중' : '종료',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent),
                        ),
                        if (timestamp.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(timestamp, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 28),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
