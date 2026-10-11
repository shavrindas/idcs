// 경로: lib/services/common/facility_shortcut.dart
// 명세: 시설이 하나뿐인 계정에서 시설 선택 화면을 한 번만 건너뛰기 위한 플래그

/// Tracks whether the "only one facility" shortcut has already been taken.
///
/// This cannot live in the router's `redirect`: a permanent redirect from 홈 to
/// the facility would fire again the moment the user presses back, trapping them
/// in a loop with no way to reach 알람 or 내 정보. So the jump is one-shot —
/// taken on the first 홈 load after signing in, and not again until the signed-in
/// user changes.
class FacilityShortcut {
  FacilityShortcut._();

  static bool _pending = true;

  /// Takes the shortcut if it is still available. Returns true at most once per
  /// sign-in, so the caller can navigate without risking a loop.
  static bool consume() {
    if (!_pending) return false;
    _pending = false;
    return true;
  }

  /// Makes the shortcut available again. Called whenever the signed-in user
  /// changes, so the next account (or the next sign-in) gets its own jump.
  static void rearm() => _pending = true;
}
