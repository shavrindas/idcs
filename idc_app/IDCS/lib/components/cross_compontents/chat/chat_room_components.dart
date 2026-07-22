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
            onPressed: onMenuPressed, // 참여자 목록 서랍(Drawer) 메뉴 호출
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

/// Box #2: 메시지 리스트 박스 (Telegram 스타일 말풍선 + 상세 기능)
class ChatMessageListBox extends StatelessWidget {
  final List<dynamic> messages;
  final String currentUserId;

  const ChatMessageListBox({super.key, required this.messages, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: ListView.builder(
        reverse: true, // 최신 메시지가 아래로 오도록 역순 배치
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          final isMine = msg['user_id'].toString() == currentUserId;

          return Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onLongPressStart: (details) {
                _showMessageMenu(context, details.globalPosition, isMine);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMine ? Colors.amber[200] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12).copyWith(
                    bottomRight: isMine ? const Radius.circular(0) : null,
                    bottomLeft: !isMine ? const Radius.circular(0) : null,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMine)
                      Text('User ${msg['user_id']}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                    Text(msg['content']),
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

  // 메시지 롱프레스 시 출력되는 팝업 메뉴
  void _showMessageMenu(BuildContext context, Offset position, bool isMine) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          value: 'reply',
          child: const Row(children: [Icon(Icons.reply, size: 18), SizedBox(width: 8), Text('답장')]),
        ),
        PopupMenuItem(
          value: 'pin',
          child: const Row(children: [Icon(Icons.push_pin, size: 18), SizedBox(width: 8), Text('고정')]),
        ),
        // 수정, 삭제는 요구사항에 따라 만들어두되 비활성화(enabled: false)
        PopupMenuItem(
          value: 'edit',
          enabled: false,
          child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.grey), const SizedBox(width: 8), const Text('수정', style: TextStyle(color: Colors.grey))]),
        ),
        PopupMenuItem(
          value: 'delete',
          enabled: false,
          child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.grey), const SizedBox(width: 8), const Text('삭제', style: TextStyle(color: Colors.grey))]),
        ),
      ],
    ).then((value) {
      if (value == 'reply') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('답장 기능 준비 중')));
      } else if (value == 'pin') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('메시지 고정 준비 중')));
      }
    });
  }
}

/// Box #3: 채팅 입력 박스 (파일, 이미지 첨부 버튼 포함)
class ChatInputBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInputBox({super.key, required this.controller, required this.onSend});

  void _showAttachMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.image), title: const Text('이미지 보내기'), onTap: () { Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.attach_file), title: const Text('파일 보내기'), onTap: () { Navigator.pop(context); }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAttachMenu(context), // 첨부 메뉴 호출
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '메시지를 입력하세요...',
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}