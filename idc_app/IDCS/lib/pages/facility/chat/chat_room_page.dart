// 경로: lib/pages/facility/chat/chat_room_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:idcs/main.dart';
import 'package:idcs/services/common/web_socket_service.dart';
import 'package:idcs/services/chat/chat_api_service.dart'; // 추가된 채팅 서비스
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
  final WebSocketService _wsService = WebSocketService();
  final List<dynamic> _messages = [];

  bool _isLoadingHistory = true; // 과거 기록 로딩 상태
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initChatRoom();
  }

  Future<void> _initChatRoom() async {
    // 1. 과거 메시지 기록 먼저 불러오기
    try {
      final pastMessages = await ChatApiService.getRoomMessages(widget.roomId, widget.userId);
      if (mounted) {
        setState(() {
          _messages.addAll(pastMessages);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }

    // 2. 실시간 웹소켓 연결
    _wsService.connect('${AppConfig.basewsUrl}/chat/ws/${widget.roomId}/${widget.userId}');
    _wsService.messageStream.listen((data) {
      final decoded = jsonDecode(data);
      if (mounted) {
        setState(() {
          // 새로 수신된 실시간 메시지는 화면의 가장 아래(인덱스 0)에 삽입
          _messages.insert(0, decoded);
        });
      }
    });
  }

  @override
  void dispose() {
    _wsService.disconnect();
    _msgController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    // 실제 서버로 전송 (로컬 UI 사전 삽입 코드 제거됨)
    _wsService.send(jsonEncode({
      "type": "TEXT",
      "content": text
    }));

    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: const Text('채팅방'), automaticallyImplyLeading: true),
      endDrawer: Drawer(
        // ... 기존 Drawer 코드 생략 ...
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChatRoomHeaderBox(
            roomName: '채팅방 ${widget.roomId}',
            onMenuPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),

          Expanded(
            // 로딩 중일 땐 인디케이터 표시
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ChatMessageListBox(
              messages: _messages,
              currentUserId: widget.userId,
            ),
          ),

          ChatInputBox(
            controller: _msgController,
            onSend: _sendMessage,
          ),
          const SafeArea(child: SizedBox.shrink()),
        ],
      ),
    );
  }
}