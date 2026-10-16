// ===============================================================
// 경로: lib/components/facility/monitoring/room_status.dart
// 명세: 실시간 값 한 묶음에서 "이 호실 지금 괜찮은가" 한 가지를 뽑아낸다
// ===============================================================
import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';

/// 호실 하나의 지금 상태.
///
/// 카드가 열 개 깔린 화면에서 사람이 하려는 일은 값을 읽는 것이 아니라
/// "어디가 문제인가" 찾는 것이다. 그런데 온도·설정값·플래그를 각각 읽어
/// 머릿속에서 합치는 일을 화면이 사람에게 떠넘기고 있었다 — 카드 열 개가
/// 똑같이 하얗게 생겼으니 하나하나 읽어야 했다.
///
/// 그 판단을 여기서 한 번 해 두고, 화면은 결과를 색으로만 쓴다. 개괄 화면과
/// '내 시설'의 호실 목록이 같은 기준으로 판단하도록 한자리에 모아 둔다.
enum RoomCondition {
  /// 설정값 근처에서 돌고 있고 올라온 이상도 없다.
  normal,

  /// 설정값에서 [RoomStatus.driftThreshold] 넘게 벗어났다. 아직 알람은
  /// 아니지만 눈으로 확인할 값이다.
  drifting,

  /// emergency_* 중 하나라도 켜져 있거나 알람이 올라와 있다.
  fault,

  /// 값이 아예 없다. 설비와 끊겼거나 아직 한 번도 못 받았다.
  offline,
}

@immutable
class RoomStatus {
  final RoomCondition condition;

  /// 고내온도(temp_pv). 없으면 null.
  final double? temp;

  /// 설정온도(temp_sv). 없으면 null.
  final double? setpoint;

  /// 지금 제상 중인지. 제상 판단에 쓰고, 칩으로도 그린다.
  final bool defrosting;

  /// 켜져 있는 이상 플래그 개수.
  final int faultCount;

  const RoomStatus({
    required this.condition,
    required this.temp,
    required this.setpoint,
    required this.defrosting,
    required this.faultCount,
  });

  /// 이만큼 벗어나면 눈으로 확인할 값으로 본다.
  ///
  /// 포인트 롤에 상·하한을 넣어 두면 서버가 알람을 띄우지만, 지금 등록된
  /// temp_pv 롤에는 상·하한이 비어 있어서 온도 알람이 한 번도 뜬 적이 없다.
  /// 그게 채워지기 전까지도 화면은 "뭔가 이상하다"를 보여줄 수 있어야 하므로,
  /// 설정값과의 차이로 자체 판단한다.
  static const double driftThreshold = 2.0;

  /// 설비가 보내는 참/거짓. "ON"/"OFF" 로도, "1"/"0" 으로도, "0.0" 처럼
  /// 소수로도 온다(temp_comp 가 그렇다). 알 수 없는 값이면 null —
  /// 안 오는 값을 OFF 로 그리면 '꺼져 있다'는 거짓말이 된다.
  static bool? asSwitch(String? raw) {
    final v = raw?.trim().toUpperCase();
    if (v == null || v.isEmpty || v == 'NA' || v == '-') return null;
    if (v == 'ON' || v == 'TRUE') return true;
    if (v == 'OFF' || v == 'FALSE') return false;

    final n = double.tryParse(v);
    return n == null ? null : n != 0;
  }

  /// [values] 는 "필드 이름 -> 값" 한 호실 분량.
  ///
  /// [fallbackTemp] 는 마지막으로 저장된 고내온도. 실시간 값이 없을 때만 쓴다.
  /// [alarmCount] 는 알람 API 로 따로 받아 둔 개수('내 시설' 쪽에서 쓴다).
  factory RoomStatus.from(
    Map<String, String> values, {
    double? fallbackTemp,
    int alarmCount = 0,
  }) {
    double? number(String key) => double.tryParse(values[key]?.trim() ?? '');

    final temp = number('temp_pv') ?? fallbackTemp;
    final setpoint = number('temp_sv');
    final defrosting = asSwitch(values['deforest_def']) ?? false;

    final flags = values.entries
        .where((e) => e.key.startsWith('emergency_') && (asSwitch(e.value) ?? false))
        .length;
    final faults = flags + alarmCount;

    final RoomCondition condition;
    if (faults > 0) {
      condition = RoomCondition.fault;
    } else if (temp == null) {
      condition = RoomCondition.offline;
    } else if (!defrosting &&
        setpoint != null &&
        (temp - setpoint).abs() >= driftThreshold) {
      // 제상 중에는 온도가 올라가는 것이 정상 동작이다. 그때까지 이탈로
      // 잡으면 하루에 몇 번씩 멀쩡한 호실이 노랗게 뜬다.
      condition = RoomCondition.drifting;
    } else {
      condition = RoomCondition.normal;
    }

    return RoomStatus(
      condition: condition,
      temp: temp,
      setpoint: setpoint,
      defrosting: defrosting,
      faultCount: faults,
    );
  }

  /// 설정값과의 차이. 둘 중 하나라도 없으면 null.
  double? get deviation =>
      (temp == null || setpoint == null) ? null : temp! - setpoint!;

  bool get needsAttention =>
      condition == RoomCondition.fault || condition == RoomCondition.drifting;

  /// 이 상태를 나타내는 색. 카드 띠·숫자·요약 띠가 모두 이 색을 쓴다.
  Color accent(AppPalette colors) => switch (condition) {
        RoomCondition.fault => colors.error,
        RoomCondition.drifting => colors.warning,
        RoomCondition.normal => colors.success,
        RoomCondition.offline => colors.textSecondary,
      };
}

/// 설비 상태 표시등 한 개.
///
/// 전에는 "제상 OFF" 처럼 글자로 켜짐/꺼짐을 적었다. 한 카드에 다섯 개가
/// 붙으니 화면에 ON/OFF 라는 글자가 쉰 개 깔리고, 그 틈에서 켜진 하나를
/// 찾아 읽어야 했다. 실제 제어반처럼 불이 들어오는 모양으로 바꾸면 글자를
/// 읽지 않고 색만 보고 넘어갈 수 있다. 보여주는 항목 수는 그대로다.
class StateLamp extends StatelessWidget {
  final String label;
  final bool on;

  /// 켜진 것이 '나쁜 소식'인 항목인지. 이상·CINT·HIGH 는 켜지면 빨갛고,
  /// 콤프·제상처럼 평소 동작은 그러면 안 된다.
  final bool danger;

  const StateLamp({
    super.key,
    required this.label,
    required this.on,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = danger ? colors.error : colors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: on ? accent.withValues(alpha: 0.12) : colors.background,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 켜지면 속이 찬 점, 꺼지면 테두리만 남은 점.
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? accent : Colors.transparent,
              border: on
                  ? null
                  : Border.all(color: colors.textSecondary.withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: on ? accent : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
