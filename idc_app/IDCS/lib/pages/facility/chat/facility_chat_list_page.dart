// 경로: lib/pages/facility/chat/facility_chat_list_page.dart
import 'package:flutter/material.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/cross_compontents/chat/chat_list_components.dart';
import 'package:idcs/services/chat/chat_api_service.dart';
import '../../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/components/shared/app_toast.dart';

class FacilityChatListPage extends StatefulWidget {
  final String userId;
  final String facilityId;

  const FacilityChatListPage({
    super.key,
    required this.userId,
    required this.facilityId,
  });

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
      final res = await ChatApiService.getChatRooms(
        int.parse(widget.facilityId),
        widget.userId,
      );
      if (mounted) {
        setState(() {
          _isAdmin = res['is_admin'];
          _rooms = res['rooms'];
        });
      }
    } catch (e) {
      if (mounted) AppToast.error(context, describeApiError(context, e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 단체방 만들기.
  ///
  /// 예전에는 방 이름과 함께 "참여자 ID"를 쉼표로 직접 적게 했다. 현장에서
  /// 남의 사용자 ID 번호를 아는 사람은 없고, 비워 두거나 잘못 적으면 버튼이
  /// 아무 반응 없이 닫히기만 했다. 이제 시설에 등록된 사람을 목록에서 고른다.
  Future<void> _showCreateGroupDialog() async {
    final l10n = context.l10n;

    List<Map<String, dynamic>> members;
    try {
      members = await ChatApiService.getFacilityMembers(
        int.parse(widget.facilityId),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        l10n.chatMembersLoadFailed(describeApiError(context, e)),
      );
      return;
    }

    // 자기 자신은 어차피 방에 들어가므로 고를 대상이 아니다.
    final me = int.tryParse(widget.userId);
    members = members.where((m) => m['id'] != me).toList();

    if (!mounted) return;
    if (members.isEmpty) {
      AppToast.info(context, l10n.chatGroupNoMembers);
      return;
    }

    final nameCtrl = TextEditingController();
    final selected = <int>{};

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.chatGroupCreate),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(labelText: l10n.chatRoomName),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.chatGroupPickMembers,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    if (selected.isNotEmpty)
                      Text(
                        l10n.chatGroupSelected(selected.length),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // 시설 인원이 많아질 수 있어 목록만 스크롤한다.
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final member in members)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: selected.contains(member['id']),
                          title: Text(
                            (member['name'] ?? '').toString().isEmpty
                                ? l10n.noName
                                : member['name'].toString(),
                          ),
                          subtitle: Text(
                            member['email']?.toString() ?? '',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onChanged: (on) => setDialogState(() {
                            if (on == true) {
                              selected.add(member['id'] as int);
                            } else {
                              selected.remove(member['id']);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.actionCancel),
            ),
            ElevatedButton(
              // 왜 안 되는지 말해 주지 않고 조용히 닫히던 자리다.
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  AppToast.warning(dialogContext, l10n.chatGroupNameRequired);
                  return;
                }
                if (selected.isEmpty) {
                  AppToast.warning(dialogContext, l10n.chatGroupMemberRequired);
                  return;
                }

                Navigator.pop(dialogContext);
                try {
                  await ChatApiService.createGroupChat(
                    widget.userId,
                    name,
                    selected.toList(),
                  );
                  if (!mounted) return;
                  AppToast.success(context, l10n.chatGroupCreated(name));
                  _fetchRooms();
                } catch (e) {
                  if (!mounted) return;
                  AppToast.error(context, describeApiError(context, e));
                }
              },
              child: Text(l10n.actionCreate),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
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
                  await ChatApiService.leaveOrDeleteRoom(
                    roomId,
                    widget.userId,
                    action: 'delete',
                  );
                  _fetchRooms();
                } catch (e) {
                  // The await above may have outlived this screen.
                  if (!mounted) return;
                  AppToast.error(context, describeApiError(context, e));
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
                    onRoomTapped: (roomId) => context
                        .push('/chat_room/${widget.userId}/$roomId')
                        .then((_) => _fetchRooms()),
                    onRoomLongPressed: _handleRoomLongPress,
                  ),
                ],
              ),
            ),
    );
  }
}
