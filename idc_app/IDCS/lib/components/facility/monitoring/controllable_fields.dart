// ===============================================================
// 경로: lib/components/facility/monitoring/controllable_fields.dart
// 명세: 제어판에서 값을 바꿔 보낼 수 있는 항목
// ===============================================================

/// 설비로 값을 써 넣을 수 있는 항목.
///
/// 제어판은 56개 행 전부에 입력칸과 '확인' 버튼을 달고 있었지만, 실제로 쓸 수
/// 있는 것은 이 다섯 개뿐이다. 나머지 51개는 눌러도 설비에 닿지 않는다.
///
/// 출처는 수집기의 쓰기 주소표다 — `DataIntercept/WriteList.py` 의
/// `DataLists` 가 req_id 를 장비 주소로 바꿔 준다. 거기에 없는 이름으로
/// 요청이 가면 수집기 쪽에서 KeyError 가 나면서 명령 수신 자체가 끊긴다.
/// 그래서 이 목록 밖의 항목은 버튼을 아예 내보내지 않는다.
///
/// 주소표가 늘어나면 여기도 같이 늘려야 한다. 서버가 포인트 롤마다 쓰기
/// 가능 여부를 내려주면 이 중복은 없앨 수 있다 — 그렇게 바꿔 달라고 요청해 둔 상태다.
class ControllableFields {
  ControllableFields._();

  static const Set<String> _writable = {
    'temp_sv', // 설정값
    'temp_hey', // 편차값
    'control_runsw', // 운전SW
    'control_efa', // 쿨러 팬 자동여부
    'control_tica', // 아날로그TC
  };

  static bool has(String apiKey) => _writable.contains(apiKey);

  /// 이 카드에 쓸 수 있는 항목이 하나라도 있는지. '제어' 표시를 달지 결정한다.
  static bool anyIn(Iterable<String> apiKeys) => apiKeys.any(has);
}
