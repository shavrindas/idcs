// ===============================================================
// 경로: lib/components/cross_compontents/board/post_editor_components.dart
// 명세: 게시글 작성/수정 폼을 위한 공통 UI 박스 컴포넌트
// ===============================================================
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:idcs/theme/app_theme.dart';

/// Box #1: 제목 입력 및 이미지 첨부 제어 박스
class PostInputBox extends StatelessWidget {
  final TextEditingController titleController;
  final VoidCallback onImageAttach;

  const PostInputBox({
    super.key,
    required this.titleController,
    required this.onImageAttach,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: '제목'),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onImageAttach,
              icon: const Icon(Icons.image_outlined, size: 18),
              label: const Text('이미지 첨부'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Box #2: 에디터 툴바 및 작성 영역 박스
///
/// FocusNode/ScrollController를 build() 안에서 만들면 화면이 다시 그려질 때마다
/// 새로 생성되어 입력 도중 포커스와 스크롤 위치가 날아간다. State가 들고 있어야 한다.
class QuillEditorBox extends StatefulWidget {
  final quill.QuillController quillController;

  const QuillEditorBox({super.key, required this.quillController});

  @override
  State<QuillEditorBox> createState() => _QuillEditorBoxState();
}

class _QuillEditorBoxState extends State<QuillEditorBox> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 툴바 영역
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.all(4.0),
            child: quill.QuillSimpleToolbar(
              controller: widget.quillController,
              config: const quill.QuillSimpleToolbarConfig(),
            ),
          ),
          const Divider(height: 1, color: AppColors.outline),
          // 에디터 영역 (고정 높이 부여 후 자체 스크롤 비활성화 위임)
          Container(
            height: 400,
            padding: const EdgeInsets.all(12.0),
            color: AppColors.surface,
            child: quill.QuillEditor(
              controller: widget.quillController,
              focusNode: _focusNode,
              scrollController: _scrollController,
              config: quill.QuillEditorConfig(
                // 이미지 블록은 본체가 그리지 못해 extensions의 빌더를 넘겨야 한다.
                embedBuilders: FlutterQuillEmbeds.editorBuilders(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Box #3: 제출(완료) 버튼 박스
class SubmitBox extends StatelessWidget {
  final String buttonLabel;
  final VoidCallback onSubmit;

  const SubmitBox({
    super.key,
    required this.buttonLabel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onSubmit,
      child: Text(buttonLabel),
    );
  }
}
