import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/indices/main_index/main_index_components.dart';
import 'package:idcs/services/common/facility_api_service.dart';
import 'package:idcs/services/common/user_api_service.dart';

class MainIndexPage extends StatefulWidget {
  final String userId;

  const MainIndexPage({super.key, required this.userId});

  @override
  State<MainIndexPage> createState() => _MainIndexPageState();
}

class _MainIndexPageState extends State<MainIndexPage> {
  bool _isAdmin = false;
  bool _isLoading = true;
  List<dynamic> _facilities = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // 1. 유저 데이터(권한 등)를 불러오는 초기화 함수
  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true; // 로딩 상태 활성화
    });

    try {
      final role = await UserApiService.getUserRole(widget.userId);
      final facilities = await FacilityApiService.getFacilities(widget.userId);
      setState(() {
        // ADMIN이거나 DEVELOPER인 경우 관리자 박스 노출
        _isAdmin = (role == 'ADMIN' || role == 'DEVELOPER');
        _facilities = facilities;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('권한 조회 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // 로딩 상태 해제
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 시설'),
        actions: [
          // 관리자는 웹 콘솔에서 시설을 관리하므로, 코드 등록은 일반 유저에게만 노출
          if (!_isAdmin)
            IconButton(
              icon: const Icon(Icons.add_business_outlined),
              tooltip: '시설 등록',
              onPressed: () => context.push('/facility_register/${widget.userId}'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // 데이터 로딩 중 처리
          : RefreshIndicator(
              onRefresh: _fetchUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: IntegratedFacilityBox(
                  facilities: _facilities,
                  onFacilityPressed: (facilityId) {
                    // 터치 시 시설 라우팅용 nav 페이지로 이동
                    context.push('/facility/${widget.userId}/$facilityId/monitoring');
                  },
                ),
              ),
            ),
    );
  }
}