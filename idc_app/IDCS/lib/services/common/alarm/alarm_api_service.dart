import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../main.dart';

import 'package:intl/intl.dart';



class AlarmApiService {
  static String get _baseUrl => '${AppConfig.baseUrl}/alarms';

  /// 알람 조회 API
  static Future<List<dynamic>> getUserAlarms(String userId) async {
    final url = Uri.parse('$_baseUrl/$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['alarms'] ?? [];
    } else {
      throw Exception('권한 정보를 불러오는데 실패했습니다.');
    }
  }
  /// 알람 조회 API(시설)
  static Future<List<dynamic>> getFacilitiesAlarms(String facilityId) async {
    final url = Uri.parse('$_baseUrl/facility/$facilityId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['alarms'] ?? [];
    } else {
      throw Exception('권한 정보를 불러오는데 실패했습니다.');
    }
  }
}