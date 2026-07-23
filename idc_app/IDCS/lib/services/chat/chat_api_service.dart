// 경로: lib/services/chat/chat_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:idcs/main.dart';

class ChatApiService {
  static String get _baseUrl => '${AppConfig.baseUrl}/chat';

  static Future<Map<String, dynamic>> getChatRooms(int facilityId, String userId) async {
    final url = Uri.parse('$_baseUrl/rooms/$facilityId?user_id=$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes));
    throw Exception('채팅방 목록을 불러오는데 실패했습니다.');
  }

  static Future<void> createGroupChat(String userId, String roomName, List<int> userIds) async {
    final url = Uri.parse('$_baseUrl/group?user_id=$userId');
    final response = await http.post(url, headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"room_name": roomName, "user_ids": userIds}),
    );
    if (response.statusCode != 201) throw Exception('단체 채팅방 생성 실패');
  }

  static Future<void> leaveOrDeleteRoom(int roomId, String userId, {String action = "delete"}) async {
    final url = Uri.parse('$_baseUrl/room/$roomId?user_id=$userId&action=$action');
    final response = await http.delete(url);
    if (response.statusCode != 200) throw Exception(jsonDecode(utf8.decode(response.bodyBytes))['detail'] ?? '실패했습니다.');
  }

  static Future<void> togglePinMessage(int roomId, int messageId, String userId) async {
    final url = Uri.parse('$_baseUrl/room/$roomId/pin/$messageId?user_id=$userId');
    final response = await http.post(url);
    if (response.statusCode != 200) throw Exception('메시지 고정에 실패했습니다.');
  }

  static Future<List<dynamic>> getParticipants(int roomId) async {
    final url = Uri.parse('$_baseUrl/room/$roomId/participants');
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes))['participants'];
    throw Exception('참여자 조회 실패');
  }

  static Future<void> markAsRead(int roomId, String userId) async {
    final url = Uri.parse('$_baseUrl/room/$roomId/read?user_id=$userId');
    await http.put(url);
  }

  static Future<List<dynamic>> getRoomMessages(int roomId, String userId, {String keyword = ""}) async {
    final encoded = Uri.encodeComponent(keyword);
    final url = Uri.parse('$_baseUrl/room/$roomId/messages?user_id=$userId&keyword=$encoded');
    final response = await http.get(url);
    if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes))['messages'];
    throw Exception('메시지 로드 실패');
  }
}