// 경로: lib/components/cross_compontents/chat/chat_list_components.dart
import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';

/// Box #1: [관리자 전용] 채팅방 제어 박스 (1:1 생성 버튼 제거)
class ChatRoomControlBox extends StatelessWidget {
  final VoidCallback onCreateGroup;

  const ChatRoomControlBox({super.key, required this.onCreateGroup});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('채팅방 관리', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: onCreateGroup,
            icon: const Icon(Icons.group_add_outlined, size: 16),
            label: const Text('단체 채팅방 생성'),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 28),
            const SizedBox(height: 8),
            const Text('참여 중인 채팅방이 없습니다.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rooms.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.outline),
        itemBuilder: (context, index) {
          final room = rooms[index];
          final isPinned = room['sort_priority'] < 4;
          return ListTile(
            tileColor: isPinned ? AppColors.primary.withValues(alpha: 0.05) : null,
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  backgroundColor: room['type'] == 'FACILITY' ? AppColors.primary : AppColors.textSecondary,
                  child: Icon(room['type'] == 'GROUP' ? Icons.group_rounded : Icons.person_rounded, color: Colors.white, size: 20),
                ),
                if (isPinned)
                  const Positioned(
                    right: -2, bottom: -2,
                    child: Icon(Icons.push_pin_rounded, size: 14, color: AppColors.error),
                  ),
              ],
            ),
            title: Text(room['room_name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
            subtitle: Text(
              room['last_message'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            trailing: room['unread_count'] > 0
                ? CircleAvatar(
                    radius: 11,
                    backgroundColor: AppColors.error,
                    child: Text('${room['unread_count']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
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
