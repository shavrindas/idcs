import 'package:flutter/material.dart';
import 'package:idcs/components/indices/facility_register/facility_register.dart';
import 'package:idcs/services/common/user_api_service.dart';
import 'package:idcs/services/common/facility_api_service.dart';
import '../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';

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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeApiError(e))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    // Read before awaiting: context may no longer be valid in the catch.
    final l10n = context.l10n;
    try {
      final msg = await FacilityApiService.registerFacility(widget.userId, code);
      setState(() {
        _collapseMessage = msg;
        _codeController.clear();
      });
      await _loadData(); // 목록 새로고침
    } catch (e) {
      setState(() => _collapseMessage = l10n.facilityRegisterFailed(describeApiError(e)));
    }
  }

  Future<void> _handleUnlink(int facilityId) async {
    try {
      final msg = await FacilityApiService.unlinkFacility(widget.userId, facilityId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeApiError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.facilityRegisterTitle)),
        body: Center(child: Text(context.l10n.facilityRegisterAdminNote)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.facilityRegisterTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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