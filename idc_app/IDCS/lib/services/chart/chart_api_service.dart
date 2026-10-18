// ===============================================================
// 경로: lib/services/chart/chart_api_service.dart
// 명세: 차트 시계열 과거 데이터 조회 서비스
// ===============================================================
import 'dart:convert';
import '../common/api_client.dart';
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
    final urlStr =
        '$_baseUrl/$facilityId/$roomId?scale=$scale&time_range=$timeRange&role_ids=${roleIds.join(',')}';
    final response = await ApiClient.get(Uri.parse(urlStr));

    final String responseBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      // 💡 JSON 디코딩 실패 시 (Internal Server Error 등) 처리
      try {
        final error = jsonDecode(responseBody);
        throw ApiException.rejected(error);
      } catch (_) {
        throw ApiException.rejected();
      }
    }
  }

  /// 시설 안 모든 호실의 최근 고내온도. 호실 목록 카드에 띄우기 위한 것으로,
  /// 호실마다 따로 묻지 않고 한 번에 받아온다.
  ///
  /// 비교용 엔드포인트가 호실별 시계열을 내려주므로 마지막 지점만 집어 쓴다.
  /// 값이 없는 호실은 결과에서 빠진다.
  static Future<Map<int, double>> getLatestRoomTemperatures(
    int facilityId,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/compare/$facilityId?role_name=temp_pv&scale=1m&time_range=1h',
    );
    final response = await ApiClient.get(url);
    if (response.statusCode != 200) return const {};

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final datasets = decoded['data']?['datasets'];
    if (datasets is! List) return const {};

    final result = <int, double>{};
    for (final set in datasets) {
      final roomId = set['room_id'];
      final points = set['data'];
      if (roomId is! int || points is! List || points.isEmpty) continue;

      final mean = points.last['mean'];
      if (mean is num) result[roomId] = mean.toDouble();
    }
    return result;
  }

  /// 호실에 등록된 포인트 롤(측정 항목) 목록. 그룹 API는 role_id만 주고 이름을 주지 않아
  /// 그룹에 어떤 항목이 묶여 있는지 보여주려면 이 목록과 맞춰봐야 한다.
  static Future<List<dynamic>> getPointRoles(int facilityId, int roomId) async {
    final url = Uri.parse('$_mappingUrl/roles/$facilityId/$roomId');
    final response = await ApiClient.get(url);
    final String responseBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      return jsonDecode(responseBody)['roles'] ?? [];
    } else {
      throw ApiException.rejected();
    }
  }

  static Future<List<dynamic>> getChartGroups(
    int facilityId,
    int roomId,
  ) async {
    final url = Uri.parse('$_mappingUrl/groups/$facilityId/$roomId');
    final response = await ApiClient.get(url);
    final String responseBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(responseBody);
      return decoded['groups'] ?? [];
    } else {
      throw ApiException.rejected();
    }
  }
}
