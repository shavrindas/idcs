// 경로: lib/components/indices/main_index/main_index_components.dart
// 명세: 홈(내 시설) 카드 목록과, 호실 선택 화면이 함께 쓰는 격자 박스
import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/l10n/l10n_context.dart';

/// One facility's at-a-glance state on the home screen.
/// [roomCount] is null while the room list is still loading or failed to load,
/// so the card can simply omit that line instead of showing a wrong "0 rooms".
class FacilitySummary {
  final int id;
  final String name;
  final int? roomCount;
  final int activeAlarmCount;

  const FacilitySummary({
    required this.id,
    required this.name,
    required this.roomCount,
    required this.activeAlarmCount,
  });
}

/// Home screen list of facilities.
/// Each row is full width because a facility carries more than a name: how many
/// rooms it has and whether anything is alarming right now.
class FacilitySummaryList extends StatelessWidget {
  final List<FacilitySummary> facilities;
  final Function(int) onFacilityPressed;
  /// Null falls back to the translated default at build time — a default
  /// parameter value cannot read the locale.
  final String? emptyMessage;

  const FacilitySummaryList({
    super.key,
    required this.facilities,
    required this.onFacilityPressed,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (facilities.isEmpty) {
      return _EmptyBox(message: emptyMessage ?? context.l10n.facilitiesEmpty);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final facility in facilities) ...[
          _FacilityCard(
            facility: facility,
            onTap: () => onFacilityPressed(facility.id),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final FacilitySummary facility;
  final VoidCallback onTap;

  const _FacilityCard({required this.facility, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasAlarm = facility.activeAlarmCount > 0;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: hasAlarm ? colors.error : colors.outline),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (facility.roomCount != null) ...[
                          Text(
                            context.l10n.roomCount(facility.roomCount!),
                            style: TextStyle(fontSize: 13, color: colors.textSecondary),
                          ),
                          Text(
                            '  ·  ',
                            style: TextStyle(fontSize: 13, color: colors.textSecondary),
                          ),
                        ],
                        _StatusText(count: facility.activeAlarmCount),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alarm state as words, not just a coloured dot, so the meaning is readable
/// without having to learn what the colour stands for.
class _StatusText extends StatelessWidget {
  final int count;

  /// Wording differs by level: a facility says 진행 중 알람 N건, a room just 알람 N건.
  /// Null means the facility-level wording; a room passes its own.
  final String? label;

  const _StatusText({required this.count, this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasAlarm = count > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: hasAlarm ? colors.error : colors.success,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          hasAlarm
              ? context.l10n.countCases(label ?? context.l10n.statusActiveAlarms, count)
              : context.l10n.statusNormal,
          style: TextStyle(
            fontSize: 13,
            fontWeight: hasAlarm ? FontWeight.w600 : FontWeight.w400,
            color: hasAlarm ? colors.error : colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String message;

  const _EmptyBox({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        children: [
          Icon(Icons.domain_disabled_outlined,
              color: colors.textSecondary.withValues(alpha: 0.6), size: 28),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Room picker grid. Carries the same alarm state as the facility card above it,
/// so the room that needs attention is visible before opening anything.
class RoomGrid extends StatelessWidget {
  final List<dynamic> rooms;

  /// Active alarm count per room id. A missing id simply counts as zero.
  final Map<int, int> activeAlarmCounts;
  final Function(int) onRoomPressed;
  final String? emptyMessage;

  const RoomGrid({
    super.key,
    required this.rooms,
    required this.activeAlarmCounts,
    required this.onRoomPressed,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) return _EmptyBox(message: emptyMessage ?? context.l10n.roomsEmpty);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.1,
      ),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        final colors = context.colors;
        final count = activeAlarmCounts[room['id']] ?? 0;
        final hasAlarm = count > 0;

        return Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onRoomPressed(room['id']),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: hasAlarm ? colors.error : colors.outline),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room['name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusText(count: count, label: context.l10n.alarmShort),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Box #2: 통합 시설 박스
/// Still used by the room picker, where entries are just names to choose from.
class IntegratedFacilityBox extends StatelessWidget {
  final List<dynamic> facilities;
  final Function(int) onFacilityPressed;
  final String? label;
  final String? emptyMessage;

  const IntegratedFacilityBox({
    super.key,
    required this.facilities,
    required this.onFacilityPressed,
    this.label,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A null or empty label means the screen already names this section in
        // its app bar.
        if (label != null && label!.isNotEmpty) ...[
          Text(
            label!,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.textSecondary, letterSpacing: 0.4),
          ),
          const SizedBox(height: 10),
        ],

        if (facilities.isEmpty)
          _EmptyBox(message: emptyMessage ?? context.l10n.facilitiesNoneVisible)
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5,
            ),
            itemCount: facilities.length,
            itemBuilder: (context, index) {
              final fac = facilities[index];

              return Material(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onFacilityPressed(fac['id']),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.colors.outline),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      child: Text(
                        fac['name'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: context.colors.textPrimary, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
