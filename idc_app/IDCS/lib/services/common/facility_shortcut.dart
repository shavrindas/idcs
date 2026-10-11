// 경로: lib/services/common/facility_shortcut.dart
// 명세: 시설이 하나뿐인 계정에서 시설 선택 화면을 건너뛰는 동작의 상태

/// Tracks whether the signed-in account has exactly one facility.
///
/// For such an account the 내 시설 list is a screen with a single card on it, so
/// 홈 goes straight into the facility instead. The jump replaces the stack
/// rather than pushing, which means back from the facility leaves the app —
/// there is no one-item list to come back to.
///
/// That removes the only route to 내 정보, so [FacilityShellPage] shows a
/// profile button in its app bar while this is set.
class FacilityShortcut {
  FacilityShortcut._();

  static bool _soleFacility = false;

  /// True once 홈 has seen that this account owns exactly one facility.
  static bool get isSoleFacility => _soleFacility;

  static void markSoleFacility(bool value) => _soleFacility = value;

  /// Called whenever the signed-in user changes, so the next account starts
  /// from an unknown state rather than inheriting the previous one's layout.
  static void reset() => _soleFacility = false;
}
