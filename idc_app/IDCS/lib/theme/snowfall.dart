// ===============================================================
// 경로: lib/theme/snowfall.dart
// 명세: 모든 화면 뒤에서 조용히 내리는 눈
// ===============================================================
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/theme/motion.dart';

/// 카드 뒤에서 눈이 내린다.
///
/// 냉동 창고를 보는 앱이라 눈은 장식이 아니라 그냥 이 일의 그림이다. 다만
/// 읽어야 할 것은 숫자지 눈이 아니라서, 눈에 띄면 그 순간 실패다. 그래서
/// 아주 옅게, 느리게, 그리고 **카드 뒤에서만** 내린다.
///
/// 한 장의 [CustomPaint] 로 전부 그린다. 눈송이마다 위젯을 두면 백 개짜리
/// 위젯 트리가 매 프레임 다시 그려진다.
class SnowfallBackground extends StatefulWidget {
  final Widget child;

  /// 꺼 두면 눈 없이 child 만 그린다. 설정에서 끌 수 있다.
  final bool enabled;

  const SnowfallBackground({super.key, required this.child, this.enabled = true});

  @override
  State<SnowfallBackground> createState() => _SnowfallBackgroundState();
}

class _SnowfallBackgroundState extends State<SnowfallBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // 한 바퀴 도는 데 걸리는 시간. 눈송이마다 속도가 달라서 이 길이가
    // 그대로 보이지는 않는다.
    duration: const Duration(seconds: 20),
  );

  late final List<_Flake> _flakes = _makeFlakes();

  bool _ready = false;

  static List<_Flake> _makeFlakes() {
    // 자리와 크기는 한 번만 정한다. 매번 새로 뽑으면 프레임마다 눈이
    // 순간이동한다.
    final rnd = Random(20251017);
    return List.generate(46, (_) {
      return _Flake(
        x: rnd.nextDouble(),
        phase: rnd.nextDouble(),
        // 작은 것이 많고 큰 것이 적어야 깊이가 생긴다.
        radius: 0.8 + rnd.nextDouble() * rnd.nextDouble() * 2.6,
        speed: 0.45 + rnd.nextDouble() * 0.9,
        sway: 0.004 + rnd.nextDouble() * 0.016,
        swayPhase: rnd.nextDouble() * pi * 2,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _sync();
  }

  @override
  void didUpdateWidget(SnowfallBackground old) {
    super.didUpdateWidget(old);
    if (old.enabled != widget.enabled) _sync();
  }

  void _sync() {
    // 끝없이 도는 움직임이라, 운영체제에서 줄이라고 하면 아예 돌리지 않는다.
    // 그래도 눈은 그려 둔다 — 멈춘 눈은 배경 무늬가 된다.
    if (widget.enabled && Motion.allowsLooping(context)) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Stack(
      children: [
        // 바탕색은 눈을 켜든 끄든 **반드시** 여기서 깐다. Scaffold 를 투명하게
        // 두었기 때문에 이 한 장이 앱 전체의 배경이고, 빠지면 화면이 검게
        // 비어 버린다.
        Positioned.fill(child: ColoredBox(color: colors.background)),
        if (widget.enabled)
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _SnowPainter(
                    flakes: _flakes,
                    t: _controller.value,
                    // 밝은 테마에서 흰 눈은 흰 바탕에 묻혀 안 보인다. 어두운
                    // 테마에서는 반대로 흰색이라야 눈처럼 보인다.
                    color: colors.isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : colors.primary.withValues(alpha: 0.26),
                  ),
                ),
              ),
            ),
          ),
        widget.child,
      ],
    );
  }
}

class _Flake {
  /// 가로 위치 (0~1).
  final double x;

  /// 세로 위치의 시작 지점 (0~1). 전부 같은 줄에서 떨어지지 않게 한다.
  final double phase;

  final double radius;

  /// 한 바퀴 동안 몇 번 떨어지는지.
  final double speed;

  /// 좌우로 흔들리는 폭 (화면 너비 대비).
  final double sway;
  final double swayPhase;

  const _Flake({
    required this.x,
    required this.phase,
    required this.radius,
    required this.speed,
    required this.sway,
    required this.swayPhase,
  });
}

class _SnowPainter extends CustomPainter {
  final List<_Flake> flakes;
  final double t;
  final Color color;

  _SnowPainter({required this.flakes, required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    for (final f in flakes) {
      // 0 에서 1 사이를 돌고 다시 위로 올라간다.
      final progress = (f.phase + t * f.speed) % 1.0;
      final y = progress * (size.height + 40) - 20;

      // 좌우로 천천히 흔들린다. 똑바로 떨어지면 비처럼 보인다.
      final dx = sin(progress * pi * 2 + f.swayPhase) * f.sway * size.width;

      canvas.drawCircle(Offset(f.x * size.width + dx, y), f.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SnowPainter old) => old.t != t || old.color != color;
}
