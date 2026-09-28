// ===============================================================
// 경로: lib/services/chart/chart_api_service.dart
// 명세: 차트 시계열 과거 데이터 조회 서비스
// ===============================================================
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:idcs/main.dart'; // AppConfig

class ChartApiService {
  static String get _baseUrl => '${AppConfig.baseUrl}/chart';

  static String get _mappingUrl => '${AppConfig.baseUrl}/chart-mapping';


  static Future<Map<String, dynamic>> getHistoricalData({
    required int facilityId,
    required int roomId,
    required String scale,
    required String timeRange,
    required List<int> roleIds, // 필수로 변경
  }) async {
    final urlStr = '$_baseUrl/$facilityId/$roomId?scale=$scale&time_range=$timeRange&role_ids=${roleIds.join(',')}';
    final response = await http.get(Uri.parse(urlStr));

    final String responseBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      // 💡 JSON 디코딩 실패 시 (Internal Server Error 등) 처리
      try {
        final error = jsonDecode(responseBody);
        throw Exception(error['detail'] ?? '차트 데이터를 불러오는데 실패했습니다.');
      } catch (_) {
        throw Exception('서버 오류 ($responseBody)');
      }
    }
  }
  static Future<List<dynamic>> getChartGroups(int facilityId, int roomId) async {
    final url = Uri.parse('$_mappingUrl/groups/$facilityId/$roomId');
    final response = await http.get(url);
    final String responseBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(responseBody);
      return decoded['groups'] ?? [];
    } else {
      throw Exception('차트 그룹 데이터를 불러오는데 실패했습니다.');
    }
  }
}