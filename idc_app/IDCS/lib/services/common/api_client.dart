// 경로: lib/services/common/api_client.dart
// 명세: 모든 API 호출이 공유하는 http 래퍼 — 응답 대기 제한과 실패 사유 분류
import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'package:idcs/l10n/l10n_context.dart';

import 'social_auth_service.dart';

/// Why a request failed, as far as the app can tell.
///
/// The screen already says *what* it was doing ("Could not load the post: …"),
/// so a service only has to supply the reason. Keeping it an enum rather than a
/// sentence is what lets the text be translated at display time, where the
/// locale is known — a service has no BuildContext.
enum ApiFailure {
  /// The server could not be reached at all.
  unreachable,

  /// The server accepted the connection but did not answer in time.
  timeout,

  /// The server answered, but with an error and no explanation of its own.
  rejected,
}

/// An API failure a screen can show without leaking socket details.
///
/// [detail] carries the server's own explanation when it sent one; that text is
/// shown as-is, because only the backend knows the specific reason.
class ApiException implements Exception {
  final ApiFailure failure;
  final String? detail;

  ApiException(this.failure, {this.detail});

  /// The server answered with an error. Prefers its own wording when present.
  factory ApiException.rejected([Object? body]) {
    final detail = body is Map ? body['detail'] : null;
    return ApiException(
      ApiFailure.rejected,
      detail: detail is String && detail.isNotEmpty ? detail : null,
    );
  }

  @override
  String toString() => detail ?? failure.name;
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
      throw ApiException(ApiFailure.timeout);
    } on SocketException {
      throw ApiException(ApiFailure.unreachable);
    } on http.ClientException {
      // Web has no SocketException; a failed fetch surfaces as ClientException.
      throw ApiException(ApiFailure.unreachable);
    }
  }
}

/// Turns anything thrown by a service into a line that is safe to show.
///
/// Takes a context because the wording has to follow the chosen language, and a
/// service cannot know it.
String describeApiError(BuildContext context, Object error) {
  final l10n = context.l10n;

  if (error is SocialAuthUnavailable) {
    switch (error.problem) {
      case SocialAuthProblem.googleWebUnsupported:
        return l10n.googleOnlyOnApp;
      case SocialAuthProblem.appleWebUnsupported:
        return l10n.appleOnlyOnApp;
      case SocialAuthProblem.googleNotConfigured:
        return l10n.googleNotConfigured;
      case SocialAuthProblem.googleFailed:
        return l10n.googleSignInFailed(error.reason ?? '');
      case SocialAuthProblem.appleFailed:
        return l10n.appleSignInFailed(error.reason ?? '');
    }
  }

  if (error is ApiException) {
    if (error.detail != null) return error.detail!;
    switch (error.failure) {
      case ApiFailure.unreachable:
        return l10n.errorServerUnreachable;
      case ApiFailure.timeout:
        return l10n.errorServerTimeout;
      case ApiFailure.rejected:
        return l10n.errorRequestFailed;
    }
  }

  final text = error.toString();
  const prefix = 'Exception: ';
  final stripped = text.startsWith(prefix) ? text.substring(prefix.length) : text;

  // Anything still carrying socket/host details is a connection problem the
  // user can act on; the details themselves mean nothing to them.
  if (stripped.contains('SocketException') ||
      stripped.contains('ClientException') ||
      stripped.contains('Failed host lookup') ||
      (kIsWeb && stripped.contains('XMLHttpRequest'))) {
    return l10n.errorServerUnreachable;
  }
  return stripped;
}
