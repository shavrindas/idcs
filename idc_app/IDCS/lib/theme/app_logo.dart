// 경로: lib/theme/app_logo.dart
// 명세: IDCool 브랜드 마크 — 범용 머티리얼 아이콘이 아닌 워드마크/모노그램 기반
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// 앱 로고.
///
/// 전에는 'ic' 두 글자를 그라디언트 사각형에 얹어 자리만 잡아 두었다.
/// 이제 실제 로고 이미지를 쓴다 — 런처 아이콘, 안드로이드 스플래시와 같은
/// 그림이라 앱을 누른 순간부터 첫 화면까지 같은 것이 이어진다.
class AppMonogram extends StatelessWidget {
  final double size;

  const AppMonogram({super.key, this.size = 88});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withValues(alpha: 0.28),
            blurRadius: size * 0.32,
            offset: Offset(0, size * 0.14),
          ),
        ],
      ),
      child: ClipRRect(
        // 원본 이미지가 이미 둥근 사각형이지만, 그림자와 모서리를 같은
        // 반지름으로 맞추려면 한 번 더 깎아야 가장자리가 어긋나지 않는다.
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          'assets/brand/idcool_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// "ID" + "Cool" 2색 워드마크. 앱바/헤더처럼 작은 영역에 사용.
class AppWordmark extends StatelessWidget {
  final double fontSize;
  final Color? baseColor;

  const AppWordmark({super.key, this.fontSize = 18, this.baseColor});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: baseColor ?? context.colors.textPrimary,
        ),
        children: [
          TextSpan(text: 'ID'),
          TextSpan(text: 'Cool', style: TextStyle(color: context.colors.primary)),
        ],
      ),
    );
  }
}
