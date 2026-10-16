// 경로: lib/components/indices/main_index/main_index_components.dart
// 명세: 홈(내 시설) 카드 목록과, 호실 선택 화면이 함께 쓰는 격자 박스
import 'package:flutter/material.dart';
import 'package:idcs/components/facility/monitoring/room_status.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
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

    // The shadow sits outside the Material so it is not clipped by it.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: colors.cardShadow,
      ),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              // Only an alarm draws an outline; otherwise the lift is enough.
              border: hasAlarm ? Border.all(color: colors.error) : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // Empty means the server had no name for it.
                        facility.name.isEmpty
                            ? context.l10n.facilityUnnamed
                            : facility.name,
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
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                            ),
                            Text(
                              '  ·  ',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
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
      ),
    );
  }
}

/// Alarm state as words, not just a coloured dot, so the meaning is readable
/// without having to learn what the colour stands for.
class _StatusText extends StatelessWidget {
  final int count;

  const _StatusText({required this.count});

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
              ? context.l10n.countCases(context.l10n.statusActiveAlarms, count)
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
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        children: [
          Icon(
            Icons.domain_disabled_outlined,
            color: colors.textSecondary.withValues(alpha: 0.6),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Room picker grid. Carries the same alarm state as the facility card above it,
/// so the room that needs attention is visible before opening anything.
/// 호실 목록. 한 칸이 그 호실의 '지금'을 요약한다.
///
/// 예전에는 이름과 알람 배지뿐이라, 어느 호실이 몇 도인지 알려면 하나씩 열어
/// 봐야 했다. 10개 호실이면 열 번이다. 창고를 맡은 사람이 아침에 확인하고 싶은
/// 것은 그 열 번이 아니라 "지금 다 괜찮은가" 한 가지다. 그래서 한 칸에 네 가지를
/// 담는다 — 현재온도, 목표온도, 이상 유무, 제상·콤프 상태.
class RoomGrid extends StatelessWidget {
  final List<dynamic> rooms;

  /// Active alarm count per room id. A missing id simply counts as zero.
  final Map<int, int> activeAlarmCounts;

  /// 저장된 마지막 고내온도. 설비와 연결이 끊겨 실시간 값이 없을 때 쓴다.
  final Map<int, double> temperatures;

  /// 실시간 값. 호실 id -> (서버 필드 이름 -> 값).
  final Map<int, Map<String, String>> liveValues;

  final Function(int) onRoomPressed;
  final String? emptyMessage;

  const RoomGrid({
    super.key,
    required this.rooms,
    required this.activeAlarmCounts,
    required this.onRoomPressed,
    this.temperatures = const {},
    this.liveValues = const {},
    this.emptyMessage,
  });

  /// 설비가 보내는 참/거짓은 "ON"/"OFF" 로 오기도 하고 "1"/"0" 으로 오기도 한다.

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return _EmptyBox(message: emptyMessage ?? context.l10n.roomsEmpty);
    }

    // 개괄 화면과 생김새를 맞춘다. 같은 호실 카드가 화면마다 다르게 생기면
    // 어느 쪽이 무슨 뜻인지 두 번 배워야 한다.
    return ValueListenableBuilder<MonitoringViewSettings>(
      valueListenable: MonitoringViewController.settings,
      builder: (context, view, _) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          // 표시등 한 줄까지 들어가는 높이. 더 납작하게 두면 잘린다.
          childAspectRatio: 1.62,
        ),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          final colors = context.colors;
          final roomId = room['id'];
          final count = activeAlarmCounts[roomId] ?? 0;

          final live = liveValues[roomId] ?? const <String, String>{};

          // 실시간 값이 있으면 그것이 맞다. 없으면 마지막으로 저장된 값이라도 보인다.
          final status = RoomStatus.from(
            live,
            fallbackTemp: temperatures[roomId],
            alarmCount: count,
          );
          final accent = status.accent(colors);
          final attention = status.needsAttention;
          final temp = status.temp;
          final deviation = status.deviation;

          final defrost = RoomStatus.asSwitch(live['deforest_def']);
          final compressor = RoomStatus.asSwitch(live['control_runsw']);

          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: colors.cardShadow,
            ),
            child: Material(
              color: attention
                  ? Color.alphaBlend(accent.withValues(alpha: 0.07), colors.surface)
                  : colors.surface,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onRoomPressed(roomId),
                child: Container(
                  decoration: BoxDecoration(
                    border: attention
                        ? Border.all(color: accent.withValues(alpha: 0.55), width: 1.2)
                        : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 상태 띠. 격자를 훑을 때 눈이 제일 먼저 집는 자리다.
                      Container(width: 4, color: accent),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      room['name'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  if (count > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: colors.error.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: colors.error,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // 이 칸에서 가장 먼저 눈에 들어와야 하는 값.
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    temp == null ? '—' : temp.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 25,
                                      height: 1,
                                      fontWeight: FontWeight.w700,
                                      color: attention ? accent : colors.textPrimary,
                                      // 제어판과 같은 7세그먼트 서체. 수치일 때만 쓴다.
                                      fontFamily: temp != null && view.ledDigits
                                          ? MonitoringViewSettings.ledFontFamily
                                          : null,
                                      letterSpacing: temp != null && view.ledDigits ? 1 : null,
                                    ),
                                  ),
                                  if (temp != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 2, bottom: 2),
                                      child: Text(
                                        context.l10n.unitCelsius,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),

                              // 숫자 하나만으로는 그게 정상인지 알 수 없다.
                              Row(
                                children: [
                                  if (status.setpoint != null)
                                    Text(
                                      '${context.l10n.roomSetpointShort} ${status.setpoint!.toStringAsFixed(1)}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  if (deviation != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      'Δ ${deviation >= 0 ? '+' : ''}${deviation.toStringAsFixed(1)}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: status.condition == RoomCondition.drifting
                                            ? colors.warning
                                            : colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              // 제상·콤프는 값이 들어온 것만 내건다. 설비가 안 보내는
                              // 항목을 꺼진 등으로 보여주면 꺼져 있다는 뜻으로 읽힌다.
                              Expanded(
                                child: ClipRect(
                                  child: Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        if (defrost != null)
                                          StateLamp(label: context.l10n.roomStatusDefrost, on: defrost),
                                        if (compressor != null)
                                          StateLamp(label: context.l10n.roomStatusCompressor, on: compressor),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
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
        },
      ),
    );
  }
}

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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.colors.textSecondary,
              letterSpacing: 0.4,
            ),
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

              return DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: context.colors.cardShadow,
                ),
                child: Material(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onFacilityPressed(fac['id']),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        child: Text(
                          fac['name'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.colors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
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
