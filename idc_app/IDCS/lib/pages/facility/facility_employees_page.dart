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
    final colors = context.colors;

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: _DialogHeader(icon: Icons.person_add_alt_1_rounded, title: l10n.employeesInviteDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.employeesInviteDialogBody, style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4)),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.employeesUserCodeLabel,
                prefixIcon: const Icon(Icons.qr_code_rounded),
                isDense: true,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.actionCancel)),
          FilledButton.icon(
            onPressed: () {
              if (codeController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(l10n.employeesInviteConfirm),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: _DialogHeader(icon: Icons.person_remove_rounded, title: l10n.employeesRemoveDialogTitle, tone: _DialogTone.danger),
        content: Text(l10n.employeesRemoveDialogBody(name)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.actionCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: context.colors.error),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: _DialogHeader(icon: Icons.admin_panel_settings_rounded, title: l10n.employeesPermissionsDialogTitle(emp['name'])),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PermissionSwitchRow(
                icon: Icons.settings_remote_rounded,
                label: l10n.employeesPermDevice,
                value: canDevice,
                onChanged: (v) => setDialogState(() => canDevice = v),
              ),
              _PermissionSwitchRow(
                icon: Icons.dashboard_customize_rounded,
                label: l10n.employeesPermBoard,
                value: canBoard,
                onChanged: (v) => setDialogState(() => canBoard = v),
              ),
              _PermissionSwitchRow(
                icon: Icons.notifications_active_rounded,
                label: l10n.employeesPermAlarm,
                value: canAlarm,
                onChanged: (v) => setDialogState(() => canAlarm = v),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.actionCancel)),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(l10n.actionSave),
            ),
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
                  ? _AccessDeniedState(message: l10n.employeesAccessDenied)
                  : Padding(
                      padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80 + MediaQuery.of(context).padding.bottom),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 헤더: 아이콘 + 인원 수 요약. 탭에 처음 들어왔을 때
                          // '여기가 어떤 화면인지'가 글자 크기만으로도 읽혀야 한다.
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.groups_rounded, color: colors.primary, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.employeesListTitle(_allEmployees.length),
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary, letterSpacing: -0.2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

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
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: colors.outline),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: colors.outline),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              FilledButton.icon(
                                onPressed: _showInviteDialog,
                                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                                label: Text(l10n.employeesAddButton),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          Expanded(
                            child: _filteredEmployees.isEmpty
                                ? _EmptyState(
                                    message: _allEmployees.isEmpty ? l10n.employeesEmptyState : l10n.employeesEmptySearchState,
                                  )
                                : ListView.separated(
                                    itemCount: _filteredEmployees.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final emp = _filteredEmployees[index];
                                      final bool isMe = emp['id'].toString() == widget.userId;
                                      final bool isUserAdmin = emp['is_user_admin'] == true;

                                      return _EmployeeCard(
                                        emp: emp,
                                        isMe: isMe,
                                        isUserAdmin: isUserAdmin,
                                        onPermissions: () => _showPermissionsDialog(emp),
                                        onRemove: isUserAdmin ? null : () => _handleRemove(emp['id'], emp['name']),
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

enum _DialogTone { normal, danger }

/// Dialog's own icon + title row. The default `AlertDialog.title` is plain
/// text; giving each confirm/edit dialog the same small icon badge makes the
/// dialogs read as one family instead of ad-hoc popups.
class _DialogHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final _DialogTone tone;

  const _DialogHeader({required this.icon, required this.title, this.tone = _DialogTone.normal});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = tone == _DialogTone.danger ? colors.error : colors.primary;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: accent, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _PermissionSwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PermissionSwitchRow({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: value ? colors.primary.withValues(alpha: 0.12) : colors.outline.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: value ? colors.primary : colors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// One row card for an employee. Carries its own avatar/initial, name,
/// role badges and the permission/remove actions.
class _EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> emp;
  final bool isMe;
  final bool isUserAdmin;
  final VoidCallback onPermissions;
  final VoidCallback? onRemove;

  const _EmployeeCard({
    required this.emp,
    required this.isMe,
    required this.isUserAdmin,
    required this.onPermissions,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final String name = emp['name'].toString();
    final String initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: colors.cardShadow,
        border: isUserAdmin ? Border.all(color: colors.primary.withValues(alpha: 0.35)) : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: isUserAdmin ? colors.primary.withValues(alpha: 0.15) : colors.outline.withValues(alpha: 0.3),
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isUserAdmin ? colors.primary : colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isUserAdmin)
                      _Badge(
                        label: l10n.employeesChiefAdminBadge,
                        icon: Icons.workspace_premium_rounded,
                        color: colors.primary,
                      ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      _Badge(label: l10n.employeesMeBadge, color: colors.textSecondary),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.employeesIdEmailLabel(emp['id'].toString(), emp['email']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 20),
            color: colors.textSecondary,
            tooltip: l10n.employeesPermissionsTooltip,
            onPressed: onPermissions,
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              color: colors.error,
              tooltip: l10n.employeesRemoveTooltip,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(label, style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.outline.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(Icons.group_off_rounded, color: colors.textSecondary, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 13.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessDeniedState extends StatelessWidget {
  final String message;

  const _AccessDeniedState({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, color: colors.textSecondary, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.4),
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
