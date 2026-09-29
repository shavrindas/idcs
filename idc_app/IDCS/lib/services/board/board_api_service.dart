// ===============================================================
// 경로: lib/services/board/board_api_service.dart
// 명세: 게시판(통합/시설/상세/작성/수정/댓글) 전용 API 서비스
// ===============================================================
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:idcs/main.dart'; // AppConfig
import 'package:idcs/models/post_model.dart';

class BoardApiService {
  static String get _baseUrl => '${AppConfig.baseUrl}/board';

  /// 1. 시설 게시판 목록 조회
  static Future<Map<String, dynamic>> fetchFacilityPosts({
    required String facilityId,
    required String userId,
    required int page,
    required int limit,
    required String searchType,
    required String keyword,
  }) async {
    final encodedKeyword = Uri.encodeComponent(keyword.trim());
    final url = Uri.parse(
      '$_baseUrl/facility/$facilityId?user_id=$userId&page=$page&limit=$limit&search_type=$searchType&keyword=$encodedKeyword',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final posts = (decoded['data'] as List).map((p) => PostModel.fromJson(p)).toList();
      final totalPages = decoded['meta']['total_pages'] ?? 1;
      return {'posts': posts, 'totalPages': totalPages};
    }
    throw Exception('시설 게시글을 불러오는데 실패했습니다.');
  }

  /// 2. 통합 게시판 목록 조회
  static Future<Map<String, dynamic>> fetchIntegratedPosts({
    required String userId,
    required int page,
    required int limit,
    required String searchType,
    required String keyword,
  }) async {
    final encodedKeyword = Uri.encodeComponent(keyword.trim());
    final url = Uri.parse(
      '$_baseUrl/integrated?user_id=$userId&page=$page&limit=$limit&search_type=$searchType&keyword=$encodedKeyword',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final posts = (decoded['data'] as List).map((p) => PostModel.fromJson(p)).toList();
      final totalPages = decoded['meta']['total_pages'] ?? 1;
      return {'posts': posts, 'totalPages': totalPages};
    }
    throw Exception('통합 게시글을 불러오는데 실패했습니다.');
  }

  /// 3. 단일 게시글 상세 조회 (댓글 포함)
  static Future<Map<String, dynamic>> fetchPostDetail({
    required int postId,
    required String userId,
  }) async {
    final url = Uri.parse('$_baseUrl/post/$postId?user_id=$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('게시글 상세 정보를 불러오는데 실패했습니다.');
  }

  /// 4. 새 게시글 생성
  /// 에디터 이미지 사전 업로드. 글을 저장할 때 반환된 image_id를 함께 보내면
  /// 서버가 그 이미지를 해당 글에 묶어준다.
  static Future<({int imageId, String imageUrl})> uploadImage({
    required List<int> bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/image/upload'))
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final streamed = await request.send();
    final body = utf8.decode(await streamed.stream.toBytes());
    final decoded = jsonDecode(body);

    if (streamed.statusCode == 200) {
      return (imageId: decoded['image_id'] as int, imageUrl: decoded['image_url'] as String);
    }
    throw Exception(decoded['detail'] ?? '이미지 업로드에 실패했습니다.');
  }

  static Future<int> createPost({
    required String userId,
    required int facilityId,
    required String title,
    required String contentJson,
    required List<int> imageIds,
  }) async {
    final url = Uri.parse('$_baseUrl/post?user_id=$userId');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "facility_id": facilityId,
        "title": title,
        "content": contentJson,
        "image_ids": imageIds,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded['post_id'];
    }
    throw Exception('게시글 작성에 실패했습니다.');
  }

  /// 5. 게시글 수정
  static Future<void> updatePost({
    required int postId,
    required String userId,
    required String title,
    required String contentJson,
    required List<int> imageIds,
  }) async {
    final url = Uri.parse('$_baseUrl/post/$postId?user_id=$userId');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "title": title,
        "content": contentJson,
        "image_ids": imageIds,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('게시글 수정에 실패했습니다.');
    }
  }

  /// 6. 게시글 삭제
  static Future<void> deletePost({
    required int postId,
    required String userId,
  }) async {
    final url = Uri.parse('$_baseUrl/post/$postId?user_id=$userId');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('게시글 삭제에 실패했습니다.');
    }
  }

  /// 7. 댓글 작성
  static Future<void> addComment({
    required int postId,
    required String userId,
    required String content,
  }) async {
    final url = Uri.parse('$_baseUrl/post/$postId/comment?user_id=$userId');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"content": content}),
    );

    if (response.statusCode != 200) {
      throw Exception('댓글 작성에 실패했습니다.');
    }
  }

  /// 8. 댓글 삭제
  static Future<void> deleteComment({
    required int commentId,
    required String userId,
  }) async {
    final url = Uri.parse('$_baseUrl/comment/$commentId?user_id=$userId');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('댓글 삭제에 실패했습니다.');
    }
  }
}