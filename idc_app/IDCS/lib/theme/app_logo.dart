// 경로: lib/theme/app_logo.dart
// 명세: IDCool 브랜드 마크 — 범용 머티리얼 아이콘이 아닌 워드마크/모노그램 기반
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// 정사각형 그라디언트 위에 소문자 이니셜을 얹은 모노그램.
/// 스플래시/앱바 등에서 로고로 사용.
class AppMonogram extends StatelessWidget {
  final double size;

  const AppMonogram({super.key, this.size = 88});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: size * 0.32,
            offset: Offset(0, size * 0.14),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'ic',
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1,
          letterSpacing: -1,
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
          color: baseColor ?? AppColors.textPrimary,
        ),
        children: const [
          TextSpan(text: 'ID'),
          TextSpan(text: 'Cool', style: TextStyle(color: AppColors.primary)),
        ],
      ),
    );
  }
}
