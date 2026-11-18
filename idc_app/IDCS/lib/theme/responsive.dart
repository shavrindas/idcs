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

  bool get _isLandscape => MediaQuery.orientationOf(this) == Orientation.landscape;

  /// 카드 그리드 한 줄의 칸 수.
  ///
  /// 폰은 눕히면 호실 한 칸을 보는 화면(RoomWatchPager)으로 바뀌는 자리가
  /// 따로 있어 격자를 눕혀 볼 일이 없다 — 방향과 무관하게 그대로 둔다.
  ///
  /// 태블릿·큰 화면은 눕혔을 때 폭이 남는데도 세로와 같은 칸 수만 채우면
  /// 카드가 쓸데없이 커지고 줄마다 빈자리만 늘어난다. 세로/가로를 따로
  /// 두고, [extended](설정 → 그리드 보기 → 확장)를 켜면 한 칸씩 더 늘려
  /// 카드를 줄이고 한 화면에 더 담는다.
  int gridColumns({int phone = 2, bool extended = false}) {
    if (screenSize == ScreenSize.phone) return phone;

    final portrait = extended ? 3 : 2;
    final landscape = extended ? 4 : 3;
    return _isLandscape ? landscape : portrait;
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
