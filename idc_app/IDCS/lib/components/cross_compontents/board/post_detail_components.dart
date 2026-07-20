// ===============================================================
// 경로: lib/components/cross_compontents/board/post_detail_components.dart
// 명세: 게시글 상세 페이지를 위한 UI 박스 컴포넌트
// ===============================================================
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Box #1: 게시글 본문 렌더링 박스 (읽기 전용 에디터 포함)
class PostContentBox extends StatelessWidget {
  final Map<String, dynamic> post;
  final quill.QuillController quillController;

  const PostContentBox({
    super.key,
    required this.post,
    required this.quillController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[${post['facility_name']}]',
            style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            post['title'] ?? '제목 없음',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '작성자: ${post['creator_name']} | 작성일: ${post['created_at']}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Divider(height: 24),
          // 읽기 전용 Quill Editor 영역
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: quill.QuillEditor(
              controller: quillController,
              focusNode: FocusNode(),
              scrollController: ScrollController(),
              config: const quill.QuillEditorConfig(
                showCursor: false,
                autoFocus: false,
              ),
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
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('수정'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onDelete,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50),
            icon: const Icon(Icons.delete, size: 16, color: Colors.red),
            label: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('댓글', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // 댓글 리스트
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final comment = comments[index];
              final bool isCreator = comment['creator_id'].toString() == currentUserId;

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(comment['content'] ?? ''),
                subtitle: Text('${comment['creator_name']} | ${comment['created_at']}'),
                trailing: (isCreator || isAdmin)
                    ? IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                  onPressed: () => onDelete(comment['comment_id']),
                )
                    : null,
              );
            },
          ),

          if (comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('등록된 댓글이 없습니다.', style: TextStyle(color: Colors.grey)),
            ),

          const SizedBox(height: 12),

          // 댓글 입력부
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    hintText: '댓글을 입력하세요...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onSubmit,
                child: const Text('등록'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}