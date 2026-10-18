// ===============================================================
// 경로: lib/components/shared/skeleton.dart
// 명세: 불러오는 동안 들어올 내용의 모양을 미리 그려 두는 자리
// ===============================================================
import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/theme/motion.dart';

/// 반짝임을 한 번만 돌리고 아래로 내려 준다.
///
/// 스켈레톤 칸마다 컨트롤러를 하나씩 두면 열 칸이면 열 개가 따로 돈다.
/// 같은 박자로 움직여야 하나의 면처럼 보이기도 하고, 그편이 싸다.
class Skeleton extends StatefulWidget {
  final Widget child;

  const Skeleton({super.key, required this.child});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool _started = false;

  // MediaQuery 는 initState 에서 못 읽는다(InheritedWidget 의존이 아직 안 잡혀
  // 있다). 그래서 여기서 한 번만 시작한다.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // 끝없이 도는 움직임은 불러오는 표시에만 쓴다. 그마저도 운영체제에서
    // 줄이라고 하면 돌리지 않는다 — 멈춘 회색 칸으로도 자리는 전해진다.
    if (Motion.allowsLooping(context)) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => _ShimmerScope(t: _controller.value, child: child!),
      child: widget.child,
    );
  }
}

class _ShimmerScope extends InheritedWidget {
  final double t;

  const _ShimmerScope({required this.t, required super.child});

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.t ?? 0;

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) => oldWidget.t != t;
}

/// 글자나 값이 들어올 자리 하나.
///
/// 실제로 들어올 것과 **같은 크기**여야 한다. 작게 그려 두면 내용이 도착하는
/// 순간 주변이 밀려나고, 그 덜컥거림이 느려 보이는 가장 큰 이유가 된다.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = _ShimmerScope.of(context);

    final base = colors.textSecondary.withValues(alpha: colors.isDark ? 0.16 : 0.11);
    final highlight = colors.textSecondary.withValues(alpha: colors.isDark ? 0.07 : 0.04);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        // 왼쪽에서 오른쪽으로 한 번 쓸고 지나간다.
        gradient: LinearGradient(
          begin: Alignment(-1 - 2 * (1 - t), 0),
          end: Alignment(1 - 2 * (1 - t), 0),
          colors: [base, highlight, base],
          stops: const [0.35, 0.5, 0.65],
        ),
      ),
    );
  }
}

/// 호실 격자가 들어올 자리.
///
/// 진짜 카드와 같은 칸 수, 같은 비율, 같은 줄 배치다. 불러오기가 끝나도
/// 격자가 제자리에 있고 안쪽만 채워진다.
class RoomGridSkeleton extends StatelessWidget {
  /// 몇 칸을 그려 둘지. 호실 수를 아직 모를 때는 네 칸이면 충분하다 —
  /// 화면을 채우면서도, 실제가 두 칸일 때 빈자리가 크게 남지 않는다.
  final int count;

  /// 카드 한 칸의 가로세로 비율. 쓰는 쪽 격자와 같아야 한다.
  final double aspectRatio;

  const RoomGridSkeleton({super.key, this.count = 4, required this.aspectRatio});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Skeleton(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: aspectRatio,
        ),
        itemCount: count,
        itemBuilder: (context, index) => DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: colors.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 64, height: 13),
                const SizedBox(height: 10),
                const SkeletonBox(width: 96, height: 24, radius: 4),
                const SizedBox(height: 8),
                const SkeletonBox(width: 78, height: 11),
                const Spacer(),
                Row(
                  children: const [
                    SkeletonBox(width: 46, height: 16, radius: 5),
                    SizedBox(width: 5),
                    SkeletonBox(width: 46, height: 16, radius: 5),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 알람 목록이 들어올 자리.
class AlarmListSkeleton extends StatelessWidget {
  final int count;

  const AlarmListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Skeleton(
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: colors.cardShadow,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(17, 14, 14, 14),
                child: Row(
                  children: const [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 150, height: 14),
                          SizedBox(height: 7),
                          SkeletonBox(width: 70, height: 11),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SkeletonBox(width: 42, height: 12),
                        SizedBox(height: 7),
                        SkeletonBox(width: 82, height: 11),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
