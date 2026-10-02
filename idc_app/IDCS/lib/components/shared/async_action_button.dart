// 경로: lib/components/shared/async_action_button.dart
// 명세: 서버 요청처럼 시간이 걸리는 동작을 실행하는 버튼
import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';

/// 누르면 비동기 동작을 실행하고, 끝날 때까지 스피너를 보여주는 버튼.
///
/// 기존에는 저장/로그인 버튼을 눌러도 요청이 끝날 때까지 아무 반응이 없어서
/// 눌린 건지 알 수 없었고, 여러 번 눌러 같은 요청이 중복으로 나가기도 했다.
class AsyncActionButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onPressed;
  final ButtonStyle? style;

  const AsyncActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style,
  });

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

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // 진행 중에는 라벨이 스피너로 바뀌어 스크린 리더가 버튼 이름을 잃는다.
      // 이름을 유지하고 진행 상태도 함께 알린다.
      label: widget.label,
      button: true,
      enabled: !_running,
      child: ElevatedButton(
        // 진행 중에는 null을 넘겨 비활성 상태가 되게 한다 (중복 탭 방지 + 시각적 표시)
        onPressed: _running ? null : _handlePressed,
        style: widget.style,
        child: _running
            // 비활성 배경은 옅은 회색이라 흰색 스피너는 보이지 않는다.
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary),
              )
            : Text(widget.label),
      ),
    );
  }
}
