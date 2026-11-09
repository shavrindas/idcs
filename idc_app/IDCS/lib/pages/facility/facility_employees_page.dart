import 'package:flutter/material.dart';
import 'package:idcs/services/common/facility_api_service.dart';
import 'package:idcs/services/common/user_api_service.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/components/shared/app_toast.dart';
import 'package:idcs/services/common/api_client.dart';

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
    setState(() => _isLoading = true);
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
      if (mounted) AppToast.error(context, "직원 목록을 불러오지 못했습니다. 상세: ${describeApiError(context, e)}");
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
    
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("직원 초대", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("초대할 직원의 유저 코드를 입력하세요.", style: TextStyle(fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: "유저 코드",
                prefixIcon: Icon(Icons.qr_code_outlined),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          FilledButton(
            onPressed: () {
              if (codeController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text("초대"),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("직원 해제"),
        content: Text("'$name' 직원을 시설에서 해제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: const Text("해제"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FacilityApiService.removeEmployee(widget.facilityId, widget.userId, targetUserId);
      if (!mounted) return;
      AppToast.success(context, "직원이 시설에서 해제되었습니다.");
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, describeApiError(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (!_hasAccess)
              ? Center(
                  child: Text(
                    "접근 권한이 없습니다.\n(관리자 및 시설 수석 어드민 전용)",
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
                                hintText: "직원 이름 검색...",
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
                            label: const Text("추가"),
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
                            Text("시설 직원 (${_filteredEmployees.length})", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary)),
                            Text("해제", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary)),
                          ],
                        ),
                      ),

                      Expanded(
                        child: ListView.separated(
                          itemCount: _filteredEmployees.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                                                decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                                child: Text("수석 어드민", style: TextStyle(fontSize: 10, color: colors.primary, fontWeight: FontWeight.w600)),
                                              ),
                                            if (isMe)
                                              Container(
                                                margin: const EdgeInsets.only(left: 6),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: colors.textSecondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                                child: Text("나", style: TextStyle(fontSize: 10, color: colors.textSecondary, fontWeight: FontWeight.w600)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text("ID: ${emp['id']} · ${emp['email']}", style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  if (!isUserAdmin)
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 20),
                                      color: colors.error,
                                      tooltip: "직원 해제",
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