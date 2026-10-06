import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Thrown when social sign-in cannot work on this build, as opposed to the user
/// backing out. The message is meant to be shown to the user as-is.
class SocialAuthUnavailable implements Exception {
  final String message;
  SocialAuthUnavailable(this.message);
  @override
  String toString() => message;
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
      throw SocialAuthUnavailable('구글 로그인은 앱에서만 사용할 수 있습니다.');
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
        'name': googleUser.displayName ?? '구글유저',
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
          throw SocialAuthUnavailable(
            '구글 로그인이 아직 설정되지 않았습니다. Firebase 프로젝트에 이 앱의 '
            'OAuth 클라이언트(SHA-1 지문)를 등록해야 합니다.',
          );
        default:
          throw SocialAuthUnavailable('구글 로그인을 진행할 수 없습니다. (${e.code.name})');
      }
    } catch (error) {
      throw SocialAuthUnavailable('구글 로그인을 진행할 수 없습니다: $error');
    }
  }

  /// 애플 SDK를 통해 프로필 정보를 가져옵니다.
  static Future<Map<String, String>?> signInWithApple() async {
    if (kIsWeb) {
      throw SocialAuthUnavailable('애플 로그인은 앱에서만 사용할 수 있습니다.');
    }
    try {
      final AuthorizationCredentialAppleID credential =
      await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      String name = '애플유저';
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
      throw SocialAuthUnavailable('애플 로그인을 진행할 수 없습니다. (${e.code.name})');
    } catch (error) {
      throw SocialAuthUnavailable('애플 로그인을 진행할 수 없습니다: $error');
    }
  }



}