import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';



class SocialAuthService {
  static bool _isGoogleInitialized = false;

  /// 구글 SDK를 통해 프로필 정보를 가져옵니다.
  static Future<Map<String, String>?> signInWithGoogle() async {
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
      final googleUser = await googleSignIn.authenticate();
      // 사용자가 로그인 팝업을 그냥 닫은 경우 null 반환
      if (googleUser == null) {
        return null;
      }

      return {
        'provider': 'google',
        'provider_id': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName ?? '구글유저',
      };
    } catch (error) {
      throw Exception('구글 로그인 진행 중 오류가 발생/취소되었습니다: $error');
    }
  }

  /// 애플 SDK를 통해 프로필 정보를 가져옵니다.
  static Future<Map<String, String>?> signInWithApple() async {
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
    } catch (error) {
      throw Exception('애플 로그인 진행 중 오류가 발생/취소되었습니다: $error');
    }
  }



}