import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:idcs/chatroom.dart';
import 'dart:async';

const TestIp = (kIsWeb) ? "127.0.0.1:8000" : "10.0.2.2:8000";

enum UserRole {
  user,
  admin,
  guest,
}

const UserRole currentLoggedInUserRole = (kIsWeb) ? UserRole.admin : UserRole.user;
const String currentUserId = (kIsWeb) ? "관리자1" : "a";

class MessengerScreen extends StatefulWidget {
  const MessengerScreen({super.key});

  @override
  State<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends State<MessengerScreen> {
  final dio = Dio();

  bool _isLoading = true;
  List<Map<String, String>> chatRooms = [];
  Timer? _pollingTimer;

  late int userId;

  // 💡 [임시 데이터] 초대를 위한 가상의 전체 유저 목록 데이터
  List<Map<String, dynamic>> _dummyUsers = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getuserId();
    await _fetchChatRooms();

    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchChatRooms();
    });
  }

  Future<void> _getuserId() async {
    try {
      setState(() { _isLoading = true; });
      final response = await dio.post(
        "http://$TestIp/userid",
        data: {"user_name": currentUserId},
      );
      if (response.statusCode == 200) {
        setState(() { userId = response.data; });
      }
    } catch (e) {
      print("아이디 불러오기 실패: $e");
    }
  }

  Future<void> _fetchChatRooms() async {
    try {
      final response = await dio.post(
        "http://$TestIp/api/ms/chat/list/",
        data: {"user": userId},
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedRooms = response.data;
        setState(() {
          chatRooms = fetchedRooms.map((room) => {
            "id": room['room_id'].toString(),
            "title": room['room_name'].toString(),
            "lastMessage": "최근 메시지가 없습니다.",
          }).toList();
        });
      }
    } catch (e) {
      print("채팅방 목록 로딩 실패: $e");
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _get_invitable_users() async {
    try {
      final response = await dio.get(
        "http://$TestIp/users"
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedRooms = response.data;
        setState(() {
          _dummyUsers = fetchedRooms.map((user) => {
            "id": int.parse(user['id'].toString()),
            "name": user['name'].toString()
          }).toList();
        });
      }
    } catch (e) {
      print("채팅방 목록 로딩 실패: $e");
    }
  }

  Future<void> _invite_users(String roomId, Set<int> selectedUserId) async {
    try {
      final response = await dio.post(
        "http://$TestIp/api/ms/chat/userinv/",
        data: {"room_id": roomId,
          "users_id": selectedUserId.toList()},
      );
    } catch (e) {
      print("채팅방 목록 로딩 실패: $e");
    }
  }

  // 💡 ✨ 추가: 특정 채팅방에 유저를 추가하기 위한 체크박스 팝업창 함수
  void _showInviteUserDialog(String roomId, String roomTitle) async {
    // 선택된 유저들의 ID를 임시로 저장할 셋(Set) 자료구조
    final Set<int> selectedUserId = {};

    await _get_invitable_users();

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder를 사용하여 다이얼로그 내부에서 체크박스 토글 시 화면이 실시간 갱신되도록 함
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('$roomTitle에 유저 초대', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SizedBox(
                width: double.maxFinite,
                height: 250, // 대화상자 높이 제한
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _dummyUsers.length,
                  itemBuilder: (context, index) {
                    final user = _dummyUsers[index];
                    final bool isChecked = selectedUserId.contains(user['id']);

                    return CheckboxListTile(
                      title: Text(user['name']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(''),
                      value: isChecked,
                      activeColor: Colors.blueAccent,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedUserId.add(user['id'] as int);
                          } else {
                            selectedUserId.remove(user['id'] as int);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedUserId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('초대할 유저를 선택해주세요.')),
                      );
                      return;
                    }

                    // TODO: 백엔드 참여 API 연결부 (참고용 구조)
                    _invite_users(roomId, selectedUserId);

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${selectedUserId.length}명의 유저가 초대되었습니다.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: const Text('초대 완료', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  final TextEditingController _roomTitleController = TextEditingController();

  void _enterRoom(String roomId, String roomTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatroomScreen(userId: userId, roomId: roomId, roomTitle: roomTitle),
      ),
    );
  }

  void _showCreateRoomDialog() {
    _roomTitleController.clear(); // 이전에 입력했던 텍스트 초기화

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('새 채팅방 만들기', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _roomTitleController,
            decoration: const InputDecoration(
              hintText: '채팅방 이름을 입력하세요',
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
            ),
            autofocus: true, // 창이 열리자마자 키보드가 올라오도록 설정
          ),
          actions: [
            // 취소 버튼
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            // 확인 버튼
            ElevatedButton(
              // 1. 비동기 처리를 위해 함수 앞에 async 추가
              onPressed: () async {
                final text = _roomTitleController.text.trim();
                if (text.isNotEmpty) {
                  try {
                    // [선택 사항] 통신 도중 여러 번 클릭 방지하기 위해 다이얼로그를 먼저 닫거나 인디케이터를 보여주면 좋습니다.

                    // 2. 백엔드 FastAPI 서버에 POST 요청 전송
                    // (안드로이드 에뮬레이터 기준 주소: 10.0.2.2)
                    final response = await dio.post(
                      "http://$TestIp/api/ms/chat/add/",
                      data: {
                        "user": userId,
                        "room_name": text,
                        "type": "GROUP"
                      },
                    );

                    // 3. 서버가 성공 응답(200 또는 201)을 보냈을 때만 로컬 UI 리스트 업데이트
                    if (response.statusCode == 200 || response.statusCode == 201) {
                      // 만약 서버에서 고유 ID를 리턴해 준다면 response.data['id']를 활용하면 됩니다.
                      final serverRoomId = response.data['id']?.toString() ?? "room_${DateTime.now().millisecondsSinceEpoch}";

                      print(serverRoomId);
                      setState(() {
                        chatRooms.add({
                          "id": serverRoomId,
                          "title": text,
                          "lastMessage": "최근 메시지가 없습니다.",
                        });
                      });

                      // 4. 성공 시에만 팝업창 닫기
                      if (context.mounted) Navigator.pop(context);
                    }
                  } catch (e) {
                    // 5. 에러 발생 시 처리 (예: 서버가 꺼져있을 때)
                    print("채팅방 생성 실패: $e");

                    // 스낵바 등을 띄워 사용자에게 알림
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('서버와 통신 중 오류가 발생했습니다.')),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text('확인', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _roomTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅방 목록'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: chatRooms.isEmpty
          ? const Center(child: Text('개설된 채팅방이 없습니다.'))
          : ListView.builder(
        itemCount: chatRooms.length,
        itemBuilder: (context, index) {
          final room = chatRooms[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueAccent.withAlpha(30),
                child: const Icon(Icons.chat, color: Colors.blueAccent),
              ),
              title: Text(
                room["title"]!,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                room["lastMessage"]!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              // 💡 ✨ 수정: 단순 화살표에서 유저 추가 팝업을 선택할 수 있는PopupMenuButton으로 변경
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'invite') {
                    _showInviteUserDialog(room["id"]!, room["title"]!);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'invite',
                    child: Row(
                      children: [
                        Icon(Icons.person_add, color: Colors.blueAccent, size: 20),
                        SizedBox(width: 8),
                        Text('유저 초대하기'),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () => _enterRoom(room["id"]!, room["title"]!),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRoomDialog,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}