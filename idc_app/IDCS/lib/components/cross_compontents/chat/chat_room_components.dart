// 경로: lib/components/cross_compontents/chat/chat_room_components.dart
import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';

/// Box #1: 채팅방 헤더
class ChatRoomHeaderBox extends StatelessWidget {
  final String roomName;
  final VoidCallback onMenuPressed;
  const ChatRoomHeaderBox({super.key, required this.roomName, required this.onMenuPressed});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(roomName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textSecondary),
            onPressed: onMenuPressed,
            constraints: const BoxConstraints(), padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

/// Box #2: 메시지 리스트 박스 (답장 UI 및 고정 아이콘 추가)
class ChatMessageListBox extends StatelessWidget {
  final List<dynamic> messages;
  final String currentUserId;
  final Function(Map<String, dynamic>, String action) onAction; // 메뉴 이벤트 상위 전달

  const ChatMessageListBox({super.key, required this.messages, required this.currentUserId, required this.onAction});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text('메시지가 없습니다.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      );
    }

    return Container(
      color: AppColors.background,
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          final isMine = msg['user_id'].toString() == currentUserId;
          final isPinned = msg['is_pinned'] == true;

          return Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onLongPressStart: (details) {
                _showMessageMenu(context, details.globalPosition, msg);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                child: Column(
                  crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMine)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2, left: 4),
                        child: Text('User ${msg['user_id']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMine ? AppColors.primary : AppColors.surface,
                        border: isMine ? null : Border.all(color: AppColors.outline),
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomRight: isMine ? const Radius.circular(4) : null,
                          bottomLeft: !isMine ? const Radius.circular(4) : null,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 답장 원문 표시
                          if (msg['parent_content'] != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                border: Border(left: BorderSide(color: isMine ? Colors.white70 : AppColors.textSecondary, width: 2)),
                              ),
                              child: Text(
                                msg['parent_content'],
                                style: TextStyle(fontSize: 12, color: isMine ? Colors.white70 : AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isPinned) Icon(Icons.push_pin_rounded, size: 13, color: isMine ? Colors.white : AppColors.error),
                              if (isPinned) const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  msg['content'],
                                  style: TextStyle(fontSize: 14, color: isMine ? Colors.white : AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                      child: Text(msg['created_at'] ?? '', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMessageMenu(BuildContext context, Offset position, Map<String, dynamic> msg) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        const PopupMenuItem(value: 'reply', child: Row(children: [Icon(Icons.reply_rounded, size: 18), SizedBox(width: 8), Text('답장')])),
        const PopupMenuItem(value: 'pin', child: Row(children: [Icon(Icons.push_pin_outlined, size: 18), SizedBox(width: 8), Text('고정 토글')])),
        const PopupMenuItem(value: 'edit', enabled: false, child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: Colors.grey), SizedBox(width: 8), Text('수정', style: TextStyle(color: Colors.grey))])),
        const PopupMenuItem(value: 'delete', enabled: false, child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey), SizedBox(width: 8), Text('삭제', style: TextStyle(color: Colors.grey))])),
      ],
    ).then((value) {
      if (value != null) onAction(msg, value);
    });
  }
}

/// Box #3: 채팅 입력 박스 (답장 뷰잉 추가)
class ChatInputBox extends StatelessWidget {
  final TextEditingController controller;
  final Map<String, dynamic>? replyingTo;
  final VoidCallback onSend;
  final VoidCallback onCancelReply;

  const ChatInputBox({super.key, required this.controller, required this.replyingTo, required this.onSend, required this.onCancelReply});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: Column(
        children: [
          if (replyingTo != null)
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '답장: ${replyingTo!['content']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                    onPressed: onCancelReply,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.textSecondary),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      border: InputBorder.none,
                      filled: false,
                      isDense: true,
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed: onSend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
