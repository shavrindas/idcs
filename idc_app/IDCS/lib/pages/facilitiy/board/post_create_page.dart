// ===============================================================
// 경로: lib/pages/facilitiy/board/post_create_page.dart
// 명세: 새 게시글 작성 페이지
// ===============================================================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:idcs/components/cross_compontents/board/post_editor_components.dart.dart';
import 'package:idcs/main.dart';

class PostCreatePage extends StatefulWidget {
  final String facilityId;
  final String userId;

  const PostCreatePage({super.key, required this.facilityId, required this.userId});

  @override
  State<PostCreatePage> createState() => _PostCreatePageState();
}

class _PostCreatePageState extends State<PostCreatePage> {
  final TextEditingController _titleController = TextEditingController();
  late quill.QuillController _quillController;
  final List<int> _uploadedImageIds = [];

  @override
  void initState() {
    super.initState();
    _quillController = quill.QuillController(
      document: quill.Document(),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: false,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _handleImageAttach() async {
    // TODO: EditorImageService 를 통한 실제 이미지 업로드 로직 호출
    // 테스트용 더미 URL 삽입
    final dummyImageUrl = "https://dummyimage.com/600x400/000/fff&text=Preview";
    final index = _quillController.selection.baseOffset;
    final length = _quillController.selection.extentOffset - index;
    _quillController.replaceText(index, length, quill.BlockEmbed.image(dummyImageUrl), null);
    _uploadedImageIds.add(999); // 더미 이미지 ID
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목을 입력해주세요.')));
      return;
    }

    final String contentJson = jsonEncode(_quillController.document.toDelta().toJson());

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/board/post?user_id=${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "board_id": int.parse(widget.facilityId),
          "title": _titleController.text,
          "content": contentJson,
          "image_ids": _uploadedImageIds
        }),
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시글이 작성되었습니다.')));
        context.pop(); // 목록으로 복귀
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글 작성 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('새 게시글 작성 (시설 ${widget.facilityId})')),
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
            QuillEditorBox(quillController: _quillController),
            const SizedBox(height: 16),
            SubmitBox(
              buttonLabel: '게시글 등록하기',
              onSubmit: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}