import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

const TestIp = (kIsWeb) ? "127.0.0.1:8000" : "10.0.2.2:8000";

enum UserRole {
  user,    // 일반 유저 (메신저 접근 가능)
  admin,   // 관리자 (메신저, 게시판 모두 접근 가능)
  guest,   // 비회원
}

// 임시 메시지 데이터 모델
class ChatMessage {
  final String content;
  final int user;
  final String user_name;
  final String type;
  final int? parentmsg;
  final String time;

  ChatMessage({required this.content, required this.user, required this.user_name, required this.type, this.parentmsg, required this.time});
}

class ChatroomScreen extends StatefulWidget {
  final String roomId;
  final String roomTitle;
  final int userId;

  const ChatroomScreen({
    super.key,
    required this.roomId,
    required this.roomTitle,
    required this.userId
  });

  @override
  State<ChatroomScreen> createState() => _ChatroomScreenState();
}

class _ChatroomScreenState extends State<ChatroomScreen> {
  final dio = Dio();
  final TextEditingController _textController = TextEditingController();

  // 임시 채팅 데이터 리스트
  final List<ChatMessage> _messages = [
    /*ChatMessage(text: "안녕하세요!", isMe: false, time: "오후 2:00"),
    ChatMessage(text: "네, 안녕하세요! 무슨 일이신가요?", isMe: true, time: "오후 2:01"),
    ChatMessage(text: "텔레그램 스타일 UI를 만들고 있어요. 어떤가요?", isMe: false, time: "오후 2:02"),
    ChatMessage(text: "우와, 깔끔하고 예쁘네요! 👍", isMe: true, time: "오후 2:03"),*/
  ];

  late WebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    // 2. 화면이 켜질 때 웹소켓 서버에 연결
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://$TestIp/api/ms/chat/${widget.roomId}'),
    );

    _fetchChatHistory();

    // 3. 서버로부터 들어오는 메시지 실시간 리스닝
    _channel.stream.listen((rawData) {
      final decodedData = jsonDecode(rawData);
      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            content: decodedData['content'],
            user: decodedData['user_id'], // 내 메시지인지 판별
            user_name: decodedData['user_name'], // 내 메시지인지 판별
            type: decodedData['message_type'],
            parentmsg: decodedData['parent_message_id'] as int?,
            time: decodedData['created_at']
          ),
        );
      });
    });
  }

  Future<void> _fetchChatHistory() async {
    try {
      final response = await dio.get(
          "http://$TestIp/api/ms/chat/${widget.roomId}/messages"
      );

      if (response.statusCode == 200) {
        final List<dynamic> historyData = response.data;
        setState(() {
          // 과거 데이터를 ChatMessage 객체 리스트로 변환
          final List<ChatMessage> historyMessages = historyData.map((msg) {
            return ChatMessage(
                content: msg['content'],
                user: msg['user_id'] as int,
                user_name: msg['user_name'],
                type: msg['message_type'],
                parentmsg: msg['parent_message_id'] as int?,
                time: msg['created_at']
            );
          }).toList();

          // 💡 ListView.reverse = true 환경이므로,
          // 과거 데이터들을 현재 메시지 리스트 뒤쪽에 통째로 붙여줍니다.
          _messages.addAll(historyMessages);
        });
      }
    } catch (e) {
      print("이전 대화 내역 불러오기 실패: $e");
    }
  }

  // 메시지 전송 함수
  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();

    // 1. 서버에 보낼 데이터 구조 정의 (서버의 프로토콜 사정에 맞추어 구성)
    final messageData = {
      'content': text,                // 메시지 내용
      'user_id': widget.userId,                 // 보낸 사람 식별자
      'msg_type': "TEXT",
      'parent_msg': null
    };

    try {
      // 2. 💡 웹소켓으로 JSON 문자열 전송
      // channel 변수는 클래스 멤버 변수로 선언되어 있다고 가정합니다.
      _channel.sink.add(jsonEncode(messageData));

    } catch (e) {
      print("웹소켓 전송 실패: $e");
      // 필요하다면 전송 실패 안내 등을 UI에 표시
    }
  }

  @override
  void dispose() {
    // 4. 화면을 나갈 때 웹소켓 연결을 반드시 닫아줌
    _channel.sink.close();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0e1621), // 텔레그램 특유의 어두운 배경색
      appBar: AppBar(
        backgroundColor: const Color(0xff17212b), // 앱바 색상
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.roomTitle,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              '온라인',
              style: TextStyle(color: Color(0xff5288c1), fontSize: 13),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // 1. 채팅 메시지 리스트 영역
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              reverse: true, // 최신 메시지가 아래에 쌓이도록 역순 정렬
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          // 2. 하단 입력창 영역
          _buildInputArea(),
        ],
      ),
    );
  }

  // 메시지 말풍선 위젯
  Widget _buildMessageBubble(ChatMessage message) {
    // 내가 보낸 메시지인지 판별
    final bool isMe = message.user == widget.userId;

    return AlignmentContainer(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 💡 상대방이 보낸 메시지일 때만 말풍선 위에 이름을 표시합니다.
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
              child: Text(
                message.user_name,
                style: const TextStyle(
                  color: Color(0xff5288c1), // 텔레그램 특유의 연한 파란색 이름 톤
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // 기존 말풍선 Container
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2.0), // 패딩 조절
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xff2b5278) : const Color(0xff182533),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isMe ? 12 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 12),
              ),
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    message.content,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  message.time,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 하단 텍스트 입력창 위젯
  Widget _buildInputArea() {
    return Container(
      color: const Color(0xff17212b),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.sentiment_satisfied_alt, color: Colors.grey),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '메시지 입력...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              onSubmitted: _handleSubmitted,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xff5288c1)),
            onPressed: () => _handleSubmitted(_textController.text),
          ),
        ],
      ),
    );
  }
}

// ListView 안에서 정렬을 도와주는 간단한 헬퍼 위젯
class AlignmentContainer extends StatelessWidget {
  final Alignment alignment;
  final Widget child;

  const AlignmentContainer({super.key, required this.alignment, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(alignment: alignment, child: child);
  }
}