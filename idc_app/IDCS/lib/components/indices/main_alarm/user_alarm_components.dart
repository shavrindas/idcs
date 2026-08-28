import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';

/// Box #2: 통합 알람 박스 (순수 목록 표시 및 이벤트 전달)
class UserAlarmBox extends StatelessWidget {
  final List<dynamic> alarms;
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
      return _EmptyState(
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
        final int facilityId = alarm['facility_id'] is int
            ? alarm['facility_id']
            : int.tryParse(alarm['facility_id']?.toString() ?? '0') ?? 0;

        return _AlarmRow(
          title: alarm['alarm_name'] ?? '알람 이름 없음',
          subtitle: '${alarm['facility_name'] ?? '시설 이름 없음'} · ${alarm['room_name'] ?? '룸 이름 없음'}',
          timestamp: rawTime,
          hasAlarm: hasAlarm,
          onTap: () => onFacilityPressed(facilityId),
        );
      },
    );
  }
}

class _AlarmRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timestamp;
  final bool hasAlarm;
  final VoidCallback onTap;

  const _AlarmRow({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.hasAlarm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (hasAlarm ? AppColors.error : AppColors.primary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 18,
                  color: hasAlarm ? AppColors.error : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (timestamp.isNotEmpty)
                Text(timestamp, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

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
          Icon(Icons.notifications_off_outlined, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 28),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
