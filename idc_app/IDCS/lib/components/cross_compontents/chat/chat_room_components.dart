// 경로: lib/components/cross_compontents/chat/chat_room_components.dart
import 'package:flutter/material.dart';

/// Box #1: 채팅방 헤더
class ChatRoomHeaderBox extends StatelessWidget {
  final String roomName;
  final VoidCallback onMenuPressed;
  const ChatRoomHeaderBox({super.key, required this.roomName, required this.onMenuPressed});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey), color: Colors.grey[200]),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(roomName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.menu),
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
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: ListView.builder(
        reverse: true,
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
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                child: Column(
                  crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMine)
                      Text('User ${msg['user_id']}', style: const TextStyle(fontSize: 10, color: Colors.black54)),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMine ? Colors.amber[200] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12).copyWith(
                          bottomRight: isMine ? const Radius.circular(0) : null,
                          bottomLeft: !isMine ? const Radius.circular(0) : null,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 답장 원문 표시
                          if (msg['parent_content'] != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.only(left: 6),
                              decoration: const BoxDecoration(border: Border(left: BorderSide(color: Colors.black38, width: 2))),
                              child: Text(msg['parent_content'], style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isPinned) const Icon(Icons.push_pin, size: 14, color: Colors.red),
                              if (isPinned) const SizedBox(width: 4),
                              Flexible(child: Text(msg['content'])),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(msg['created_at'] ?? '', style: const TextStyle(fontSize: 8, color: Colors.black45)),
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
        const PopupMenuItem(value: 'reply', child: Row(children: [Icon(Icons.reply, size: 18), SizedBox(width: 8), Text('답장')])),
        const PopupMenuItem(value: 'pin', child: Row(children: [Icon(Icons.push_pin, size: 18), SizedBox(width: 8), Text('고정 토글')])),
        const PopupMenuItem(value: 'edit', enabled: false, child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.grey), SizedBox(width: 8), Text('수정', style: TextStyle(color: Colors.grey))])),
        const PopupMenuItem(value: 'delete', enabled: false, child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.grey), SizedBox(width: 8), Text('삭제', style: TextStyle(color: Colors.grey))])),
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
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: Column(
        children: [
          if (replyingTo != null)
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('답장: ${replyingTo!['content']}', maxLines: 1, overflow: TextOverflow.ellipsis)),
                  IconButton(icon: const Icon(Icons.close, size: 16), onPressed: onCancelReply, constraints: const BoxConstraints(), padding: EdgeInsets.zero),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () {}),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: '메시지를 입력하세요...', border: InputBorder.none, isDense: true),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: onSend),
              ],
            ),
          ),
        ],
      ),
    );
  }
}