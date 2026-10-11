// ===============================================================
// 경로: lib/pages/facility/board/post_edit_page.dart
// 명세: 기존 게시글 수정 페이지
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
      final decoded = await BoardApiService.fetchPostDetail(
        postId: widget.postId,
        userId: widget.userId,
      );
      final postData = decoded['data'];

      _titleController.text = postData['title'];
      _initQuillController(postData['content']);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postSourceLoadFailed(describeApiError(context, e)))));
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
    final controller = _quillController;
    if (controller == null) return;

    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final uploaded = await BoardApiService.uploadImage(
        bytes: await picked.readAsBytes(),
        filename: picked.name,
      );

      final index = controller.selection.baseOffset;
      final length = controller.selection.extentOffset - index;
      controller.replaceText(index, length, quill.BlockEmbed.image(uploaded.imageUrl), null);
      _newImageIds.add(uploaded.imageId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.imageAttachFailed(describeApiError(context, e)))));
    }
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.trim().isEmpty) return;

    final String contentJson = jsonEncode(_quillController!.document.toDelta().toJson());

    try {
      await BoardApiService.updatePost(
        postId: widget.postId,
        userId: widget.userId,
        title: _titleController.text,
        contentJson: contentJson,
        imageIds: _newImageIds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postUpdated)));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.postUpdateFailed(describeApiError(context, e)))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _quillController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.postEditTitle)),
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
              buttonLabel: context.l10n.postEditSubmit,
              onSubmit: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}