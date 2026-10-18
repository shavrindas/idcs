// 경로: lib/components/shared/async_action_button.dart
// 명세: 서버 요청처럼 시간이 걸리는 동작을 실행하는 버튼
import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';

/// 누르면 비동기 동작을 실행하고, 끝날 때까지 스피너를 보여주는 버튼.
///
/// 기존에는 저장/로그인 버튼을 눌러도 요청이 끝날 때까지 아무 반응이 없어서
/// 눌린 건지 알 수 없었고, 여러 번 눌러 같은 요청이 중복으로 나가기도 했다.
///
/// 소셜 로그인처럼 테두리 버튼이어야 하는 자리는 [AsyncActionButton.outlined]
/// 를 쓴다. 구글/애플 창이 뜨기까지 몇 초가 걸려서, 반응이 없으면 더 눌러
/// 보게 되는 자리다.
class AsyncActionButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onPressed;
  final ButtonStyle? style;

  /// 테두리 버튼으로 그릴지. 기본은 채운 버튼.
  final bool outlined;

  /// 라벨 앞에 붙일 것. 보통 제공자 로고.
  final Widget? icon;

  /// 아직 누를 수 없는 자리인지. 여러 단계로 나뉜 화면에서 앞 단계를 끝내야
  /// 열리는 버튼에 쓴다.
  final bool enabled;

  const AsyncActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style,
    this.icon,
    this.enabled = true,
  }) : outlined = false;

  const AsyncActionButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.style,
    this.icon,
    this.enabled = true,
  }) : outlined = true;

  @override
  State<AsyncActionButton> createState() => _AsyncActionButtonState();
}

class _AsyncActionButtonState extends State<AsyncActionButton> {
  bool _running = false;

  Future<void> _handlePressed() async {
    if (_running) return;
    setState(() => _running = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  /// 진행 중에 보여줄 것. 비활성 배경은 옅은 회색이라 흰색 스피너는 보이지 않는다.
  Widget get _spinner => SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary),
      );

  @override
  Widget build(BuildContext context) {
    // 진행 중에는 null을 넘겨 비활성 상태가 되게 한다 (중복 탭 방지 + 시각적 표시)
    final onPressed = (_running || !widget.enabled) ? null : _handlePressed;

    // 아이콘이 있는 버튼은 진행 중에 아이콘 자리를 스피너가 대신한다. 라벨까지
    // 같이 지우면 버튼 폭이 출렁이고, 무엇을 누른 것인지도 알 수 없다.
    final Widget child = widget.icon == null
        ? (_running ? _spinner : Text(widget.label))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 20, height: 20, child: _running ? _spinner : widget.icon),
              const SizedBox(width: 10),
              Text(widget.label),
            ],
          );

    return Semantics(
      // 진행 중에는 라벨이 스피너로 바뀌어 스크린 리더가 버튼 이름을 잃는다.
      // 이름을 유지하고 진행 상태도 함께 알린다.
      label: widget.label,
      button: true,
      enabled: widget.enabled && !_running,
      child: widget.outlined
          ? OutlinedButton(onPressed: onPressed, style: widget.style, child: child)
          : ElevatedButton(onPressed: onPressed, style: widget.style, child: child),
    );
  }
}
