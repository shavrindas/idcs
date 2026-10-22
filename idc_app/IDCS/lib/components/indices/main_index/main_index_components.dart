// 경로: lib/components/indices/main_index/main_index_components.dart
// 명세: 시설 안 호실 선택 격자
//
// 원래는 '내 시설' 홈 화면의 시설 카드 목록도 여기 있었다. 그 화면이 전체
// 현황에 흡수되면서 쓰는 곳이 없어져 걷어냈다 — 파일 이름은 그대로 두었다.
// 옮기면 다른 사람 브랜치와 부딪힌다.
import 'package:flutter/material.dart';
import 'package:idcs/components/facility/monitoring/room_status.dart';
import 'package:idcs/components/facility/monitoring/temperature_readout.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/l10n/l10n_context.dart';


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
/// 것은 그 열 번이 아니라 "지금 다 괜찮은가" 한 가지다. 그래서 한 칸이 그 답을
/// 바로 보여준다 — 현재온도, 목표온도, 설정값과의 차이, 제상·콤프, 알람 수,
/// 그리고 아래쪽 상태 띠.
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
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onRoomPressed(roomId),
                child: Container(
                  decoration: BoxDecoration(
                    // Only faults get an outline; a drifting card is already tinted and
                    // the extra yellow ring read as a rendering glitch.
                    border: status.condition == RoomCondition.fault
                        ? Border.all(color: accent.withValues(alpha: 0.55), width: 1.2)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
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
                              TemperatureReadout(
                                temp: temp,
                                // Digits take the status colour too: green, yellow or red.
                                color: status.condition == RoomCondition.offline ? colors.textPrimary : accent,
                                ledDigits: view.ledDigits,
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
                      // 상태 띠. 개괄 화면과 같은 자리, 같은 색, 같은 속도다.
                      StatusRail(color: status.railColor(colors), index: index),
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

