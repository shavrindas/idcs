// 경로: lib/components/cross_compontents/chat/chat_room_components.dart
import 'package:flutter/material.dart';
import 'package:idcs/components/shared/time_format.dart';
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

/// Box #1-2: 상단 고정 메시지 배너. 메시지 목록과 별개 위젯이라 스크롤해도
/// 화면 위쪽에 그대로 남아 있는다 — 고정한 메시지를 찾으려고 위로 스크롤해
/// 올라갈 필요가 없게 하려는 목적이다.
class ChatPinnedBannerBox extends StatelessWidget {
  final List<dynamic> pinnedMessages;
  final Map<int, String> senderNames;
  final void Function(int messageId) onUnpin;

  const ChatPinnedBannerBox({
    super.key,
    required this.pinnedMessages,
    required this.onUnpin,
    this.senderNames = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (pinnedMessages.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 160),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.06),
        border: Border(bottom: BorderSide(color: context.colors.outline)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 2),
        itemCount: pinnedMessages.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: context.colors.outline),
        itemBuilder: (context, index) {
          final msg = pinnedMessages[index];
          final sender = senderNames[msg['user_id']] ?? '#${msg['user_id']}';
          final isImage = msg['message_type'] == 'IMAGE';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.push_pin_rounded, size: 15, color: context.colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(sender, style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
                      Text(
                        isImage ? context.l10n.chatPinnedImageLabel : (msg['content']?.toString() ?? ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.chatUnpin,
                  icon: Icon(Icons.close_rounded, size: 16, color: context.colors.textSecondary),
                  onPressed: () => onUnpin(msg['message_id']),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Box #2: 메시지 리스트 박스 (답장 UI 및 고정 아이콘 추가)
class ChatMessageListBox extends StatelessWidget {
  final List<dynamic> messages;
  final String currentUserId;
  final Function(Map<String, dynamic>, String action) onAction; // 메뉴 이벤트 상위 전달

  /// 보낸 사람 id -> 이름. 메시지에는 user_id 밖에 없다.
  final Map<int, String> senderNames;

  const ChatMessageListBox({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.onAction,
    this.senderNames = const {},
  });

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
                _showMessageMenu(context, details.globalPosition, msg, isMine);
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
                        child: Text(
                          // 참여자 목록에서 못 찾으면 — 방을 떠난 사람 등 —
                          // 번호라도 보여 준다. 빈칸보다는 낫다.
                          senderNames[msg['user_id']] ?? '#${msg['user_id']}',
                          style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                        ),
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
                                child: msg['message_type'] == 'IMAGE'
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          msg['content'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Icon(
                                            Icons.broken_image_outlined,
                                            color: isMine ? context.colors.onPrimary : context.colors.textSecondary,
                                          ),
                                        ),
                                      )
                                    : Text(
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
                      child: Text(
                        formatChatTime(msg['created_at']?.toString() ?? ''),
                        style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                      ),
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

  void _showMessageMenu(BuildContext context, Offset position, Map<String, dynamic> msg, bool isMine) {
    // 수정/삭제는 본인 글에서만 의미가 있다 — 남의 글에는 눌러도 안 되는
    // 버튼을 아예 안 보여주는 편이 "눌렀는데 비활성" 보다 낫다.
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(value: 'reply', child: Row(children: [Icon(Icons.reply_rounded, size: 18), SizedBox(width: 8), Text(context.l10n.chatReply)])),
        PopupMenuItem(value: 'pin', child: Row(children: [Icon(Icons.push_pin_outlined, size: 18), SizedBox(width: 8), Text(context.l10n.chatPinToggle)])),
        if (isMine) PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined, size: 18), const SizedBox(width: 8), Text(context.l10n.actionEdit)])),
        if (isMine) PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: context.colors.error), const SizedBox(width: 8), Text(context.l10n.actionDelete, style: TextStyle(color: context.colors.error))])),
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
  final VoidCallback onAttach;

  const ChatInputBox({super.key, required this.controller, required this.replyingTo, required this.onSend, required this.onCancelReply, required this.onAttach});

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
                  icon: Icon(Icons.add_circle_outline_rounded, color: context.colors.primary),
                  onPressed: onAttach,
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
