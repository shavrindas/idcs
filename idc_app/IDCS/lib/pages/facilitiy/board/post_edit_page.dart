// ===============================================================
// 경로: lib/pages/facilitiy/board/post_edit_page.dart
// 명세: 기존 게시글 수정 페이지
// ===============================================================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:idcs/main.dart';
import 'package:idcs/components/cross_compontents/board/post_editor_components.dart.dart';
class PostEditPage extends StatefulWidget {
  final int postId;
  final String userId;

  const PostEditPage({super.key, required this.postId, required this.userId});

  @override
  State<PostEditPage> createState() => _PostEditPageState();
}

class _PostEditPageState extends State<PostEditPage> {
  final TextEditingController _titleController = TextEditingController();
  quill.QuillController? _quillController;
  final List<int> _newImageIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOriginalPost();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController?.dispose();
    super.dispose();
  }

  Future<void> _fetchOriginalPost() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/board/post/${widget.postId}?user_id=${widget.userId}'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes))['data'];

        _titleController.text = decoded['title'];
        _initQuillController(decoded['content']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('원문 로드 실패: $e')));
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
        readOnly: false,
      );
    } catch (e) {
      final doc = quill.Document()..insert(0, contentStr);
      _quillController = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: false,
      );
    }
  }

  Future<void> _handleImageAttach() async {
    // TODO: 이미지 업로드 로직
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.trim().isEmpty) return;

    final String contentJson = jsonEncode(_quillController!.document.toDelta().toJson());

    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/board/post/${widget.postId}?user_id=${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "title": _titleController.text,
          "content": contentJson,
          "image_ids": _newImageIds
        }),
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('수정 완료되었습니다.')));
        context.pop(); // 상세 페이지로 복귀
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('수정 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _quillController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('게시글 수정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PostInputBox(
              titleController: _titleController,
              onImageAttach: _handleImageAttach,
            ),
            const SizedBox(height: 16),
            QuillEditorBox(quillController: _quillController!),
            const SizedBox(height: 16),
            SubmitBox(
              buttonLabel: '수정 완료하기',
              onSubmit: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}