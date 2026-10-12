// 경로: lib/theme/app_theme.dart
// 명세: 앱 전역 디자인 토큰(색상/타이포/컴포넌트 테마) — 연한 테마와 어두운 테마
import 'package:flutter/material.dart';

/// 화면에서 쓰는 색 묶음. 테마에 따라 통째로 바뀐다.
///
/// 색을 `AppColors.surface`처럼 정적으로 읽으면 테마가 바뀌어도 값이 그대로여서
/// 어두운 모드를 만들 수 없다. ThemeExtension으로 올려두고 `context.colors.surface`
/// 처럼 읽으면 현재 테마에 맞는 값이 나온다.
///
/// 모든 값은 WCAG 대비 기준을 만족하도록 계산해서 골랐다.
/// 본문 텍스트 4.5:1, 컨트롤 경계선 3:1, 장식 테두리 1.5:1 이상.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;

  /// 기본 버튼처럼 primary를 배경으로 깔았을 때 그 위에 올라가는 글자색.
  /// 어두운 테마의 primary는 밝은 파랑이라 흰 글자를 올리면 대비가 2.58밖에 안 된다.
  final Color onPrimary;

  final Color background;
  final Color surface;

  /// 카드/구분선용 장식 테두리.
  final Color outline;

  /// 입력창·컨트롤의 경계선. 장식이 아니므로 대비 3:1을 지킨다.
  final Color outlineStrong;

  final Color textPrimary;
  final Color textSecondary;

  final Color error;
  final Color warning;
  final Color success;

  const AppPalette({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.outline,
    required this.outlineStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.error,
    required this.warning,
    required this.success,
  });

  static const AppPalette light = AppPalette(
    primary: Color(0xFF2E6BEF),
    primaryLight: Color(0xFF5C8DF5),
    primaryDark: Color(0xFF1E4FBD),
    onPrimary: Color(0xFFFFFFFF),
    background: Color(0xFFF5F8FA),
    surface: Color(0xFFFFFFFF),
    outline: Color(0xFFC0CED6),
    outlineStrong: Color(0xFF7B99A8),
    textPrimary: Color(0xFF16232A),
    textSecondary: Color(0xFF5B6B73),
    error: Color(0xFFD54141),
    warning: Color(0xFFA26B1C),
    success: Color(0xFF1D875A),
  );

  static const AppPalette dark = AppPalette(
    primary: Color(0xFF6FA0FF),
    primaryLight: Color(0xFF9BBEFF),
    primaryDark: Color(0xFF3F79E0),
    // 밝은 파랑 위에는 어두운 글자라야 읽힌다 (7.12:1)
    onPrimary: Color(0xFF0F151C),
    background: Color(0xFF0F151C),
    // 어두운 배경에서는 그림자가 거의 보이지 않으므로, 카드는 면을 한 단계
    // 밝혀서 띄운다. 배경 대비 1.37:1 — 선을 두르지 않아도 가장자리가 보인다.
    surface: Color(0xFF223040),
    outline: Color(0xFF36454F),
    outlineStrong: Color(0xFF6B7D8A),
    textPrimary: Color(0xFFE9EEF3),
    textSecondary: Color(0xFF9FB0BC),
    error: Color(0xFFFF6B6B),
    warning: Color(0xFFE0A94A),
    success: Color(0xFF4ECB8D),
  );

  bool get isDark => background.computeLuminance() < 0.5;

  /// 일반 카드용 높이감. 선을 두르는 대신 이것으로 바닥에서 띄운다.
  ///
  /// 밝은 테마에서 카드(#FFFFFF)와 배경(#F5F8FA)의 차이는 1.07:1 뿐이라
  /// 면 색만으로는 카드가 보이지 않는다 — 그림자가 그 역할을 한다.
  /// 어두운 테마는 반대로 그림자가 묻히므로, surface 를 밝혀 둔 것이 주역이고
  /// 여기서는 가장자리에 약간의 깊이만 더한다.
  List<BoxShadow> get cardShadow => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];

  /// 특별히 더 띄워야 하는 표면에만 (모달, 떠 있는 패널 등).
  /// 어두운 배경에서는 그림자가 거의 보이지 않으므로 더 진하게 깐다.
  List<BoxShadow> get softShadow => [
        BoxShadow(
          color: isDark ? Colors.black.withValues(alpha: 0.45) : primary.withValues(alpha: 0.10),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: isDark ? Colors.black.withValues(alpha: 0.30) : const Color(0xFF0B1420).withValues(alpha: 0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  /// 차트 시리즈 색. 데이터 색이라 테마와 무관하게 쓰되, 어두운 배경에서도
  /// 보이도록 테마별로 밝기를 다르게 둔다.
  List<Color> get chartSeries => isDark
      ? const [
          Color(0xFF6FA0FF),
          Color(0xFFFF6B6B),
          Color(0xFF4ECB8D),
          Color(0xFFE0A94A),
          Color(0xFFB08BFF),
          Color(0xFF4DD0C7),
        ]
      : const [
          Color(0xFF2E6BEF),
          Color(0xFFD54141),
          Color(0xFF1D875A),
          Color(0xFFA26B1C),
          Color(0xFF1E4FBD),
          Color(0xFF00897B),
        ];

  @override
  AppPalette copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? onPrimary,
    Color? background,
    Color? surface,
    Color? outline,
    Color? outlineStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? error,
    Color? warning,
    Color? success,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      onPrimary: onPrimary ?? this.onPrimary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      outline: outline ?? this.outline,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      success: success ?? this.success,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineStrong: Color.lerp(outlineStrong, other.outlineStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

/// `context.colors.surface` 처럼 현재 테마의 색을 읽는다.
extension AppPaletteContext on BuildContext {
  AppPalette get colors => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppPalette.light, Brightness.light);
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      surface: p.surface,
      error: p.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.background,
      fontFamily: 'Roboto',
      extensions: [p],
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: p.textPrimary,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: p.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: p.textSecondary,
          height: 1.5,
        ),
        labelLarge: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: p.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      // 머티리얼 기본값은 secondaryContainer 라서 앱의 파랑과 따로 놀았다.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 3,
        extendedTextStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size(64, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          minimumSize: const Size(64, 52),
          side: BorderSide(color: p.primary, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: p.textSecondary),
        labelStyle: TextStyle(color: p.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.outlineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.outlineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.error),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.primary : Colors.transparent,
        ),
        side: BorderSide(color: p.outlineStrong, width: 1.5),
      ),
      dividerTheme: DividerThemeData(
        color: p.outline,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.outline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        titleTextStyle: TextStyle(color: p.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
        contentTextStyle: TextStyle(color: p.textSecondary, fontSize: 14, height: 1.5),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.isDark ? p.surface : const Color(0xFF2B3843),
        contentTextStyle: TextStyle(color: p.isDark ? p.textPrimary : Colors.white, fontSize: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.primary.withValues(alpha: 0.16),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? p.primary : p.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? p.primary : p.textSecondary,
          ),
        ),
      ),
    );
  }
}
