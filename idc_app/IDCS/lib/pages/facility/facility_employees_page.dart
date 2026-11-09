import 'package:flutter/material.dart';
import 'package:idcs/services/common/facility_api_service.dart';
import 'package:idcs/services/common/user_api_service.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/components/shared/app_toast.dart';
import 'package:idcs/services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';

class FacilityEmployeesPage extends StatefulWidget {
  final String userId;
  final String facilityId;

  const FacilityEmployeesPage({super.key, required this.userId, required this.facilityId});

  @override
  State<FacilityEmployeesPage> createState() => _FacilityEmployeesPageState();
}

class _FacilityEmployeesPageState extends State<FacilityEmployeesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allEmployees = [];
  List<dynamic> _filteredEmployees = [];
  bool _isLoading = true;
  bool _hasAccess = false;
  // 목록 자체를 못 불러왔을 때만 채운다 — 권한 없음과는 다른 상태라 별도로 둔다.
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final userRole = await UserApiService.getUserRole(widget.userId);
      final isSystemAdmin = (userRole == 'ADMIN' || userRole == 'DEVELOPER');

      final employees = await FacilityApiService.getFacilityEmployees(widget.facilityId, widget.userId);

      bool isUserAdmin = false;
      if (!isSystemAdmin) {
        for (var emp in employees) {
          if (emp['id'].toString() == widget.userId && emp['is_user_admin'] == true) {
            isUserAdmin = true;
            break;
          }
        }
      }

      final canAccess = isSystemAdmin || isUserAdmin;

      if (mounted) {
        setState(() {
          _allEmployees = employees;
          _hasAccess = canAccess;
        });
        _applySearch();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadError = describeApiError(context, e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySearch() {
    final query = _searchController.text.trim().toLowerCase();
    var filtered = _allEmployees.where((emp) {
      return emp['name'].toString().toLowerCase().contains(query);
    }).toList();

    // 정렬: 수석 어드민이 최상단, 그다음 이름순 정렬
    filtered.sort((a, b) {
      if (a['is_user_admin'] == true && b['is_user_admin'] != true) return -1;
      if (a['is_user_admin'] != true && b['is_user_admin'] == true) return 1;
      return a['name'].toString().compareTo(b['name'].toString());
    });

    setState(() {
      _filteredEmployees = filtered;
    });
  }

  Future<void> _showInviteDialog() async {
    final TextEditingController codeController = TextEditingController();
    final l10n = context.l10n;

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.employeesInviteDialogTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.employeesInviteDialogBody, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: l10n.employeesUserCodeLabel,
                prefixIcon: const Icon(Icons.qr_code_outlined),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.actionCancel)),
          FilledButton(
            onPressed: () {
              if (codeController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(l10n.employeesInviteConfirm),
          ),
        ],
      ),
    );

    if (result == true) {
      _handleInvite(codeController.text.trim());
    }
  }

  Future<void> _handleInvite(String code) async {
    try {
      final msg = await FacilityApiService.inviteUserByCode(widget.facilityId, widget.userId, code);
      if (!mounted) return;
      AppToast.success(context, msg);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, describeApiError(context, e));
    }
  }

  Future<void> _handleRemove(int targetUserId, String name) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.employeesRemoveDialogTitle),
        content: Text(l10n.employeesRemoveDialogBody(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.actionCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: Text(l10n.employeesRemoveConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FacilityApiService.removeEmployee(widget.facilityId, widget.userId, targetUserId);
      if (!mounted) return;
      AppToast.success(context, l10n.employeesRemovedToast);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, describeApiError(context, e));
    }
  }

  Future<void> _showPermissionsDialog(Map<String, dynamic> emp) async {
    final l10n = context.l10n;
    bool canDevice = emp['can_control_device'] == true;
    bool canBoard = emp['can_manage_board'] == true;
    bool canAlarm = emp['can_manage_alarm'] == true;

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.employeesPermissionsDialogTitle(emp['name'])),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.employeesPermDevice),
                value: canDevice,
                onChanged: (v) => setDialogState(() => canDevice = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.employeesPermBoard),
                value: canBoard,
                onChanged: (v) => setDialogState(() => canBoard = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.employeesPermAlarm),
                value: canAlarm,
                onChanged: (v) => setDialogState(() => canAlarm = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.actionCancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.actionSave)),
          ],
        ),
      ),
    );

    if (saved != true) return;

    try {
      await FacilityApiService.updateEmployeePermissions(
        widget.facilityId,
        widget.userId,
        emp['id'],
        canControlDevice: canDevice,
        canManageBoard: canBoard,
        canManageAlarm: canAlarm,
      );
      if (!mounted) return;
      AppToast.success(context, l10n.employeesPermissionsUpdated);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, describeApiError(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_loadError != null)
              ? _ErrorState(message: _loadError!, onRetry: _loadData)
              : (!_hasAccess)
                  ? Center(
                      child: Text(
                        l10n.employeesAccessDenied,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.4),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80 + MediaQuery.of(context).padding.bottom),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: l10n.employeesSearchHint,
                                    prefixIcon: const Icon(Icons.search_rounded),
                                    isDense: true,
                                    fillColor: colors.surface,
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: colors.outline),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _showInviteDialog,
                                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                                label: Text(l10n.employeesAddButton),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(l10n.employeesListTitle(_filteredEmployees.length),
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary)),
                                Text(l10n.employeesRemoveColumnLabel,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary)),
                              ],
                            ),
                          ),

                          Expanded(
                            child: _filteredEmployees.isEmpty
                                ? Center(
                                    child: Text(
                                      _allEmployees.isEmpty ? l10n.employeesEmptyState : l10n.employeesEmptySearchState,
                                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _filteredEmployees.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final emp = _filteredEmployees[index];
                                      final bool isMe = emp['id'].toString() == widget.userId;
                                      final bool isUserAdmin = emp['is_user_admin'] == true;

                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isUserAdmin ? colors.primary.withValues(alpha: 0.05) : colors.surface,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: isUserAdmin ? colors.primary.withValues(alpha: 0.4) : colors.outline),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          emp['name'],
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      if (isUserAdmin)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration:
                                                              BoxDecoration(color: colors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                                          child: Text(l10n.employeesChiefAdminBadge,
                                                              style: TextStyle(fontSize: 10, color: colors.primary, fontWeight: FontWeight.w600)),
                                                        ),
                                                      if (isMe)
                                                        Container(
                                                          margin: const EdgeInsets.only(left: 6),
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                              color: colors.textSecondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                                          child: Text(l10n.employeesMeBadge,
                                                              style: TextStyle(fontSize: 10, color: colors.textSecondary, fontWeight: FontWeight.w600)),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(l10n.employeesIdEmailLabel(emp['id'].toString(), emp['email']),
                                                      style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.tune_rounded, size: 20),
                                              color: colors.textSecondary,
                                              tooltip: l10n.employeesPermissionsTooltip,
                                              onPressed: () => _showPermissionsDialog(emp),
                                            ),
                                            if (!isUserAdmin)
                                              IconButton(
                                                icon: const Icon(Icons.close_rounded, size: 20),
                                                color: colors.error,
                                                tooltip: l10n.employeesRemoveTooltip,
                                                onPressed: () => _handleRemove(emp['id'], emp['name']),
                                              )
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.error, size: 32),
            const SizedBox(height: 12),
            Text(
              '${l10n.employeesLoadFailed}\n$message',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.actionRetry),
            ),
          ],
        ),
      ),
    );
  }
}
