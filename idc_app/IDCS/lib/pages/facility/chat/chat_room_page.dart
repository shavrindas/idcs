// 경로: lib/pages/facility/chat/chat_room_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:idcs/main.dart';
import 'package:idcs/services/common/web_socket_service.dart';
import 'package:idcs/services/chat/chat_api_service.dart';
import 'package:idcs/components/cross_compontents/chat/chat_room_components.dart';
import 'package:idcs/theme/app_theme.dart';
import '../../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/components/shared/app_toast.dart';

class ChatRoomPage extends StatefulWidget {
  final String userId;
  final int roomId;

  /// 목록에서 넘겨받은 방 이름. 없으면 방 번호로 대신한다.
  final String? roomName;

  const ChatRoomPage({
    super.key,
    required this.userId,
    required this.roomId,
    this.roomName,
  });

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
  Map<String, dynamic>? _replyingTo; // 답장 대상 메시지 저장

  /// 보낸 사람 id -> 이름. 메시지 API 는 user_id 만 주기 때문에, 참여자 목록에서
  /// 맞춰 둬야 'User 11' 대신 사람 이름이 뜬다.
  Map<int, String> _senderNames = {};
  bool _isLoadingHistory = true;
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _initChatRoom();
  }

  Future<void> _initChatRoom() async {
    try {
      await ChatApiService.markAsRead(widget.roomId, widget.userId);
      _participants = await ChatApiService.getParticipants(widget.roomId);
      _senderNames = {
        for (final p in _participants)
          if (p['id'] is int && p['name'] != null) p['id'] as int: p['name'].toString(),
      };
      await _loadMessages();
    } catch (e) {
      if (mounted) AppToast.error(context, describeApiError(context, e));
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }

    _wsService.connect('${AppConfig.basewsUrl}/chat/ws/${widget.roomId}/${widget.userId}');
    _wsService.messageStream.listen((data) {
      final decoded = jsonDecode(data);
      if (mounted) {
        setState(() {
          _messages.insert(0, decoded);
        });
        ChatApiService.markAsRead(widget.roomId, widget.userId);
      }
    });
  }

  Future<void> _loadMessages({String keyword = ""}) async {
    setState(() => _isLoadingHistory = true);
    try {
      final pastMessages = await ChatApiService.getRoomMessages(widget.roomId, widget.userId, keyword: keyword);
      if (mounted) setState(() => _messages = pastMessages);
    } catch (e) {
      // 에러 로직 생략
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

    // 답장 여부에 따라 parent_message_id 포함
    final payload = {
      "type": "TEXT",
      "content": text,
    };
    if (_replyingTo != null) {
      payload["parent_message_id"] = _replyingTo!['message_id'];
    }

    _wsService.send(jsonEncode(payload));
    _msgController.clear();
    setState(() => _replyingTo = null);
  }

  void _handleMessageAction(Map<String, dynamic> msg, String action) async {
    if (action == 'reply') {
      setState(() => _replyingTo = msg);
    } else if (action == 'pin') {
      try {
        await ChatApiService.togglePinMessage(widget.roomId, msg['message_id'], widget.userId);
        _loadMessages(); // 상태 리프레시
      } catch (e) {
        // The await above may have outlived this screen.
        if (!mounted) return;
        AppToast.error(context, describeApiError(context, e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: _isSearchMode
            ? TextField(
          controller: _searchController,
          decoration: InputDecoration(hintText: context.l10n.chatSearchHint, border: InputBorder.none, filled: false),
          style: TextStyle(color: context.colors.textPrimary),
          onSubmitted: (val) => _loadMessages(keyword: val),
        )
            : Text(widget.roomName ?? context.l10n.chatRoomFallback('${widget.roomId}')),
        actions: [
          IconButton(
            tooltip: context.l10n.chatMembers,
            icon: const Icon(Icons.group_outlined),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          IconButton(
            tooltip: context.l10n.actionClose,
            icon: Icon(_isSearchMode ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _isSearchMode = !_isSearchMode;
                if (!_isSearchMode) {
                  _searchController.clear();
                  _loadMessages();
                }
              });
            },
          )
        ],
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: context.colors.primary),
              child: Center(child: Text(context.l10n.chatMembers, style: TextStyle(color: context.colors.onPrimary, fontSize: 18, fontWeight: FontWeight.w700))),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _participants.length,
                itemBuilder: (context, index) {
                  final p = _participants[index];
                  final bool isAdmin = p['role'] != 'USER';
                  final String name = p['name'] ?? '';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isAdmin ? context.colors.primary : context.colors.primary.withValues(alpha: 0.12),
                      child: isAdmin
                          ? Icon(Icons.shield_rounded, color: context.colors.onPrimary, size: 18)
                          : Text(
                              name.isNotEmpty ? name.substring(0, 1) : '?',
                              style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w700),
                            ),
                    ),
                    title: Text('${p['name']} (${p['role']})'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 앱바가 'Chat', 그 아래 상자가 'Chat 5' 라 제목이 두 줄로 겹쳐 있었다.
          // 방 이름을 앱바에 올리고 상자는 걷어냈다 — 대화가 보이는 높이가 늘었다.
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ChatMessageListBox(
              messages: _messages,
              currentUserId: widget.userId,
              senderNames: _senderNames,
              onAction: _handleMessageAction, // 액션 핸들러 연동
            ),
          ),
          ChatInputBox(
            controller: _msgController,
            replyingTo: _replyingTo,
            onSend: _sendMessage,
            onCancelReply: () => setState(() => _replyingTo = null),
          ),
          const SafeArea(child: SizedBox.shrink()),
        ],
      ),
    );
  }
}