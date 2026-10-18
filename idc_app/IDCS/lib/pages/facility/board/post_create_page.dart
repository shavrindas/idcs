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
import 'package:idcs/components/shared/app_toast.dart';
import 'package:idcs/theme/app_theme.dart';

class PostCreatePage extends StatefulWidget {
  final String facilityId;
  final String userId;

  const PostCreatePage({
    super.key,
    required this.facilityId,
    required this.userId,
  });

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

  /// 아직 올리지 않은 글이 있는지. 제목이든 본문이든 손댔으면 있는 것으로 본다.
  bool get _hasDraft =>
      _titleController.text.trim().isNotEmpty ||
      _quillController.document.toPlainText().trim().isNotEmpty;

  /// 뒤로 나가려 할 때 한 번 묻는다.
  ///
  /// 현장에서 쓰는 작업 기록은 짧지 않다. 길게 적어 둔 것이 뒤로 한 번에
  /// 사라지면 다시 쓰지 않게 된다.
  Future<bool> _confirmDiscard() async {
    if (!_hasDraft) return true;

    final l10n = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.discardDraftTitle),
        content: Text(l10n.discardDraftBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.discardDraftKeep),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: Text(l10n.discardDraftLeave),
          ),
        ],
      ),
    );
    return leave ?? false;
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
      _quillController.replaceText(
        index,
        length,
        quill.BlockEmbed.image(uploaded.imageUrl),
        null,
      );
      _uploadedImageIds.add(uploaded.imageId);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        context.l10n.imageAttachFailed(describeApiError(context, e)),
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.trim().isEmpty) {
      AppToast.warning(context, context.l10n.postTitleRequired);
      return;
    }

    final String contentJson = jsonEncode(
      _quillController.document.toDelta().toJson(),
    );

    try {
      await BoardApiService.createPost(
        userId: widget.userId,
        facilityId: int.parse(widget.facilityId),
        title: _titleController.text,
        contentJson: contentJson,
        imageIds: _uploadedImageIds,
      );

      if (mounted) {
        AppToast.success(context, context.l10n.postCreated);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          context.l10n.postCreateFailed(describeApiError(context, e)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.postCreateTitle)),
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
      ),
    );
  }
}
