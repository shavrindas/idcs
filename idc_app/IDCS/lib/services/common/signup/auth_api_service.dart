import 'dart:convert';
import 'package:http/http.dart' as http;
// AppConfig가 정의된 main.dart를 임포트 (경로에 맞게 수정하세요)
import '../../../main.dart';

class AuthApiService {
  // 백엔드 auth 라우터 기본 URL
  static String get _authUrl => '${AppConfig.baseUrl}/auth';

  /// Box #1: 일반 회원가입 API 호출
  static Future<Map<String, dynamic>> signupGeneral({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
  }) async {
    final url = Uri.parse('$_authUrl/signup/general');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        if (phoneNumber != null &&
            phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? '회원가입에 실패했습니다.');
    }
  }

  /// Box #2: 소셜 회원가입 API 호출
  static Future<Map<String, dynamic>> signupSocial({
    required String provider,
    required String providerId,
    required String email,
    required String name,
    String? phoneNumber,
  }) async {
    final url = Uri.parse('$_authUrl/signup/social');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider': provider,
        'provider_id': providerId,
        'email': email,
        'name': name,
        if (phoneNumber != null &&
            phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? '소셜 회원가입에 실패했습니다.');
    }
  }
}