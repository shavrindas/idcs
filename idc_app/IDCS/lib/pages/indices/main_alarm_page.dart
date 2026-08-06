import 'package:flutter/material.dart';
import 'package:idcs/components/indices/global_nav_box.dart';
import 'package:idcs/services/common/user_api_service.dart';
import 'package:idcs/components/indices/main_alarm/user_alarm_components.dart';
import 'package:idcs/services/common/alarm/alarm_api_service.dart';

class MainAlarmPage extends StatefulWidget {
  final String userId;
  const MainAlarmPage({super.key, required this.userId});

  @override
  State<MainAlarmPage> createState() => _MainAlarmPageState();
}

class _MainAlarmPageState extends State<MainAlarmPage> {
  bool _isAdmin = false;
  bool _isLoading = true;
  List<dynamic> _alarms = [];

  // 💡 검색을 위한 컨트롤러 및 필터 상태 관리 변수
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRole();
    _fetchUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 유저 데이터(권한 등)를 불러오는 초기화 함수
  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final alarms = await AlarmApiService.getUserAlarms(widget.userId);
      setState(() {
        _alarms = alarms;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('권한 조회 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRole() async {
    try {
      final role = await UserApiService.getUserRole(widget.userId);
      if (mounted) {
        setState(() {
          _isAdmin = (role == 'ADMIN' || role == 'DEVELOPER');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void onPressed(int facilityId) {
    // TODO: 시설 눌렀을 때 페이지 이동 등의 로직 작성
    print('선택된 시설 ID: $facilityId');
  }

  @override
  Widget build(BuildContext context) {
    // 💡 검색어 기반 알람 필터링
    final filteredAlarms = _alarms.where((alarm) {
      final name = (alarm['alarm_name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('메인 알람 페이지')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Box #1: 글로벌 네비게이션
            GlobalNavigationBox(
              userId: widget.userId,
              isAdmin: _isAdmin,
              onStateInitialize: _loadRole,
            ),
            const SizedBox(height: 16),

            // 💡 Page 내부에 위치한 검색창
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '알람 이름으로 검색...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Box #2: 통합 알람 박스 (필터링된 결과 전달)
            UserAlarmBox(
              alarms: filteredAlarms,
              onFacilityPressed: onPressed,
              isSearching: _searchQuery.isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }
}