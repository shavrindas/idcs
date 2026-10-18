// 경로: lib/services/chat/chat_api_service.dart
import 'dart:convert';
import '../common/api_client.dart';
import 'package:idcs/main.dart';

class ChatApiService {
  static String get _baseUrl => '${AppConfig.baseUrl}/chat';

  static Future<Map<String, dynamic>> getChatRooms(int facilityId, String userId) async {
    final url = Uri.parse('$_baseUrl/rooms/$facilityId?user_id=$userId');
    final response = await ApiClient.get(url);
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes));
    throw ApiException.rejected();
  }

  /// 시설에 등록된 사람들. 단체방을 만들 때 누구를 넣을지 고르는 데 쓴다.
  ///
  /// 예전에는 화면에서 사용자 ID 를 쉼표로 직접 받아 적게 했는데, 현장에서
  /// 남의 ID 번호를 아는 사람은 없다.
  static Future<List<Map<String, dynamic>>> getFacilityMembers(int facilityId) async {
    final url = Uri.parse('${AppConfig.webUrl}/facility-manager/facility/$facilityId/users');
    final response = await ApiClient.get(url);
    if (response.statusCode != 200) throw ApiException.rejected();

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final users = decoded['users'];
    return users is List ? users.whereType<Map<String, dynamic>>().toList() : const [];
  }

  static Future<void> createGroupChat(String userId, String roomName, List<int> userIds) async {
    final url = Uri.parse('$_baseUrl/group?user_id=$userId');
    final response = await ApiClient.post(url, headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"room_name": roomName, "user_ids": userIds}),
    );
    if (response.statusCode != 201) throw ApiException.rejected();
  }

  static Future<void> leaveOrDeleteRoom(int roomId, String userId, {String action = "delete"}) async {
    final url = Uri.parse('$_baseUrl/room/$roomId?user_id=$userId&action=$action');
    final response = await ApiClient.delete(url);
    if (response.statusCode != 200) {
      throw ApiException.rejected(jsonDecode(utf8.decode(response.bodyBytes)));
    }
  }

  static Future<void> togglePinMessage(int roomId, int messageId, String userId) async {
    final url = Uri.parse('$_baseUrl/room/$roomId/pin/$messageId?user_id=$userId');
    final response = await ApiClient.post(url);
    if (response.statusCode != 200) throw ApiException.rejected();
  }

  static Future<List<dynamic>> getParticipants(int roomId) async {
    final url = Uri.parse('$_baseUrl/room/$roomId/participants');
    final response = await ApiClient.get(url);
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes))['participants'];
    throw ApiException.rejected();
  }

  static Future<void> markAsRead(int roomId, String userId) async {
    final url = Uri.parse('$_baseUrl/room/$roomId/read?user_id=$userId');
    await ApiClient.put(url);
  }

  static Future<List<dynamic>> getRoomMessages(int roomId, String userId, {String keyword = ""}) async {
    final encoded = Uri.encodeComponent(keyword);
    final url = Uri.parse('$_baseUrl/room/$roomId/messages?user_id=$userId&keyword=$encoded');
    final response = await ApiClient.get(url);
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes))['messages'];
    throw ApiException.rejected();
  }
}