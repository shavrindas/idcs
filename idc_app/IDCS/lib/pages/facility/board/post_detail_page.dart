// ===============================================================
// 경로: lib/pages/facility/board/post_detail_page.dart
// 명세: 게시글 상세 조회 페이지
// ===============================================================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:idcs/components/cross_compontents/board/post_detail_components.dart';
import 'package:idcs/services/board/board_api_service.dart';
import 'package:idcs/services/common/user_api_service.dart';
import '../../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';

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
      _userRole = await UserApiService.getUserRole(widget.userId);

      final decoded = await BoardApiService.fetchPostDetail(
        postId: widget.postId,
        userId: widget.userId,
      );

      if (mounted) {
        setState(() {
          _post = decoded['data'];
          _comments = decoded['comments'] ?? [];
          _initQuillController(_post!['content']);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postLoadFailed(describeApiError(e)))));
      }
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
      await BoardApiService.deletePost(postId: widget.postId, userId: widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postDeleted)));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postDeleteFailed(describeApiError(e)))));
      }
    }
  }

  Future<void> _handleAddComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    try {
      await BoardApiService.addComment(
        postId: widget.postId,
        userId: widget.userId,
        content: content,
      );
      _commentController.clear();
      _fetchPostDetail();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.commentFailed(describeApiError(e)))));
      }
    }
  }

  Future<void> _handleDeleteComment(int commentId) async {
    try {
      await BoardApiService.deleteComment(commentId: commentId, userId: widget.userId);
      _fetchPostDetail();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.commentDeleteFailed(describeApiError(e)))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_post == null || _quillController == null) return Scaffold(body: Center(child: Text(context.l10n.dataUnavailable)));

    final bool isCreator = _post!['creator_id'].toString() == widget.userId;
    final bool isAdmin = _userRole == 'ADMIN' || _userRole == 'DEVELOPER';
    final bool canControl = isCreator || isAdmin;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.postDetailTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PostContentBox(post: _post!, quillController: _quillController!),
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