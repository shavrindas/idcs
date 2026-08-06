import 'package:flutter/material.dart';
import 'package:idcs/components/indices/main_alarm/facility_alarm_components.dart';
import 'package:idcs/services/common/alarm/alarm_api_service.dart';

class FacilityAlarmPage extends StatefulWidget {
  final String userId;
  final String facilityId;

  const FacilityAlarmPage({
    super.key,
    required this.userId,
    required this.facilityId,
  });

  @override
  State<FacilityAlarmPage> createState() => _FacilityAlarmPageState();
}

class _FacilityAlarmPageState extends State<FacilityAlarmPage> {
  bool _isLoading = true;
  List<dynamic> _alarms = [];

  // 💡 검색을 위한 컨트롤러 및 변수 선언
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final alarms = await AlarmApiService.getFacilitiesAlarms(widget.facilityId);
      setState(() {
        _alarms = alarms;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('권한 조회 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 검색어로 필터링된 알람 목록 생성
    final filteredAlarms = _alarms.where((alarm) {
      final name = (alarm['alarm_name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('시설 ID: ${widget.facilityId} 알람 페이지')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 💡 Page 내부에 들어간 검색창
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '알람 이름으로 검색...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // 2. 필터링된 알람 데이터 전달
            FacilityAlarmBox(
              alarms: filteredAlarms,
              isSearching: _searchQuery.isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }
}