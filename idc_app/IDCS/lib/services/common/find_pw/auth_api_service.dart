import 'dart:convert';
import 'package:http/http.dart' as http;
// AppConfig가 정의된 main.dart를 임포트 (경로에 맞게 수정하세요)
import '../../../main.dart';

class AuthApiService {
  // 백엔드 auth 라우터 기본 URL
  static String get _authUrl => '${AppConfig.baseUrl}/auth';
  /// 아이디 찾기 페이지: 이메일 계정 존재 및 연동 여부 확인


  static Future<Map<String, dynamic>> requestPasswordCode(String email) async {
    final response = await http.post(
      Uri.parse('$_authUrl/password/request-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes));
    throw Exception(jsonDecode(utf8.decode(response.bodyBytes))['detail']);
  }

  static Future<Map<String, dynamic>> verifyPasswordCode(String token, String code) async {
    final response = await http.post(
      Uri.parse('$_authUrl/password/verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'code': code}),
    );
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes));
    throw Exception(jsonDecode(utf8.decode(response.bodyBytes))['detail']);
  }

  static Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    final response = await http.post(
      Uri.parse('$_authUrl/password/reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'new_password': newPassword}),
    );
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes));
    throw Exception(jsonDecode(utf8.decode(response.bodyBytes))['detail']);
  }

}