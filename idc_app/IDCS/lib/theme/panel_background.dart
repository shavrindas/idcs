// ===============================================================
// 경로: lib/theme/panel_background.dart
// 명세: 실시간 제어판 뒤에 깔리는 배경 패턴 모음
// ===============================================================
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:idcs/l10n/app_localizations.dart';
import 'package:idcs/theme/app_theme.dart';

/// A backdrop the user can pick for the live control panel.
///
/// These are painted rather than shipped as images: a painter weighs nothing,
/// stays sharp at any screen size, and can read the current theme's colours, so
/// one entry covers both light and dark instead of needing two files. The
/// `assets/backgrounds/` folder is registered in pubspec for the day a real
/// photograph is preferred — such an entry would carry [assetPath] instead.
@immutable
class PanelBackground {
  final String id;

  /// Shown in 설정. Resolved at build time so it follows the chosen language.
  final String Function(AppLocalizations) labelOf;

  /// Builds the painter for the current palette. Null means "no pattern".
  final CustomPainter Function(AppPalette colors)? painterOf;

  /// Reserved for image-backed entries added later.
  final String? assetPath;

  const PanelBackground({
    required this.id,
    required this.labelOf,
    this.painterOf,
    this.assetPath,
  });

  static const String defaultId = 'none';

  static final List<PanelBackground> all = [
    PanelBackground(id: 'none', labelOf: (l) => l.backgroundNone),
    PanelBackground(
      id: 'blueprint',
      labelOf: (l) => l.backgroundBlueprint,
      painterOf: (colors) => _BlueprintPainter(colors),
    ),
    PanelBackground(
      id: 'coil',
      labelOf: (l) => l.backgroundCoil,
      painterOf: (colors) => _CoilPainter(colors),
    ),
    PanelBackground(
      id: 'metal',
      labelOf: (l) => l.backgroundMetal,
      painterOf: (colors) => _MetalPainter(colors),
    ),
    PanelBackground(
      id: 'grid',
      labelOf: (l) => l.backgroundGrid,
      painterOf: (colors) => _GridPainter(colors),
    ),
  ];

  static PanelBackground byId(String id) {
    return all.firstWhere((b) => b.id == id, orElse: () => all.first);
  }
}

/// Draws the chosen backdrop, filling whatever space it is given.
class PanelBackdrop extends StatelessWidget {
  final String backgroundId;

  const PanelBackdrop({super.key, required this.backgroundId});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final background = PanelBackground.byId(backgroundId);
    final painter = background.painterOf?.call(colors);

    return Container(
      color: colors.background,
      child: painter == null ? null : CustomPaint(painter: painter, size: Size.infinite),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters
//
// Every pattern is drawn in a narrow luminance band around the page background.
// That is deliberate: a panel at the lowest allowed opacity still has to leave
// its readings legible, and a high-contrast backdrop is what would break that.
// ---------------------------------------------------------------------------

/// Shared helper: the ink these patterns draw with, kept faint on purpose.
Color _ink(AppPalette colors, double alpha) =>
    colors.outline.withValues(alpha: alpha);

/// Technical drawing paper — a fine grid with a heavier line every fifth step.
class _BlueprintPainter extends CustomPainter {
  final AppPalette colors;

  _BlueprintPainter(this.colors);

  static const double _step = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final fine = Paint()
      ..color = _ink(colors, 0.22)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = _ink(colors, 0.38)
      ..strokeWidth = 1.4;

    var i = 0;
    for (double x = 0; x <= size.width; x += _step, i++) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), i % 5 == 0 ? major : fine);
    }
    i = 0;
    for (double y = 0; y <= size.height; y += _step, i++) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), i % 5 == 0 ? major : fine);
    }
  }

  @override
  bool shouldRepaint(_BlueprintPainter old) => old.colors.outline != colors.outline;
}

/// Evaporator coil — straight runs joined by return bends, as on a cooling unit.
class _CoilPainter extends CustomPainter {
  final AppPalette colors;

  _CoilPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    // The spacing follows the canvas so the pattern still reads as a coil in a
    // 56px swatch in 설정, not just on a full screen.
    final pitch = (size.height / 5).clamp(14.0, 54.0);
    final margin = pitch / 2;

    final pipe = Paint()
      ..color = _ink(colors, 0.3)
      ..strokeWidth = pitch < 24 ? 1.5 : 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final radius = pitch / 2;
    var y = margin;
    var toRight = true;

    path.moveTo(margin, y);
    while (y < size.height) {
      final from = toRight ? margin : size.width - margin;
      final to = toRight ? size.width - margin : margin;
      path.moveTo(from, y);
      path.lineTo(to, y);
      // Return bend into the next run.
      path.arcToPoint(
        Offset(to, y + pitch),
        radius: Radius.circular(radius),
        clockwise: toRight,
      );
      y += pitch;
      toRight = !toRight;
    }
    canvas.drawPath(path, pipe);
  }

  @override
  bool shouldRepaint(_CoilPainter old) => old.colors.outline != colors.outline;
}

/// Brushed metal — a soft vertical gradient under fine horizontal grain.
class _MetalPainter extends CustomPainter {
  final AppPalette colors;

  _MetalPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _ink(colors, 0.26),
            _ink(colors, 0.06),
            _ink(colors, 0.22),
          ],
        ).createShader(rect),
    );

    // A fixed seed keeps the grain identical between repaints, so scrolling
    // does not make the backdrop shimmer.
    final random = math.Random(7);
    final grain = Paint()..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      grain.color = _ink(colors, 0.04 + random.nextDouble() * 0.07);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grain);
    }
  }

  @override
  bool shouldRepaint(_MetalPainter old) => old.colors.outline != colors.outline;
}

/// Perforated plate — dots on a tight lattice.
class _GridPainter extends CustomPainter {
  final AppPalette colors;

  _GridPainter(this.colors);

  static const double _step = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = _ink(colors, 0.4);
    for (double y = _step / 2; y < size.height; y += _step) {
      for (double x = _step / 2; x < size.width; x += _step) {
        canvas.drawCircle(Offset(x, y), 1.3, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.colors.outline != colors.outline;
}
