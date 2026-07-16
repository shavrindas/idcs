import 'dart:convert';
import 'package:http/http.dart' as http;
// AppConfig가 정의된 main.dart를 임포트 (경로에 맞게 수정하세요)
import '../../../main.dart';

class AuthApiService {
  // 백엔드 auth 라우터 기본 URL
  static String get _authUrl => '${AppConfig.baseUrl}/auth';
  /// 아이디 찾기 페이지: 이메일 계정 존재 및 연동 여부 확인
  static Future<Map<String, dynamic>> checkAccountExistence(String email) async {
    final url = Uri.parse('$_authUrl/check-account');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? '계정 정보를 확인하는데 실패했습니다.');
    }
  }
}