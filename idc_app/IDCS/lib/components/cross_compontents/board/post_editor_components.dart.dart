// ===============================================================
// 경로: lib/components/cross_compontents/board/post_editor_components.dart
// 명세: 게시글 작성/수정 폼을 위한 공통 UI 박스 컴포넌트
// ===============================================================
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:idcs/components/shared/async_action_button.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/l10n/l10n_context.dart';

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
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: titleController,
            decoration: InputDecoration(labelText: context.l10n.boardTitle),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onImageAttach,
              icon: const Icon(Icons.image_outlined, size: 18),
              label: Text(context.l10n.editorImageAttach),
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
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.colors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 툴바 영역.
          //
          // 기본값은 서른 개 가까운 버튼을 다섯 줄로 펼쳐 화면의 절반을 먹었다.
          // 여기에 적히는 것은 '3호 제상 이상, 수리 요청함' 같은 작업 기록이지
          // 문서가 아니다. 아래첨자·위첨자·코드블록·색 채우기 같은 것을 쓸 일은
          // 없고, 쓸 일 없는 버튼이 많으면 정작 쓸 버튼을 찾는 데 시간이 든다.
          //
          // 남긴 것: 되돌리기, 굵게, 제목, 목록. 한 줄에 들어간다.
          Container(
            color: context.colors.background,
            padding: const EdgeInsets.all(4.0),
            child: quill.QuillSimpleToolbar(
              controller: widget.quillController,
              config: const quill.QuillSimpleToolbarConfig(
                showFontFamily: false,
                showFontSize: false,
                showItalicButton: false,
                showUnderLineButton: false,
                showStrikeThrough: false,
                showInlineCode: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                showClearFormat: false,
                showSubscript: false,
                showSuperscript: false,
                showCodeBlock: false,
                showQuote: false,
                showIndent: false,
                showListCheck: false,
                showSearchButton: false,
                // 링크까지 두면 한 줄을 넘겨 둘째 줄에 버튼 하나만 남는다.
                // 작업 기록에 링크를 거는 일은 드물다.
                showLink: false,
                showDividers: false,
              ),
            ),
          ),
          Divider(height: 1, color: context.colors.outline),
          // 에디터 영역 (고정 높이 부여 후 자체 스크롤 비활성화 위임)
          Container(
            height: 400,
            padding: const EdgeInsets.all(12.0),
            color: context.colors.surface,
            child: quill.QuillEditor(
              controller: widget.quillController,
              focusNode: _focusNode,
              scrollController: _scrollController,
              config: quill.QuillEditorConfig(
                // 빈 하얀 칸만 있으면 여기에 무엇을 적어야 하는지 알 수 없다.
                placeholder: context.l10n.editorBodyHint,
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
  final Future<void> Function() onSubmit;

  const SubmitBox({
    super.key,
    required this.buttonLabel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncActionButton(label: buttonLabel, onPressed: onSubmit);
  }
}
