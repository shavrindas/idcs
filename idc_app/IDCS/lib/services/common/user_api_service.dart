import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../main.dart';

class UserApiService {
  static String get _baseUrl => '${AppConfig.baseUrl}/auth'; // 라우터 경로에 맞게 수정

  /// 유저 권한(Role) 조회 API
  static Future<String> getUserRole(String userId) async {
    final url = Uri.parse('$_baseUrl/$userId/role');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['role']; // 'USER', 'ADMIN', 'DEVELOPER' 중 하나 반환
    } else {
      throw Exception('권한 정보를 불러오는데 실패했습니다.');
    }
  }

  // ----------------------------------------------
  // 계정 수정 로직

  /// 유저 프로필 조회
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final url = Uri.parse('$_baseUrl/$userId/profile');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('프로필 정보를 불러오는데 실패했습니다.');
    }
  }

  /// Box #2: 이름 수정
  static Future<String> updateName(String userId, String name) async {
    final url = Uri.parse('$_baseUrl/$userId/name');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return data['message'];
    throw Exception(data['detail'] ?? '이름 수정에 실패했습니다.');
  }

  /// Box #3: 전화번호 수정
  static Future<String> updatePhone(String userId, String phone) async {
    final url = Uri.parse('$_baseUrl/$userId/phone');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phone}),
    );
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return data['message'];
    throw Exception(data['detail'] ?? '전화번호 수정에 실패했습니다.');
  }

  /// Box #4: 비밀번호 수정
  static Future<String> updatePassword(String userId, String currentPw, String newPw) async {
    final url = Uri.parse('$_baseUrl/$userId/password');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'current_password': currentPw,
        'new_password': newPw,
      }),
    );
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return data['message'];
    throw Exception(data['detail'] ?? '비밀번호 수정에 실패했습니다.');
  }

  /// 계정 탈퇴. 서버에서 CASCADE로 연동 계정/시설 소속 정보까지 함께 삭제된다.
  static Future<String> withdraw(String userId) async {
    final url = Uri.parse('$_baseUrl/withdraw');
    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': int.parse(userId)}),
    );
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return data['message'];
    throw Exception(data['detail'] ?? '계정 탈퇴에 실패했습니다.');
  }
}