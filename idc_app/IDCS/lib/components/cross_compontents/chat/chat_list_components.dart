// 경로: lib/components/cross_compontents/chat/chat_list_components.dart
import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/l10n/l10n_context.dart';

/// Box #1: [관리자 전용] 채팅방 제어 박스 (1:1 생성 버튼 제거)
class ChatRoomControlBox extends StatelessWidget {
  final VoidCallback onCreateGroup;

  const ChatRoomControlBox({super.key, required this.onCreateGroup});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.colors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(context.l10n.chatRoomsManage, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: onCreateGroup,
            icon: const Icon(Icons.group_add_outlined, size: 16),
            label: Text(context.l10n.chatGroupCreate),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
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
    if (rooms.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: context.colors.cardShadow,
        ),
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline_rounded, color: context.colors.textSecondary.withValues(alpha: 0.6), size: 28),
            const SizedBox(height: 8),
            Text(context.l10n.chatRoomsEmpty, style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.colors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rooms.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: context.colors.outline),
        itemBuilder: (context, index) {
          final room = rooms[index];
          final isPinned = room['sort_priority'] < 4;
          final String roomName = room['room_name'] ?? '';
          final bool isGroup = room['type'] == 'GROUP';
          return ListTile(
            tileColor: isPinned ? context.colors.primary.withValues(alpha: 0.05) : null,
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  backgroundColor: room['type'] == 'FACILITY' ? context.colors.primary : context.colors.primaryDark,
                  child: isGroup
                      ? Icon(Icons.group_rounded, color: context.colors.onPrimary, size: 20)
                      : Text(
                          roomName.isNotEmpty ? roomName.substring(0, 1) : '?',
                          style: TextStyle(color: context.colors.onPrimary, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
                if (isPinned)
                  Positioned(
                    right: -2, bottom: -2,
                    child: Icon(Icons.push_pin_rounded, size: 14, color: context.colors.error),
                  ),
              ],
            ),
            title: Text(roomName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.colors.textPrimary)),
            subtitle: Text(
              room['last_message'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
            ),
            trailing: room['unread_count'] > 0
                ? CircleAvatar(
                    radius: 13,
                    backgroundColor: context.colors.error,
                    child: Text('${room['unread_count']}', style: TextStyle(color: context.colors.onPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
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
