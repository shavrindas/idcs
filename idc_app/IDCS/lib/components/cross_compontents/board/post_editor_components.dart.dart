// ===============================================================
// 경로: lib/components/cross_compontents/board/post_editor_components.dart
// 명세: 게시글 작성/수정 폼을 위한 공통 UI 박스 컴포넌트
// ===============================================================
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

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
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: '제목',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onImageAttach,
              icon: const Icon(Icons.image, size: 18),
              label: const Text('이미지 첨부'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Box #2: 에디터 툴바 및 작성 영역 박스
class QuillEditorBox extends StatelessWidget {
  final quill.QuillController quillController;

  const QuillEditorBox({super.key, required this.quillController});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: Column(
        children: [
          // 툴바 영역
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(4.0),
            child: quill.QuillSimpleToolbar(
              controller: quillController,
              config: const quill.QuillSimpleToolbarConfig(),
            ),
          ),
          const Divider(height: 1),
          // 에디터 영역 (고정 높이 부여 후 자체 스크롤 비활성화 위임)
          Container(
            height: 400,
            padding: const EdgeInsets.all(12.0),
            color: Colors.white,
            child: quill.QuillEditor(
              controller: quillController,
              focusNode: FocusNode(),
              scrollController: ScrollController(),
              config: const quill.QuillEditorConfig(
                // 자체 스크롤을 막고 부모의 SingleChildScrollView에 의존하게 할 때 유용 (v11 방식)
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
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: ElevatedButton(
        onPressed: onSubmit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(buttonLabel, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}