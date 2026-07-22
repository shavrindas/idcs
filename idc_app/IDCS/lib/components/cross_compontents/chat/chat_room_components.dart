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
            onPressed: onMenuPressed, // 참여자 목록, 인원 추가 등 서랍 메뉴 호출
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

/// Box #2: 메시지 리스트 박스 (Telegram 스타일 말풍선)
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
                  Text(msg['created_at'], style: const TextStyle(fontSize: 8, color: Colors.black45)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Box #3: 채팅 입력 박스
class ChatInputBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  const ChatInputBox({super.key, required this.controller, required this.onSend, required this.onAttach});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: onAttach, // 파일, 이미지 첨부
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