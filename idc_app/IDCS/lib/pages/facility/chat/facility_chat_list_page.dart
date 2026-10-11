// 경로: lib/pages/facility/chat/facility_chat_list_page.dart
import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/cross_compontents/chat/chat_list_components.dart';
import 'package:idcs/services/chat/chat_api_service.dart';
import '../../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';

class FacilityChatListPage extends StatefulWidget {
  final String userId;
  final String facilityId;

  const FacilityChatListPage({super.key, required this.userId, required this.facilityId});

  @override
  State<FacilityChatListPage> createState() => _FacilityChatListPageState();
}

class _FacilityChatListPageState extends State<FacilityChatListPage> {
  bool _isAdmin = false;
  bool _isLoading = true;
  List<dynamic> _rooms = [];

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    setState(() => _isLoading = true);
    try {
      final res = await ChatApiService.getChatRooms(int.parse(widget.facilityId), widget.userId);
      if (mounted) {
        setState(() {
          _isAdmin = res['is_admin'];
          _rooms = res['rooms'];
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeApiError(e))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateGroupDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController usersCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.chatGroupCreate),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: context.l10n.chatRoomName)),
            TextField(controller: usersCtrl, decoration: InputDecoration(labelText: context.l10n.chatInviteUsers)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.actionCancel)),
          ElevatedButton(
            onPressed: () async {
              final ids = usersCtrl.text.split(',').map((e) => int.tryParse(e.trim())).whereType<int>().toList();
              if (nameCtrl.text.isNotEmpty && ids.isNotEmpty) {
                Navigator.pop(context);
                await ChatApiService.createGroupChat(widget.userId, nameCtrl.text, ids);
                _fetchRooms();
              }
            },
            child: Text(context.l10n.actionCreate),
          ),
        ],
      ),
    );
  }

  void _handleRoomLongPress(int roomId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.exit_to_app, color: context.colors.error),
              title: Text(context.l10n.chatLeaveRoom),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await ChatApiService.leaveOrDeleteRoom(roomId, widget.userId, action: 'delete');
                  _fetchRooms();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeApiError(e))));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navMessenger)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isAdmin) ...[
              ChatRoomControlBox(onCreateGroup: _showCreateGroupDialog),
              const SizedBox(height: 16),
            ],
            ChatRoomListBox(
              rooms: _rooms,
              onRoomTapped: (roomId) => context.push('/chat_room/${widget.userId}/$roomId').then((_) => _fetchRooms()),
              onRoomLongPressed: _handleRoomLongPress,
            ),
          ],
        ),
      ),
    );
  }
}