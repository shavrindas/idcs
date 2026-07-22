// 경로: lib/pages/facility/chat/chat_room_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:idcs/main.dart'; // AppConfig
import 'package:idcs/services/common/web_socket_service.dart';
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
  final List<dynamic> _messages = []; // 최신 메시지가 0번 인덱스

  @override
  void initState() {
    super.initState();
    // 1. 웹소켓 연결
    _wsService.connect('${AppConfig.basewsUrl}/chat/ws/${widget.roomId}/${widget.userId}');
    
    // 2. 수신 리스너 등록
    _wsService.messageStream.listen((data) {
      final decoded = jsonDecode(data);
      setState(() {
        _messages.insert(0, decoded); // ListView.reverse를 위해 0번에 삽입
      });
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

    // TODO: WebSocketService 내부에 send 기능 추가 필요 (아래는 임시 전송 구현)
    // _wsService.send(jsonEncode({"content": text}));
    
    // 임시 UI 반영 (서버 통신 전)
    setState(() {
      _messages.insert(0, {
        "user_id": widget.userId,
        "content": text,
        "created_at": "Just now"
      });
    });
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('채팅방')), // 실제로는 빈 AppBar 두고 Box#1 사용
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Box #1: 헤더
          ChatRoomHeaderBox(
            roomName: '채팅방 ${widget.roomId}',
            onMenuPressed: () {
              // TODO: 참여자 목록 팝업 및 권한에 따른 인원 추가 모달 열기
            },
          ),
          
          // Box #2: 메시지 리스트 (남은 공간 모두 차지)
          Expanded(
            child: ChatMessageListBox(
              messages: _messages,
              currentUserId: widget.userId,
            ),
          ),
          
          // Box #3: 입력창
          ChatInputBox(
            controller: _msgController,
            onSend: _sendMessage,
            onAttach: () { /* 파일 첨부 */ },
          ),
          // iOS 안전 영역 대응
          const SafeArea(child: SizedBox.shrink()), 
        ],
      ),
    );
  }
}