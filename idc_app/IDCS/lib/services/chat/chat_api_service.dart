// 경로: lib/services/chat/chat_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:idcs/main.dart'; // AppConfig 사용

class ChatApiService {
  static String get _baseUrl => '${AppConfig.baseUrl}/chat';

  /// 단일 채팅방의 과거 메시지 기록 로드
  static Future<List<dynamic>> getRoomMessages(int roomId, String userId, {int limit = 50, int offset = 0}) async {
    final url = Uri.parse('$_baseUrl/room/$roomId/messages?user_id=$userId&limit=$limit&offset=$offset');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['messages'] ?? [];
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? '과거 대화 내역을 불러오는데 실패했습니다.');
    }
  }
}