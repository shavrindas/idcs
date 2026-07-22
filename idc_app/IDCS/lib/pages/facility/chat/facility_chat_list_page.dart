// 경로: lib/pages/facility/chat/facility_chat_list_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/cross_compontents/chat/chat_list_components.dart';

class FacilityChatListPage extends StatefulWidget {
  final String userId;
  final String facilityId;

  const FacilityChatListPage({super.key, required this.userId, required this.facilityId});

  @override
  State<FacilityChatListPage> createState() => _FacilityChatListPageState();
}

class _FacilityChatListPageState extends State<FacilityChatListPage> {
  bool _isAdmin = false;
  List<dynamic> _rooms = [];

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    // TODO: ChatApiService.getChatRooms 호출 로직
    // 임시 더미 데이터로 대체
    setState(() {
      _isAdmin = true; // 임시
      _rooms = [
        {"room_id": 101, "room_name": "시설 ${widget.facilityId} 공식방", "type": "FACILITY", "last_message": "공지", "unread_count": 0, "sort_priority": 1},
        {"room_id": 102, "room_name": "유지보수방", "type": "GROUP", "last_message": "수리 완료", "unread_count": 3, "sort_priority": 4},
      ];
      // 프런트엔드 정렬 로직 (우선순위 오름차순 정렬)
      _rooms.sort((a, b) => (a['sort_priority'] as int).compareTo(b['sort_priority'] as int));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('시설 ${widget.facilityId} 메신저')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isAdmin) ...[
              ChatRoomControlBox(
                onCreateGroup: () { /* 단체방 생성 팝업 */ },
                onCreateDirect: () { /* 1:1방 초대 팝업 */ },
              ),
              const SizedBox(height: 16),
            ],
            ChatRoomListBox(
              rooms: _rooms,
              onRoomTapped: (roomId) => context.push('/chat_room/${widget.userId}/$roomId'),
              onRoomLongPressed: (roomId) {
                // TODO: 방 숨기기/삭제 바텀시트
              },
            ),
          ],
        ),
      ),
    );
  }
}