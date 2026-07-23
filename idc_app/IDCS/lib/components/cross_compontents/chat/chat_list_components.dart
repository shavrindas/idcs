// 경로: lib/components/cross_compontents/chat/chat_list_components.dart
import 'package:flutter/material.dart';

/// Box #1: [관리자 전용] 채팅방 제어 박스 (1:1 생성 버튼 제거)
class ChatRoomControlBox extends StatelessWidget {
  final VoidCallback onCreateGroup;

  const ChatRoomControlBox({super.key, required this.onCreateGroup});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('채팅방 관리 (관리자)', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onCreateGroup,
            icon: const Icon(Icons.group_add, size: 16),
            label: const Text('단체 채팅방 생성'),
          ),
        ],
      ),
    );
  }
}

/// Box #2: 채팅방 목록 박스 (유지)
class ChatRoomListBox extends StatelessWidget {
  final List<dynamic> rooms;
  final Function(int) onRoomTapped;
  final Function(int) onRoomLongPressed;

  const ChatRoomListBox({super.key, required this.rooms, required this.onRoomTapped, required this.onRoomLongPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rooms.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final room = rooms[index];
          final isPinned = room['sort_priority'] < 4;
          return ListTile(
            tileColor: isPinned ? Colors.blue.withOpacity(0.05) : null,
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: room['type'] == 'FACILITY' ? Colors.blue : Colors.grey,
                  child: Icon(room['type'] == 'GROUP' ? Icons.group : Icons.person, color: Colors.white),
                ),
                if (isPinned)
                  const Positioned(right: 0, bottom: 0, child: Icon(Icons.push_pin, size: 12, color: Colors.red))
              ],
            ),
            title: Text(room['room_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(room['last_message'], maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: room['unread_count'] > 0
                ? CircleAvatar(
              radius: 12, backgroundColor: Colors.red,
              child: Text('${room['unread_count']}', style: const TextStyle(color: Colors.white, fontSize: 10)),
            )
                : null,
            onTap: () => onRoomTapped(room['room_id']),
            onLongPress: () => onRoomLongPressed(room['room_id']),
          );
        },
      ),
    );
  }
}