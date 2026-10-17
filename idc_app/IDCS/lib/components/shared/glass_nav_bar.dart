// ===============================================================
// 경로: lib/components/shared/glass_nav_bar.dart
// 명세: 화면 아래에 떠 있는 알약 모양 네비게이션
// ===============================================================
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/theme/motion.dart';

/// 네비게이션 한 칸.
class GlassNavItem {
  final IconData icon;

  /// 골랐을 때의 아이콘. 없으면 [icon] 을 그대로 쓴다.
  final IconData? selectedIcon;

  final String label;

  const GlassNavItem({required this.icon, this.selectedIcon, required this.label});
}

/// 화면 폭을 다 쓰지 않고 가운데에 떠 있는 네비게이션.
///
/// 꽉 찬 막대는 화면을 가로로 잘라서, 그 위의 내용이 거기서 끝난 것처럼
/// 보인다. 띄워 두면 목록이 그 아래로 이어진다는 것이 그대로 보인다.
///
/// 뒤는 흐리게 비친다. 뒤에서 눈이 내리고 있는데 막대가 불투명하면 그
/// 띠에서만 눈이 사라져 오려 붙인 것처럼 보인다. 흐리게 비치면 같은
/// 화면 위에 놓인 유리판이 된다.
class GlassNavBar extends StatelessWidget {
  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const GlassNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      top: false,
      child: Padding(
        // 화면 가장자리에서 띄운다. 아래쪽은 제스처 바와 겹치지 않을 만큼.
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            // 막대 하나에만 걸리는 블러라 비용이 작다. 카드마다 걸면
            // 스크롤이 무거워진다.
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                // 유리의 두께. 완전히 투명하면 글자가 뒤 내용과 겹쳐 읽히지
                // 않고, 불투명하면 유리가 아니다.
                color: colors.surface.withValues(alpha: colors.isDark ? 0.72 : 0.78),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: colors.isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.white.withValues(alpha: 0.65),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavButton(
                          item: items[i],
                          selected: i == selectedIndex,
                          onTap: () => onSelected(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = selected ? colors.primary : colors.textSecondary;

    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.fast),
            curve: Motion.enter,
            // 고른 칸만 바탕이 생긴다. 네 칸을 다 칠하면 어느 것이 지금
            // 자리인지 알 수 없다.
            decoration: BoxDecoration(
              color: selected ? colors.primary.withValues(alpha: 0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            // 손가락이 닿을 자리. 아이콘만 48dp 아래로 내려가지 않게 한다.
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? (item.selectedIcon ?? item.icon) : item.icon,
                  size: 22,
                  color: tint,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: tint,
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
