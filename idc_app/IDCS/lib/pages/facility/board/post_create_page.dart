// ===============================================================
// 경로: lib/pages/facility/board/post_create_page.dart
// 명세: 새 게시글 작성 페이지
// ===============================================================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:idcs/components/cross_compontents/board/post_editor_components.dart.dart';
import 'package:idcs/services/board/board_api_service.dart';
import '../../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';

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
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final uploaded = await BoardApiService.uploadImage(
        bytes: await picked.readAsBytes(),
        filename: picked.name,
      );

      final index = _quillController.selection.baseOffset;
      final length = _quillController.selection.extentOffset - index;
      _quillController.replaceText(index, length, quill.BlockEmbed.image(uploaded.imageUrl), null);
      _uploadedImageIds.add(uploaded.imageId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.imageAttachFailed(describeApiError(context, e)))));
    }
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postTitleRequired)));
      return;
    }

    final String contentJson = jsonEncode(_quillController.document.toDelta().toJson());

    try {
      await BoardApiService.createPost(
        userId: widget.userId,
        facilityId: int.parse(widget.facilityId),
        title: _titleController.text,
        contentJson: contentJson,
        imageIds: _uploadedImageIds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postCreated)));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postCreateFailed(describeApiError(context, e)))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.postCreateTitle(widget.facilityId))),
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
              buttonLabel: context.l10n.postCreateSubmit,
              onSubmit: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}