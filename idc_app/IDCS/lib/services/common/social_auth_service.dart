import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'api_client.dart';

/// Why social sign-in could not go ahead.
///
/// Like [ApiFailure], this stays an enum rather than a sentence: the service
/// runs without a BuildContext, so the wording is chosen at display time by
/// `describeApiError`.
enum SocialAuthProblem {
  /// The plugin has no web implementation.
  googleWebUnsupported,
  appleWebUnsupported,

  /// The Firebase project has no OAuth client for this package + signature.
  googleNotConfigured,

  /// Anything else the SDK reported; [SocialAuthUnavailable.reason] says what.
  googleFailed,
  appleFailed,
}

/// Thrown when social sign-in cannot work, as opposed to the user backing out.
class SocialAuthUnavailable implements Exception {
  final SocialAuthProblem problem;

  /// SDK error code or message, shown in parentheses after the sentence.
  final String? reason;

  SocialAuthUnavailable(this.problem, {this.reason});

  @override
  String toString() => reason == null ? problem.name : '${problem.name}: $reason';
}



class SocialAuthService {
  static bool _isGoogleInitialized = false;

  /// 구글 SDK를 통해 프로필 정보를 가져옵니다.
  /// Web is not supported: google_sign_in_web has no authenticate() and requires
  /// Google's own rendered button instead, so fail with a clear message rather
  /// than an UnimplementedError from deep inside the plugin.
  static bool get isSupported => !kIsWeb;

  static Future<Map<String, String>?> signInWithGoogle() async {
    if (kIsWeb) {
      throw SocialAuthUnavailable(SocialAuthProblem.googleWebUnsupported);
    }
    try {
      final googleSignIn = GoogleSignIn.instance;
      try {
        if (!_isGoogleInitialized) {
          await googleSignIn.initialize(
            // TODO: GCP에서 발급받은 유형의 클라이언트 ID
            // 근데 IDCool 용으로 아니면 설민님 계정으로
            serverClientId: '415636031627-asr8rncpbq4c5jkn3r44d0u65cf64lvb.apps.googleusercontent.com',
          );
          _isGoogleInitialized = true;
        }
      } catch (e) {
        // 이미 초기화된 상태에서 발생하는 StateError는 안전하게 무시합니다.
        if (e is StateError && e.message.contains('already been called')) {
          _isGoogleInitialized = true;
        } else {
          rethrow; // 다른 종류의 에러는 그대로 던집니다.
        }
      }
      // authenticate() no longer returns null on cancel; it throws with
      // GoogleSignInExceptionCode.canceled, handled below.
      final googleUser = await googleSignIn.authenticate();

      return {
        'provider': 'google',
        'provider_id': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName ?? '',
      };
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        // Backing out of the picker is a normal action, not an error. Returning
        // null lets the caller stay on the screen without showing anything.
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
          return null;
        // The Firebase project has no OAuth client registered for this app's
        // package name + signing fingerprint, so Google rejects the request.
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          throw SocialAuthUnavailable(SocialAuthProblem.googleNotConfigured);
        default:
          throw SocialAuthUnavailable(SocialAuthProblem.googleFailed, reason: e.code.name);
      }
    } catch (error) {
      throw SocialAuthUnavailable(SocialAuthProblem.googleFailed, reason: '$error');
    }
  }

  /// 애플 SDK를 통해 프로필 정보를 가져옵니다.
  static Future<Map<String, String>?> signInWithApple() async {
    if (kIsWeb) {
      throw SocialAuthUnavailable(SocialAuthProblem.appleWebUnsupported);
    }
    try {
      final AuthorizationCredentialAppleID credential =
      await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      String name = '';
      if (credential.givenName != null || credential.familyName != null) {
        name = '${credential.familyName ?? ''}${credential.givenName ?? ''}';
      }

      return {
        'provider': 'apple',
        'provider_id': credential.userIdentifier ?? '',
        'email': credential.email ?? '',
        'name': name,
      };
    } on SignInWithAppleAuthorizationException catch (e) {
      // Same reasoning as Google: a cancelled dialog is not an error.
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw SocialAuthUnavailable(SocialAuthProblem.appleFailed, reason: e.code.name);
    } catch (error) {
      throw SocialAuthUnavailable(SocialAuthProblem.appleFailed, reason: '$error');
    }
  }



}