import 'dart:convert';
import 'api_client.dart';
import '../../main.dart';

class FacilityApiService {
  static String get _baseUrl => '${AppConfig.baseUrl}/facilities';

  // 시설 목록 조회 (권한에 따라 백엔드에서 알아서 필터링됨)
  static Future<List<dynamic>> getFacilities(String userId) async {
    final url = Uri.parse('$_baseUrl/$userId');
    final response = await ApiClient.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['facilities'] ?? [];
    } else {
      throw ApiException.rejected();
    }
  }

  // 시설 등록
  static Future<String> registerFacility(String userId, String accessCode) async {
    final url = Uri.parse('$_baseUrl/$userId/register');
    final response = await ApiClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'access_code': accessCode}),
    );
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return data['message'];
    throw ApiException.rejected(data);
  }

  // 시설 연동 해제
  static Future<String> unlinkFacility(String userId, int facilityId) async {
    final url = Uri.parse('$_baseUrl/$userId/unlink/$facilityId');
    final response = await ApiClient.delete(url);
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return data['message'];
    throw ApiException.rejected(data);
  }

  //시설 호실 목록 조회
  static Future<List<dynamic>> getFacilityRooms(String facilityId) async {
    final url = Uri.parse('$_baseUrl/rooms/$facilityId');
    final response = await ApiClient.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['rooms'] ?? [];
    } else {
      throw ApiException.rejected();
    }
  }

  static Future<List<dynamic>> getFacilityEmployees(String facilityId, String userId) async {
    // 쿼리파라미터로 본인 ID 전달
    final url = Uri.parse('$_baseUrl/$facilityId/employees?user_id=$userId');
    final response = await ApiClient.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['employees'] ?? [];
    } else {
      throw ApiException.rejected();
    }
  }

  static Future<String> inviteUserByCode(String facilityId, String userId, String userCode) async {
    final url = Uri.parse('$_baseUrl/$facilityId/invite-by-code?user_id=$userId');
    final response = await ApiClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_code': userCode}),
    );
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return data['message'];
    throw ApiException.rejected(data);
  }

  static Future<String> removeEmployee(String facilityId, String userId, int targetUserId) async {
    final url = Uri.parse('$_baseUrl/$facilityId/remove-employee/$targetUserId?user_id=$userId');
    final response = await ApiClient.delete(url);
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return data['message'];
    throw ApiException.rejected(data);
  }
}