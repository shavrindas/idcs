// ===============================================================
// 경로: lib/pages/facility/board/post_create_page.dart
// 명세: 새 게시글 작성 페이지
// ===============================================================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:idcs/components/cross_compontents/board/post_editor_components.dart.dart';
import 'package:idcs/services/board/board_api_service.dart';

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
    final dummyImageUrl = "https://dummyimage.com/600x400/000/fff&text=Preview";
    final index = _quillController.selection.baseOffset;
    final length = _quillController.selection.extentOffset - index;
    _quillController.replaceText(index, length, quill.BlockEmbed.image(dummyImageUrl), null);
    _uploadedImageIds.add(999);
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목을 입력해주세요.')));
      return;
    }

    final String contentJson = jsonEncode(_quillController.document.toDelta().toJson());

    try {
      await BoardApiService.createPost(
        userId: widget.userId,
        boardId: int.parse(widget.facilityId),
        title: _titleController.text,
        contentJson: contentJson,
        imageIds: _uploadedImageIds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시글이 작성되었습니다.')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글 작성 실패: $e')));
      }
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