// 경로: lib/theme/responsive.dart
// 명세: 태블릿 등 넓은 화면에서도 카드/그리드가 듬성듬성해지지 않게 돕는 공용 도우미.
//
// 지금까지는 화면 폭을 보는 코드가 거의 없었다(차트 높이 정도). 여기서는
// Material 가이드의 폭 기준(600/840dp)을 그대로 따르는 가장 단순한 등급만
// 두고, 그리드 칸 수처럼 "폭이 넓을 때 뭘 더 보여줄지"가 필요한 자리에서만
// 쓴다. 전체 화면을 억지로 가운데 모으는 전역 래퍼는 앱바/하단 탭처럼 폭
// 전체를 쓰는 편이 자연스러운 요소까지 같이 좁혀버려서 두지 않았다 — 필요한
// 화면에서 개별적으로 쓰는 편이 안전하다.
import 'package:flutter/material.dart';

enum ScreenSize { phone, tablet, desktop }

extension ResponsiveContext on BuildContext {
  double get _screenWidth => MediaQuery.sizeOf(this).width;

  ScreenSize get screenSize {
    final w = _screenWidth;
    if (w >= 1024) return ScreenSize.desktop;
    if (w >= 600) return ScreenSize.tablet;
    return ScreenSize.phone;
  }

  bool get isTablet => screenSize != ScreenSize.phone;

  /// 카드 그리드 한 줄의 칸 수. 폰 2 / 태블릿 3 / 큰 화면(가로모드 태블릿 등) 4.
  int gridColumns({int phone = 2, int tablet = 3, int desktop = 4}) {
    switch (screenSize) {
      case ScreenSize.phone:
        return phone;
      case ScreenSize.tablet:
        return tablet;
      case ScreenSize.desktop:
        return desktop;
    }
  }
}
