// ===============================================================
// 경로: lib/components/cross_compontents/board/post_detail_components.dart
// 명세: 게시글 상세 페이지를 위한 UI 박스 컴포넌트
// ===============================================================
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/l10n/l10n_context.dart';

/// Box #1: 게시글 본문 렌더링 박스 (읽기 전용 에디터 포함)
///
/// FocusNode/ScrollController는 build()가 아니라 State가 들고 있어야 한다.
/// build()에서 만들면 다시 그릴 때마다 새로 생성되어 스크롤 위치가 초기화된다.
class PostContentBox extends StatefulWidget {
  final Map<String, dynamic> post;
  final quill.QuillController quillController;

  const PostContentBox({
    super.key,
    required this.post,
    required this.quillController,
  });

  @override
  State<PostContentBox> createState() => _PostContentBoxState();
}

class _PostContentBoxState extends State<PostContentBox> {
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
    final post = widget.post;
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.colors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[${post['facility_name']}]',
            style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            post['title'] ?? context.l10n.postNoTitle,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.postMeta('${post['creator_name']}', '${post['created_at']}'),
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
          ),
          Divider(height: 28, color: context.colors.outline),
          // 읽기 전용 Quill Editor 영역
          quill.QuillEditor(
            controller: widget.quillController,
            focusNode: _focusNode,
            scrollController: _scrollController,
            config: quill.QuillEditorConfig(
              showCursor: false,
              autoFocus: false,
              // 본문에 들어간 이미지를 그리려면 extensions의 빌더가 필요하다.
              embedBuilders: FlutterQuillEmbeds.editorBuilders(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Box #2: 게시글 제어 박스 (수정/삭제 버튼)
class PostControlBox extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PostControlBox({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: Text(context.l10n.actionEdit),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onDelete,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 40),
            foregroundColor: context.colors.error,
            side: BorderSide(color: context.colors.error.withValues(alpha: 0.4)),
          ),
          icon: const Icon(Icons.delete_outline_rounded, size: 16),
          label: Text(context.l10n.actionDelete),
        ),
      ],
    );
  }
}

/// Box #3: 댓글 박스 (리스트 및 입력창)
class CommentBox extends StatelessWidget {
  final List<dynamic> comments;
  final String currentUserId;
  final bool isAdmin;
  final TextEditingController commentController;
  final VoidCallback onSubmit;
  final Function(int) onDelete;

  const CommentBox({
    super.key,
    required this.comments,
    required this.currentUserId,
    required this.isAdmin,
    required this.commentController,
    required this.onSubmit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.commentsCount(comments.length), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
          const SizedBox(height: 8),

          // 댓글 리스트
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: context.colors.outline),
            itemBuilder: (context, index) {
              final comment = comments[index];
              final bool isCreator = comment['creator_id'].toString() == currentUserId;

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(comment['content'] ?? '', style: TextStyle(fontSize: 14, color: context.colors.textPrimary)),
                subtitle: Text(
                  '${comment['creator_name']} · ${comment['created_at']}',
                  style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                ),
                trailing: (isCreator || isAdmin)
                    ? IconButton(
                      tooltip: context.l10n.commentDelete,
                  icon: Icon(Icons.close_rounded, size: 16, color: context.colors.textSecondary),
                  onPressed: () => onDelete(comment['comment_id']),
                )
                    : null,
              );
            },
          ),

          if (comments.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(context.l10n.commentsEmpty, style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
            ),

          const SizedBox(height: 12),

          // 댓글 입력부
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: context.l10n.commentHint,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(64, 48)),
                  child: Text(context.l10n.commentSubmit),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
