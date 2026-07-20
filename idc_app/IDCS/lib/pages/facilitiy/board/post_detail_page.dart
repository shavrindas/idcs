// ===============================================================
// 경로: lib/pages/facilitiy/board/post_detail_page.dart
// 명세: 게시글 상세 조회 페이지
// ===============================================================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:idcs/components/cross_compontents/board/post_detail_components.dart';
import 'package:idcs/main.dart'; // AppConfig, AuthService

class PostDetailPage extends StatefulWidget {
  final int postId;
  final String userId;

  const PostDetailPage({super.key, required this.postId, required this.userId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  Map<String, dynamic>? _post;
  List<dynamic> _comments = [];
  bool _isLoading = true;
  String _userRole = 'USER';

  quill.QuillController? _quillController;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPostDetail();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _quillController?.dispose();
    super.dispose();
  }

  Future<void> _fetchPostDetail() async {
    setState(() => _isLoading = true);
    try {
      // 1. 유저 권한 로드 (삭제/수정 버튼 제어용)
      final roleRes = await http.get(Uri.parse('${AppConfig.baseUrl}/auth/${widget.userId}/role'));
      if (roleRes.statusCode == 200) {
        _userRole = jsonDecode(utf8.decode(roleRes.bodyBytes))['role'];
      }

      // 2. 포스트 상세 정보 로드
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/board/post/${widget.postId}?user_id=${widget.userId}'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        _post = decoded['data'];
        _comments = decoded['comments'] ?? [];

        // 3. Quill Controller 방어적 초기화
        _initQuillController(_post!['content']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글 로드 실패: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initQuillController(String contentStr) {
    try {
      final doc = quill.Document.fromJson(jsonDecode(contentStr));
      _quillController = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    } catch (e) {
      // JSON 파싱 실패 시 일반 텍스트로 처리하는 방어 로직
      final doc = quill.Document()..insert(0, contentStr);
      _quillController = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    }
  }

  Future<void> _handleDeletePost() async {
    try {
      final response = await http.delete(Uri.parse('${AppConfig.baseUrl}/board/post/${widget.postId}?user_id=${widget.userId}'));
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
        context.pop(); // 삭제 후 뒤로가기
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  Future<void> _handleAddComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/board/post/${widget.postId}/comment?user_id=${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"content": content}),
      );
      if (response.statusCode == 200) {
        _commentController.clear();
        _fetchPostDetail(); // 댓글 갱신
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 작성 실패: $e')));
    }
  }

  Future<void> _handleDeleteComment(int commentId) async {
    try {
      final response = await http.delete(Uri.parse('${AppConfig.baseUrl}/board/comment/$commentId?user_id=${widget.userId}'));
      if (response.statusCode == 200) {
        _fetchPostDetail();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 삭제 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_post == null || _quillController == null) return const Scaffold(body: Center(child: Text('데이터를 불러올 수 없습니다.')));

    final bool isCreator = _post!['creator_id'].toString() == widget.userId;
    final bool isAdmin = _userRole == 'ADMIN' || _userRole == 'DEVELOPER';
    final bool canControl = isCreator || isAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('게시글 상세 조회')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Box #1: 본문
            PostContentBox(post: _post!, quillController: _quillController!),

            // Box #2: 수정/삭제 제어 박스 (권한자에게만 표시)
            if (canControl) ...[
              const SizedBox(height: 8),
              PostControlBox(
                onEdit: () {
                  context.push('/post_edit/${widget.userId}/${widget.postId}').then((_) => _fetchPostDetail());
                },
                onDelete: _handleDeletePost,
              ),
            ],

            const SizedBox(height: 16),

            // Box #3: 댓글 박스
            CommentBox(
              comments: _comments,
              currentUserId: widget.userId,
              isAdmin: isAdmin,
              commentController: _commentController,
              onSubmit: _handleAddComment,
              onDelete: _handleDeleteComment,
            ),
          ],
        ),
      ),
    );
  }
}