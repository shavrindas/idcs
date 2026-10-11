// 경로: lib/components/cross_compontents/chat/chat_room_components.dart
import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/l10n/l10n_context.dart';

/// Box #1: 채팅방 헤더
class ChatRoomHeaderBox extends StatelessWidget {
  final String roomName;
  final VoidCallback onMenuPressed;
  const ChatRoomHeaderBox({super.key, required this.roomName, required this.onMenuPressed});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(bottom: BorderSide(color: context.colors.outline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(roomName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
          IconButton(
            tooltip: context.l10n.chatMenu,
            icon: Icon(Icons.menu_rounded, color: context.colors.textSecondary),
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
      return Center(
        child: Text(context.l10n.chatNoMessages, style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
      );
    }

    return Container(
      color: context.colors.background,
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
                        child: Text('User ${msg['user_id']}', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                      ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMine ? context.colors.primary : context.colors.surface,
                        border: isMine ? null : Border.all(color: context.colors.outline),
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
                                border: Border(left: BorderSide(color: isMine ? context.colors.onPrimary.withValues(alpha: 0.7) : context.colors.textSecondary, width: 2)),
                              ),
                              child: Text(
                                msg['parent_content'],
                                style: TextStyle(fontSize: 12, color: isMine ? context.colors.onPrimary.withValues(alpha: 0.7) : context.colors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isPinned) Icon(Icons.push_pin_rounded, size: 13, color: isMine ? context.colors.onPrimary : context.colors.error),
                              if (isPinned) const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  msg['content'],
                                  style: TextStyle(fontSize: 14, color: isMine ? context.colors.onPrimary : context.colors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                      child: Text(msg['created_at'] ?? '', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
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
        PopupMenuItem(value: 'reply', child: Row(children: [Icon(Icons.reply_rounded, size: 18), SizedBox(width: 8), Text(context.l10n.chatReply)])),
        PopupMenuItem(value: 'pin', child: Row(children: [Icon(Icons.push_pin_outlined, size: 18), SizedBox(width: 8), Text(context.l10n.chatPinToggle)])),
        PopupMenuItem(value: 'edit', enabled: false, child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: context.colors.textSecondary), const SizedBox(width: 8), Text(context.l10n.actionEdit, style: TextStyle(color: context.colors.textSecondary))])),
        PopupMenuItem(value: 'delete', enabled: false, child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: context.colors.textSecondary), const SizedBox(width: 8), Text(context.l10n.actionDelete, style: TextStyle(color: context.colors.textSecondary))])),
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
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outline)),
      ),
      child: Column(
        children: [
          if (replyingTo != null)
            Container(
              color: context.colors.background,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.reply_rounded, size: 16, color: context.colors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.chatReplyingTo('${replyingTo!['content']}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.actionClose,
                    icon: Icon(Icons.close_rounded, size: 16, color: context.colors.textSecondary),
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
                  tooltip: context.l10n.chatAttach,
                  icon: Icon(Icons.add_circle_outline_rounded, color: context.colors.textSecondary),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: context.l10n.chatInputHint,
                      border: InputBorder.none,
                      filled: false,
                      isDense: true,
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.chatSend,
                  icon: Icon(Icons.send_rounded, color: context.colors.primary),
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
