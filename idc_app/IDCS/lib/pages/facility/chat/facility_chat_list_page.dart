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

    final result = await showDialog<({String name, List<int> userIds})>(
      context: context,
      builder: (_) => _CreateGroupDialog(members: members),
    );
    if (result == null || !mounted) return;

    try {
      await ChatApiService.createGroupChat(
        widget.userId,
        result.name,
        result.userIds,
      );
      if (!mounted) return;
      AppToast.success(context, l10n.chatGroupCreated(result.name));
      _fetchRooms();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, describeApiError(context, e));
    }
  }

  void _handleRoomLongPress(int roomId) {
    showModalBottomSheet(
      context: context,
      // 시트가 닫힌 뒤에도 토스트는 띄워야 하므로, 시트의 context 와 화면의
      // context 를 섞지 않는다.
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.exit_to_app, color: sheetContext.colors.error),
              title: Text(sheetContext.l10n.chatLeaveRoom),
              onTap: () async {
                Navigator.pop(sheetContext);
                try {
                  await ChatApiService.leaveOrDeleteRoom(
                    roomId,
                    widget.userId,
                    action: 'delete',
                  );
                  if (!mounted) return;
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
                    // 방 이름은 이 목록이 이미 들고 있다. 상세가 다시 묻지
                    // 않도록 같이 넘긴다.
                    onRoomTapped: (roomId) {
                      final room = _rooms.firstWhere(
                        (r) => r['room_id'] == roomId,
                        orElse: () => const <String, dynamic>{},
                      );
                      context
                          .push(
                            '/chat_room/${widget.userId}/$roomId',
                            extra: room['room_name'],
                          )
                          .then((_) => _fetchRooms());
                    },
                    onRoomLongPressed: _handleRoomLongPress,
                  ),
                ],
              ),
            ),
    );
  }
}

/// 단체방 만들기 창.
///
/// 입력 컨트롤러를 들고 있어야 해서 별도 위젯이다. 호출한 쪽에서 showDialog 가
/// 끝나자마자 dispose 하면, 아직 닫히는 중인 창이 버려진 컨트롤러를 다시 그리려다
/// 터진다. 창 자신이 들고 있다가 자기 dispose 에서 정리하는 게 맞다.
class _CreateGroupDialog extends StatefulWidget {
  final List<Map<String, dynamic>> members;

  const _CreateGroupDialog({required this.members});

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final TextEditingController _nameCtrl = TextEditingController();
  final Set<int> _selected = {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    final name = _nameCtrl.text.trim();

    // 왜 안 되는지 말해 주지 않고 조용히 닫히던 자리다.
    if (name.isEmpty) {
      AppToast.warning(context, l10n.chatGroupNameRequired);
      return;
    }
    if (_selected.isEmpty) {
      AppToast.warning(context, l10n.chatGroupMemberRequired);
      return;
    }

    Navigator.pop(context, (name: name, userIds: _selected.toList()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.chatGroupCreate),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              textInputAction: TextInputAction.done,
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
                if (_selected.isNotEmpty)
                  Text(
                    l10n.chatGroupSelected(_selected.length),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // 인원이 적으면 그만큼만 차지하고, 많아지면 여기서만 스크롤한다.
            // Flexible 로 두면 높이가 정해지지 않은 창 안에서 폭주한다.
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final member in widget.members)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _selected.contains(member['id']),
                      title: Text(
                        (member['name'] ?? '').toString().isEmpty
                            ? l10n.noName
                            : member['name'].toString(),
                      ),
                      subtitle: Text(
                        member['email']?.toString() ?? '',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onChanged: (on) => setState(() {
                        if (on == true) {
                          _selected.add(member['id'] as int);
                        } else {
                          _selected.remove(member['id']);
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
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        ElevatedButton(onPressed: _submit, child: Text(l10n.actionCreate)),
      ],
    );
  }
}
