// 경로: lib/services/common/api_client.dart
// 명세: 모든 API 호출이 공유하는 http 래퍼 — 응답 대기 제한과 사용자용 오류 문구
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// An API failure whose message is already written for the user to read.
/// Services throw this so screens can print it directly instead of leaking a
/// SocketException with host names and errno values into the UI.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// http wrapper that every *_api_service.dart goes through.
///
/// Two things it adds over calling `http` directly:
/// 1. A response deadline. Without one, an unreachable-but-routable server (the
///    usual case when the LAN address changed) leaves the screen spinning for
///    as long as the OS keeps the socket open.
/// 2. Network errors turned into one short Korean sentence, so a dropped
///    connection reads the same on every screen.
class ApiClient {
  /// Long enough for a slow mobile network, short enough that a wrong server
  /// address fails while the user is still looking at the screen.
  static const Duration timeout = Duration(seconds: 10);

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _send(() => http.get(url, headers: headers));
  }

  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) {
    return _send(() => http.post(url, headers: headers, body: body));
  }

  static Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body}) {
    return _send(() => http.put(url, headers: headers, body: body));
  }

  static Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body}) {
    return _send(() => http.delete(url, headers: headers, body: body));
  }

  /// Runs a multipart request (image upload) under the same rules.
  static Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _send(() => request.send());
  }

  static Future<T> _send<T>(Future<T> Function() request) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw ApiException('서버 응답이 없습니다. 네트워크 상태를 확인해주세요.');
    } on SocketException {
      throw ApiException('서버에 연결할 수 없습니다. 네트워크 상태를 확인해주세요.');
    } on http.ClientException {
      // Web has no SocketException; a failed fetch surfaces as ClientException.
      throw ApiException('서버에 연결할 수 없습니다. 네트워크 상태를 확인해주세요.');
    }
  }
}

/// Turns anything thrown by a service into a line that is safe to show.
///
/// Services already raise Korean messages via `Exception('...')`, but printing
/// one with `$e` renders the `Exception: ` prefix too, so strip it here.
String describeApiError(Object error) {
  if (error is ApiException) return error.message;

  final text = error.toString();
  const prefix = 'Exception: ';
  final stripped = text.startsWith(prefix) ? text.substring(prefix.length) : text;

  // Anything still carrying socket/host details is a connection problem the
  // user can act on; the details themselves mean nothing to them.
  if (stripped.contains('SocketException') ||
      stripped.contains('ClientException') ||
      stripped.contains('Failed host lookup') ||
      (kIsWeb && stripped.contains('XMLHttpRequest'))) {
    return '서버에 연결할 수 없습니다. 네트워크 상태를 확인해주세요.';
  }
  return stripped;
}
