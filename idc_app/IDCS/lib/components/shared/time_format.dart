// ===============================================================
// 경로: lib/components/shared/time_format.dart
// 명세: 서버 시간 문자열을 화면에서 읽을 수 있는 형태로
// ===============================================================
import 'package:intl/intl.dart';

/// 서버는 `2026-08-20T11:35:08.981469+00:00` 같은 ISO 문자열을 내려준다.
/// 그대로 화면에 붙이면 기계가 읽는 값을 사람에게 보여주는 셈이 된다.
///
/// 파싱에 실패하면 원문을 그대로 둔다 — 형식이 바뀌었을 때 빈칸이 뜨는 것보다
/// 낫고, 무엇이 왔는지 눈으로 확인할 수 있다.
String _format(String raw, String pattern) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return DateFormat(pattern).format(parsed.toLocal());
}

/// 목록에서 쓰는 짧은 형태. 올해 안의 일이 대부분이라 연도는 빼 둔다.
String formatListTime(String raw) => _format(raw, 'MM/dd HH:mm');

/// 글 하나를 펼쳐 볼 때. 몇 년도 글인지가 의미를 갖는 자리다.
String formatPostTime(String raw) => _format(raw, 'yyyy.MM.dd HH:mm');
