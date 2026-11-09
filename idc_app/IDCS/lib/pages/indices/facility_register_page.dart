import 'package:flutter/material.dart';
import 'package:idcs/components/indices/facility_register/facility_register.dart';
import 'package:idcs/services/common/user_api_service.dart';
import 'package:idcs/services/common/facility_api_service.dart';
import '../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/components/shared/app_toast.dart';

class FacilityRegisterPage extends StatefulWidget {
  final String userId;
  const FacilityRegisterPage({super.key, required this.userId});

  @override
  State<FacilityRegisterPage> createState() => _FacilityRegisterPageState();
}

class _FacilityRegisterPageState extends State<FacilityRegisterPage> {
  bool _isAdmin = false;
  bool _isLoading = true;
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
      if (mounted) AppToast.error(context, describeApiError(context, e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUnlink(int facilityId) async {
    try {
      await FacilityApiService.unlinkFacility(widget.userId, facilityId);
      // The await above may have outlived this screen.
      if (!mounted) return;
      AppToast.success(context, context.l10n.facilityUnlinkDone);
      await _loadData();
    } catch (e) {
      // The await above may have outlived this screen.
      if (!mounted) return;
      AppToast.error(context, describeApiError(context, e));
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
      appBar: AppBar(title: Text(context.l10n.facilitiesTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FacilityListEditBox(
              facilities: _facilities, onUnlink: _handleUnlink,
            ),
          ],
        ),
      ),
    );
  }
}