// ===============================================================
// 경로: lib/services/chart/chart_api_service.dart
// ===============================================================
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:idcs/main.dart';

class ChartApiService {
  static String get _baseUrl => '${AppConfig.baseUrl}/chart';
  static String get _mappingUrl => '${AppConfig.baseUrl}/chart-mapping';

  static Future<Map<String, dynamic>> getHistoricalData({
    required int facilityId,
    required int roomId,
    required String scale,
    required DateTime startTime, // 💡 새로 추가된 파라미터
    required DateTime endTime,   // 💡 새로 추가된 파라미터
    required List<int> roleIds,
  }) async {
    // ISO-8601 포맷으로 변환하여 쿼리 스트링에 전달
    final strStart = startTime.toUtc().toIso8601String();
    final strEnd = endTime.toUtc().toIso8601String();

    final urlStr = '$_baseUrl/$facilityId/$roomId?scale=$scale&start_time=$strStart&end_time=$strEnd&role_ids=${roleIds.join(',')}';
    final url = Uri.parse(urlStr);

    final response = await http.get(url);
    final String responseBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      try {
        final error = jsonDecode(responseBody);
        throw Exception(error['detail'] ?? '차트 데이터를 불러오는데 실패했습니다.');
      } catch (_) {
        throw Exception('서버 오류 ($responseBody)');
      }
    }
  }

// ... (getChartGroups는 기존 유지) ...

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