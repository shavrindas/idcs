import 'package:flutter/material.dart';
import 'package:idcs/components/indices/global_nav_box.dart';
import 'package:idcs/services/common/user_api_service.dart';

class SettingsPage extends StatefulWidget {
  final String userId;
  const SettingsPage({super.key, required this.userId});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
    } catch (e) {
      // 에러 처리 생략
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정 페이지')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: GlobalNavigationBox(
          userId: widget.userId,
          isAdmin: _isAdmin,
          onStateInitialize: () {}, // 설정 페이지 자체 초기화 로직 (필요시 구현)
        ),
      ),
    );
  }
}