import 'package:flutter/material.dart';
import 'package:idcs/components/indices/facility_register/facility_register.dart';
import 'package:idcs/components/indices/global_nav_box.dart';
import 'package:idcs/services/common/user_api_service.dart';
import 'package:idcs/services/common/facility_api_service.dart';

class FacilityRegisterPage extends StatefulWidget {
  final String userId;
  const FacilityRegisterPage({super.key, required this.userId});

  @override
  State<FacilityRegisterPage> createState() => _FacilityRegisterPageState();
}

class _FacilityRegisterPageState extends State<FacilityRegisterPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isAdmin = false;
  bool _isLoading = true;
  String _collapseMessage = '';
  List<dynamic> _facilities = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final role = await UserApiService.getUserRole(widget.userId);
      _isAdmin = (role == 'ADMIN' || role == 'DEVELOPER');

      // ADMIN은 애초에 이 페이지 접근할 필요 없지만 들어왔을 경우 방어
      if (!_isAdmin) {
        _facilities = await FacilityApiService.getFacilities(widget.userId);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    try {
      final msg = await FacilityApiService.registerFacility(widget.userId, code);
      setState(() {
        _collapseMessage = msg;
        _codeController.clear();
      });
      await _loadData(); // 목록 새로고침
    } catch (e) {
      setState(() => _collapseMessage = '등록 실패: $e');
    }
  }

  Future<void> _handleUnlink(int facilityId) async {
    try {
      final msg = await FacilityApiService.unlinkFacility(widget.userId, facilityId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('시설 등록 페이지')),
        body: const Center(child: Text('관리자 및 개발자는 시설 등록이 필요하지 않습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('시설 등록 페이지')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlobalNavigationBox(
              userId: widget.userId, isAdmin: _isAdmin, onStateInitialize: _loadData,
            ),
            const SizedBox(height: 16),
            FacilityInputBox(
              codeController: _codeController, onSubmit: _handleRegister, collapseMessage: _collapseMessage,
            ),
            const SizedBox(height: 16),
            FacilityListEditBox(
              facilities: _facilities, onUnlink: _handleUnlink,
            ),
          ],
        ),
      ),
    );
  }
}