import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:idcs/services/common/fcm_service.dart';
// AppConfig가 정의된 main.dart를 임포트 (경로에 맞게 수정하세요)
import '../../../main.dart';

class AuthApiService {
  // 백엔드 auth 라우터 기본 URL
  static String get _authUrl => '${AppConfig.baseUrl}/auth';

  /// Box #1: 일반 로그인 API 호출
  static Future<Map<String, dynamic>> loginGeneral({
    required String email,
    required String password,
    required bool keepLogin,
  }) async {
    final url = Uri.parse('$_authUrl/login/general');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'keep_login': keepLogin,
      }),
    );

    if (response.statusCode == 200) {
      //토큰 전송 추가
      dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if(decoded['user_id'] != null)
        FcmService.registToken();
      return decoded;
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? '로그인에 실패했습니다.');
    }
  }

  /// Box #2: 소셜 로그인 API 호출
  static Future<Map<String, dynamic>> loginSocial({
    required String provider,
    required String providerId,
    required bool keepLogin,
  }) async {
    final url = Uri.parse('$_authUrl/login/social');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider': provider,
        'provider_id': providerId,
        'keep_login': keepLogin,
      }),
    );

    if (response.statusCode == 200) {
      //토큰 전송 추가
      dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if(decoded['user_id'] != null)
        FcmService.registToken();
      return decoded;
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? '소셜 로그인에 실패했습니다.');
    }
  }
}