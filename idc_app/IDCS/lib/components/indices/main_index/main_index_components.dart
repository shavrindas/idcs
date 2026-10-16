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
              ? context.l10n.countCases(
                  label ?? context.l10n.statusActiveAlarms,
                  count,
                )
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
  /// 둘 다 같은 뜻으로 읽는다. 알 수 없는 값이면 아예 보여주지 않는다.
  static bool? _asSwitch(String? raw) {
    final v = raw?.trim().toUpperCase();
    if (v == null || v.isEmpty || v == 'NA') return null;
    if (v == 'ON' || v == '1' || v == 'TRUE') return true;
    if (v == 'OFF' || v == '0' || v == 'FALSE') return false;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return _EmptyBox(message: emptyMessage ?? context.l10n.roomsEmpty);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        // 네 가지를 담되, 호실이 열 개여도 첫 화면에 다 들어와야 한다.
        // 한 칸이라도 더 높으면 마지막 줄이 잘린다.
        childAspectRatio: 1.55,
      ),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        final colors = context.colors;
        final roomId = room['id'];
        final count = activeAlarmCounts[roomId] ?? 0;
        final hasAlarm = count > 0;

        final live = liveValues[roomId] ?? const <String, String>{};

        // 실시간 값이 있으면 그것이 맞다. 없으면 마지막으로 저장된 값이라도 보인다.
        final temp = double.tryParse(live['temp_pv'] ?? '') ?? temperatures[roomId];
        final setpoint = double.tryParse(live['temp_sv'] ?? '');
        final defrost = _asSwitch(live['deforest_def']);
        final compressor = _asSwitch(live['control_runsw']);

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
              onTap: () => onRoomPressed(roomId),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: hasAlarm ? Border.all(color: colors.error) : null,
                ),
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room['name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // 이 칸에서 가장 먼저 눈에 들어와야 하는 값.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          temp == null ? '—' : temp.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 24,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (temp != null)
                          Text(
                            context.l10n.unitCelsius,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                        const Spacer(),
                        if (setpoint != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${context.l10n.roomSetpointShort} ${setpoint.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const Spacer(),
                    _StatusText(count: count, label: context.l10n.alarmShort),

                    // 제상·콤프는 값이 들어온 것만 내건다. 설비가 안 보내는
                    // 항목을 'OFF' 로 보여주면 꺼져 있다는 뜻으로 읽힌다.
                    if (defrost != null || compressor != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (defrost != null)
                            StatePill(label: context.l10n.roomStatusDefrost, on: defrost),
                          if (defrost != null && compressor != null) const SizedBox(width: 6),
                          if (compressor != null)
                            StatePill(label: context.l10n.roomStatusCompressor, on: compressor),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 켜짐/꺼짐 한 가지를 작게 표시한다.
///
/// 켜진 것만 색을 입힌다. 둘 다 색이 있으면 칸마다 알록달록해져서, 정작
/// 눈에 띄어야 할 알람 테두리가 묻힌다.
/// 켜짐/꺼짐 한 가지를 작게 표시한다. 개괄 화면도 같은 것을 쓴다.
class StatePill extends StatelessWidget {
  final String label;
  final bool on;

  /// 켜진 것이 '나쁜 소식'인 항목인지. 이상·CINT·HIGH 처럼 고장 플래그는
  /// 켜졌을 때 빨갛게 보여야 하고, 콤프·제상처럼 평소 동작은 그러면 안 된다.
  final bool danger;

  const StatePill({super.key, required this.label, required this.on, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = danger ? colors.error : colors.primary;
    final color = on ? accent : colors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: on ? accent.withValues(alpha: 0.10) : colors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label ${on ? context.l10n.roomStatusOn : context.l10n.roomStatusOff}',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
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
