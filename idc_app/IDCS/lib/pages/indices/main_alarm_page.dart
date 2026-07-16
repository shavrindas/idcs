import 'package:flutter/material.dart';
import 'package:idcs/components/indices/global_nav_box.dart';
import 'package:idcs/services/common/user_api_service.dart';

class MainAlarmPage extends StatefulWidget {
  final String userId;
  const MainAlarmPage({super.key, required this.userId});

  @override
  State<MainAlarmPage> createState() => _MainAlarmPageState();
}

class _MainAlarmPageState extends State<MainAlarmPage> {
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final role = await UserApiService.getUserRole(widget.userId);
      if (mounted) setState(() => _isAdmin = (role == 'ADMIN' || role == 'DEVELOPER'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('메인 알람 페이지')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Box #1: 네비게이션
            GlobalNavigationBox(
              userId: widget.userId,
              isAdmin: _isAdmin,
              onStateInitialize: _loadRole,
            ),
            const SizedBox(height: 16),

            // Box #2: 통합 알람 빈 박스
            Container(
              height: 300,
              decoration: BoxDecoration(border: Border.all(color: Colors.redAccent)),
              alignment: Alignment.center,
              child: const Text('통합 알람 박스\n(추후 구현 예정)', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            )
          ],
        ),
      ),
    );
  }
}