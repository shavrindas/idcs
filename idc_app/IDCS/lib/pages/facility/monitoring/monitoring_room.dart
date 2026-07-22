import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/common/opening/open_nav.dart';
import 'package:idcs/services/common/facility_api_service.dart';
import 'package:idcs/components/indices/main_index/main_index_components.dart';

class MonitoringRoom extends StatefulWidget {
  final String userId;
  final String facilityId;

  const MonitoringRoom({super.key, required this.userId, required this.facilityId});

  @override
  State<MonitoringRoom> createState() => _MonitoringRoomPage();
}

class _MonitoringRoomPage extends State<MonitoringRoom> {
  bool _isLoading = true;
  List<dynamic> _rooms = [];

  @override
  void initState() {
    super.initState();
    _fetchFacilityData();
  }

  // 1. 유저 데이터(권한 등)를 불러오는 초기화 함수
  Future<void> _fetchFacilityData() async {
    setState(() {
      _isLoading = true; // 로딩 상태 활성화
    });

    try {
      final rooms = await FacilityApiService.getFacilityRooms(widget.facilityId);
      setState(() {
        _rooms = rooms;
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
      appBar: AppBar(title: Text('시설 ID: ${widget.facilityId} 라우팅')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IntegratedFacilityBox(
              facilities: _rooms,
              onFacilityPressed: (roomId) {
                // 터치 시 시설 라우팅용 nav 페이지로 이동
                context.push('/facility_monitoring/${widget.userId}/${widget.facilityId}/$roomId');
              }),
          ],
        ),
      ),
    );
  }
}