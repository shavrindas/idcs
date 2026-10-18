// ===============================================================
// 경로: lib/theme/motion.dart
// 명세: 앱이 쓰는 움직임의 길이와 가속 곡선
// ===============================================================
import 'package:flutter/material.dart';

/// 움직임 토큰.
///
/// 길이를 화면마다 따로 적으면 같은 종류의 변화가 화면마다 다른 속도로
/// 일어난다. 거리와 하는 일에 따라 셋으로 나눠 두고 그것만 쓴다.
///
/// 이 앱에서 움직임은 장식이 아니다. 설비를 보는 화면이라 눈이 숫자에
/// 가 있어야 하고, 그 옆에서 뭔가 계속 움직이면 방해만 된다. 그래서
/// 움직이는 것은 '뜻이 있는 변화'로 제한한다 — 호실이 정상에서 이상으로
/// 넘어가는 순간, 접힌 것이 펼쳐지는 순간 같은 것들이다.
class Motion {
  Motion._();

  /// 눌렀을 때의 반응, 작은 페이드. 이보다 길면 굼떠 보인다.
  static const Duration fast = Duration(milliseconds: 120);

  /// 상태 색이 바뀌거나 접힌 것이 펼쳐질 때.
  static const Duration normal = Duration(milliseconds: 220);

  /// 화면에 처음 들어오는 것, 스켈레톤이 실제 내용으로 바뀔 때.
  static const Duration slow = Duration(milliseconds: 380);

  /// 들어올 때. 빠르게 시작해 부드럽게 멈춘다.
  static const Curve enter = Curves.easeOutCubic;

  /// 나갈 때는 들어올 때보다 짧게 — 사라지는 것을 기다릴 이유가 없다.
  static const Curve exit = Curves.easeInCubic;

  /// 운영체제에서 '애니메이션 줄이기'를 켜 두면 전부 0 으로 만든다.
  ///
  /// 멀미를 느끼는 사람이 있고, 접근성 설정에서 꺼 둔 것은 취향이 아니라
  /// 요구다. 길이만 0 으로 바꾸면 결과는 그대로이고 중간 과정만 사라진다.
  static Duration of(BuildContext context, Duration duration) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
          ? Duration.zero
          : duration;

  /// 끝없이 도는 움직임(스켈레톤의 반짝임 등)을 써도 되는지.
  static bool allowsLooping(BuildContext context) =>
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
}
