import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../main.dart';

class FacilityApiService {
  static String get _baseUrl => '${AppConfig.baseUrl}/facilities';

  // 시설 목록 조회 (권한에 따라 백엔드에서 알아서 필터링됨)
  static Future<List<dynamic>> getFacilities(String userId) async {
    final url = Uri.parse('$_baseUrl/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['facilities'] ?? [];
    } else {
      throw Exception('시설 목록을 불러오는데 실패했습니다.');
    }
  }

  // 시설 등록
  static Future<String> registerFacility(String userId, String accessCode) async {
    final url = Uri.parse('$_baseUrl/$userId/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'access_code': accessCode}),
    );
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return data['message'];
    throw Exception(data['detail'] ?? '시설 등록에 실패했습니다.');
  }

  // 시설 연동 해제
  static Future<String> unlinkFacility(String userId, int facilityId) async {
    final url = Uri.parse('$_baseUrl/$userId/unlink/$facilityId');
    final response = await http.delete(url);
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return data['message'];
    throw Exception(data['detail'] ?? '시설 해제에 실패했습니다.');
  }
}