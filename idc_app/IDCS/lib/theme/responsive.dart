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

  /// 카드 그리드 한 줄의 칸 수. 칸을 너무 늘리면 카드 하나하나가 좁아져
  /// 오히려 더 작아 보인다 — 태블릿은 폰보다 한 칸만 더 둔다.
  int gridColumns({int phone = 2, int tablet = 2, int desktop = 3}) {
    switch (screenSize) {
      case ScreenSize.phone:
        return phone;
      case ScreenSize.tablet:
        return tablet;
      case ScreenSize.desktop:
        return desktop;
    }
  }

  /// 칸 수를 늘리는 것만으로는 카드 하나하나가 그대로 작게 남는다. 글자·숫자·
  /// 여백을 같이 키워야 카드가 "커 보인다" — 태블릿 화면을 실제로 채운다.
  double get uiScale {
    switch (screenSize) {
      case ScreenSize.phone:
        return 1.0;
      case ScreenSize.tablet:
        return 1.4;
      case ScreenSize.desktop:
        return 1.6;
    }
  }

  /// 글자 크기·여백·아이콘 크기 등을 화면 크기에 맞춰 키운다.
  double scale(double base) => base * uiScale;
}
