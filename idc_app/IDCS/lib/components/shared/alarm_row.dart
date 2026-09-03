// 경로: lib/components/shared/alarm_row.dart
// 명세: 알람 목록 행 — user_alarm/facility_alarm 두 화면에서 공유
import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';

/// 알람 상태를 아이콘 대신 좌측 색상 바로 표현하는 리스트 행.
class AlarmRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timestamp;
  final bool hasAlarm;
  final VoidCallback? onTap;

  const AlarmRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.hasAlarm,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = hasAlarm ? AppColors.error : AppColors.primary;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outline),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
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
                        if (timestamp.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(timestamp, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
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
