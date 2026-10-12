// ===============================================================
// 경로: lib/components/shared/app_toast.dart
// 명세: 상태별 색을 가진 토스트 알림 (성공/실패/주의/안내)
// ===============================================================
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';

/// What a toast is telling the user. The colour and icon follow from this, so a
/// screen only has to say which kind it is.
enum ToastKind { success, error, warning, info }

/// Short status messages shown over the current screen.
///
/// These replace the default SnackBar, which came up grey at the bottom and told
/// the user nothing before they had read it — a failed save and a successful one
/// looked identical. A toast sits at the top instead: the bottom of this app is
/// taken by the navigation bar, and a message there competes with it.
class AppToast {
  AppToast._();

  /// Errors stay a little longer; they usually carry something to act on.
  static const Duration _shortLife = Duration(seconds: 3);
  static const Duration _longLife = Duration(seconds: 4);

  static OverlayEntry? _current;

  static void success(BuildContext context, String message) =>
      show(context, message, kind: ToastKind.success);

  static void error(BuildContext context, String message) =>
      show(context, message, kind: ToastKind.error);

  static void warning(BuildContext context, String message) =>
      show(context, message, kind: ToastKind.warning);

  static void info(BuildContext context, String message) =>
      show(context, message, kind: ToastKind.info);

  static void show(
    BuildContext context,
    String message, {
    ToastKind kind = ToastKind.info,
  }) {
    if (message.trim().isEmpty) return;

    // rootOverlay so a toast raised from inside a dialog still lands on top of
    // the app rather than inside the dialog's own overlay.
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _dismissCurrent();

    final life = kind == ToastKind.error || kind == ToastKind.warning
        ? _longLife
        : _shortLife;

    late final OverlayEntry entry;
    var removed = false;
    entry = OverlayEntry(
      builder: (context) => _ToastView(
        message: message,
        kind: kind,
        life: life,
        onFinished: () {
          // A swipe and the timer can both finish the same toast; removing an
          // entry twice throws, so the first one wins.
          if (removed) return;
          removed = true;
          if (_current == entry) _current = null;
          entry.remove();
        },
      ),
    );

    _current = entry;
    overlay.insert(entry);
  }

  /// Takes the visible toast away at once, so a new one does not stack on it.
  static void _dismissCurrent() {
    final entry = _current;
    _current = null;
    if (entry != null && entry.mounted) entry.remove();
  }
}

class _ToastView extends StatefulWidget {
  final String message;
  final ToastKind kind;
  final Duration life;
  final VoidCallback onFinished;

  const _ToastView({
    required this.message,
    required this.kind,
    required this.life,
    required this.onFinished,
  });

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 200),
    );
    // Drops in from just above its resting place rather than from off-screen,
    // which reads as an arrival instead of a swipe.
    _slide = Tween<Offset>(begin: const Offset(0, -0.45), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
    _timer = Timer(widget.life, _dismiss);
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = switch (widget.kind) {
      ToastKind.success => colors.success,
      ToastKind.error => colors.error,
      ToastKind.warning => colors.warning,
      ToastKind.info => colors.primary,
    };
    final icon = switch (widget.kind) {
      ToastKind.success => Icons.check_circle_rounded,
      ToastKind.error => Icons.error_rounded,
      ToastKind.warning => Icons.warning_rounded,
      ToastKind.info => Icons.info_rounded,
    };

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Dismissible(
              key: const ValueKey('app_toast'),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onFinished(),
              child: GestureDetector(
                onTap: _dismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    // The card stays on surface so the message keeps the same
                    // contrast it would have anywhere else; the status colour
                    // carries the meaning through the icon and the edge.
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withValues(alpha: 0.45)),
                    boxShadow: colors.softShadow,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(icon, size: 18, color: accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
