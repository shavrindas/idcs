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

/// 채팅은 `2026-08-20 11:30` 처럼 타임존이 빠진 문자열로 온다. 서버가
/// timestamptz 를 strftime 으로 찍으면서 시간대 표시를 떨어뜨린 것인데, 값
/// 자체는 UTC다 — 같은 시각이 방 목록 API 에서는 `...+00:00` 으로 돌아온다.
///
/// 그래서 시간대 표시가 없으면 UTC 로 읽는다. 그냥 두면 한국에서 9시간 이른
/// 시각이 뜬다. 서버가 ISO 로 내려주게 되면 이 분기는 저절로 쓰이지 않는다.
String formatChatTime(String raw) {
  final hasZone = raw.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(raw);
  return _format(hasZone ? raw : '${raw.replaceFirst(' ', 'T')}Z', 'MM/dd HH:mm');
}

/// 목록에서 쓰는 짧은 형태. 올해 안의 일이 대부분이라 연도는 빼 둔다.
String formatListTime(String raw) => _format(raw, 'MM/dd HH:mm');

/// 글 하나를 펼쳐 볼 때. 몇 년도 글인지가 의미를 갖는 자리다.
String formatPostTime(String raw) => _format(raw, 'yyyy.MM.dd HH:mm');
