// 경로: lib/pages/facility/chat/chat_room_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:idcs/main.dart';
import 'package:idcs/services/common/web_socket_service.dart';
import 'package:idcs/services/chat/chat_api_service.dart';
import 'package:idcs/components/cross_compontents/chat/chat_room_components.dart';

class ChatRoomPage extends StatefulWidget {
  final String userId;
  final int roomId;

  const ChatRoomPage({super.key, required this.userId, required this.roomId});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _msgController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final WebSocketService _wsService = WebSocketService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<dynamic> _messages = [];
  List<dynamic> _participants = [];
  bool _isLoadingHistory = true;
  bool _isSearchMode = false; // 채팅 검색 모드 토글

  @override
  void initState() {
    super.initState();
    _initChatRoom();
  }

  Future<void> _initChatRoom() async {
    try {
      // 1. 읽음 처리 먼저
      await ChatApiService.markAsRead(widget.roomId, widget.userId);
      // 2. 참여자 정보 로드 (Drawer 용)
      _participants = await ChatApiService.getParticipants(widget.roomId);
      // 3. 메시지 히스토리 로드
      await _loadMessages();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }

    // 4. 웹소켓 연결
    _wsService.connect('${AppConfig.basewsUrl}/chat/ws/${widget.roomId}/${widget.userId}');
    _wsService.messageStream.listen((data) {
      final decoded = jsonDecode(data);
      if (mounted) {
        setState(() {
          _messages.insert(0, decoded);
        });
        // 새 메시지 수신 시 읽음 처리 API 가볍게 호출 (선택적)
        ChatApiService.markAsRead(widget.roomId, widget.userId);
      }
    });
  }

  Future<void> _loadMessages({String keyword = ""}) async {
    setState(() => _isLoadingHistory = true);
    try {
      final pastMessages = await ChatApiService.getRoomMessages(widget.roomId, widget.userId, keyword: keyword);
      if (mounted) {
        setState(() {
          _messages = pastMessages; // 덮어쓰기
        });
      }
    } catch (e) {
      // 에러 로직
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  @override
  void dispose() {
    _wsService.disconnect();
    _msgController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _wsService.send(jsonEncode({"type": "TEXT", "content": text}));
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: _isSearchMode
            ? TextField(
          controller: _searchController,
          decoration: const InputDecoration(hintText: '메시지 검색...', border: InputBorder.none),
          style: const TextStyle(color: Colors.black),
          onSubmitted: (val) => _loadMessages(keyword: val),
        )
            : const Text('채팅방'),
        actions: [
          IconButton(
            icon: Icon(_isSearchMode ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchMode = !_isSearchMode;
                if (!_isSearchMode) {
                  _searchController.clear();
                  _loadMessages(); // 검색 종료 시 전체 다시 로드
                }
              });
            },
          )
        ],
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(child: Text('참여중인 유저 목록', style: TextStyle(color: Colors.white, fontSize: 18))),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _participants.length,
                itemBuilder: (context, index) {
                  final p = _participants[index];
                  return ListTile(
                    leading: CircleAvatar(child: Icon(p['role'] == 'USER' ? Icons.person : Icons.admin_panel_settings)),
                    title: Text('${p['name']} (${p['role']})'),
                  );
                },
              ),
            ),
            // TODO: (관리자) 그룹 챗 추가 권한 검증은 여기서 is_admin && is_group 등 활용
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () { /* 인원 추가 로직 연동 */ },
                icon: const Icon(Icons.person_add),
                label: const Text('현재 채팅방 인원 추가'),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChatRoomHeaderBox(
            roomName: '채팅방 ${widget.roomId}',
            onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ChatMessageListBox(
              messages: _messages,
              currentUserId: widget.userId,
            ),
          ),
          ChatInputBox(controller: _msgController, onSend: _sendMessage),
          const SafeArea(child: SizedBox.shrink()),
        ],
      ),
    );
  }
}