import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:idcs/components/facility/monitoring/Allmonitoring.dart';
import 'package:idcs/services/common/facility_api_service.dart';
import 'package:idcs/services/common/web_socket_service.dart';
import 'package:idcs/main.dart';

class MonitoringAll extends StatefulWidget {
  final String userId;

  const MonitoringAll({super.key, required this.userId});

  @override
  State<MonitoringAll> createState() => _MonitoringAllState();
}

class _MonitoringAllState extends State<MonitoringAll> {
  List<dynamic> facilityList = [];
  bool isLoading = true;

  // 💡 호실 ID(roomId)별 실시간 데이터를 저장할 상태 (예: {"25": {"temp_pv": 13}, "26": {"temp_pv": 14}})
  final Map<String, Map<String, dynamic>> deviceDataMap = {};

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription<String>? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _fetchFacilities();
    _webSocketService.connect('${AppConfig.basewsUrl}/facilities/data/outget/${widget.userId}');
    _wsSubscription = _webSocketService.messageStream.listen((rawJson) {
      _parseAndMapDeviceMessage(rawJson);
    });
  }

  List<dynamic> get filteredFacilityList {
    if (searchQuery.trim().isEmpty) {
      return facilityList;
    }
    final query = searchQuery.toLowerCase().trim();
    return facilityList.where((facility) {
      final facilityId = (facility['id']?.toString() ?? '').toLowerCase();
      final facilityName = (facility['name']?.toString() ?? '').toLowerCase();

      return facilityName.contains(query) || facilityId.contains(query);
    }).toList();
  }

  // 💡 웹소켓 메시지 파싱 및 호실 ID별 데이터 매핑
  void _parseAndMapDeviceMessage(String rawJsonString) {
    try {
      final Map<String, dynamic> parsedJson = jsonDecode(rawJsonString);
      // 'datas' 또는 최상위 Map 구조에 맞게 처리
      final Map<String, dynamic> parsedSJson = parsedJson['datas'] ?? parsedJson;

      setState(() {
        parsedSJson.forEach((key, value) {
          // 키 형식 예시: "25.temp_pv"
          final List<String> parts = key.split('.');
          if (parts.length >= 2) {
            final String roomId = parts[0];     // "25"
            final String sensorKey = parts[1];  // "temp_pv"

            // 해당 호실의 데이터 맵 초기화 및 값 업데이트
            deviceDataMap.putIfAbsent(roomId, () => {});
            deviceDataMap[roomId]![sensorKey] = value;
          }
        });
      });
    } catch (e) {
      print('웹소켓 데이터 파싱 에러: $e');
    }
  }

  Future<void> _fetchFacilities() async {
    try {
      final facilities = await FacilityApiService.getFacilities(widget.userId);
      setState(() {
        facilityList = facilities;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('시설 목록을 불러오는 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _wsSubscription?.cancel();
    _webSocketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayList = filteredFacilityList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('시설 및 호실 실시간 제어판'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: '시설 이름 또는 ID로 검색...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),

          Expanded(
            child: displayList.isEmpty
                ? Center(
              child: Text(
                searchQuery.isEmpty ? '등록된 시설이 없습니다.' : '검색 결과가 없습니다.',
                style: const TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final facility = displayList[index];
                final facilityId = facility['id']?.toString() ?? '';
                final facilityName = facility['name'] ?? '시설 $facilityId';

                return _FacilityMonitoringCard(
                  key: ValueKey(facilityId),
                  userId: widget.userId,
                  facilityId: facilityId,
                  facilityName: facilityName,
                  // 💡 파싱된 실시간 데이터 맵 전달
                  deviceDataMap: deviceDataMap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// 시설별 카드 위젯
// ------------------------------------------------------------------
class _FacilityMonitoringCard extends StatefulWidget {
  final String userId;
  final String facilityId;
  final String facilityName;
  final Map<String, Map<String, dynamic>> deviceDataMap; // 💡 추가

  const _FacilityMonitoringCard({
    super.key,
    required this.userId,
    required this.facilityId,
    required this.facilityName,
    required this.deviceDataMap,
  });

  @override
  State<_FacilityMonitoringCard> createState() => _FacilityMonitoringCardState();
}

class _FacilityMonitoringCardState extends State<_FacilityMonitoringCard> {
  List<dynamic> roomList = [];
  int currentRoomIndex = 0;
  bool isRoomLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    try {
      final rooms = await FacilityApiService.getFacilityRooms(widget.facilityId);

      // 💡 위젯이 화면에 살아있는지 확인 (위젯이 파괴되었다면 이하 실행 중단)
      if (!mounted) return;

      setState(() {
        roomList = rooms;
        isRoomLoading = false;
      });
    } catch (e) {
      // 💡 에러 발생 후 setState 전에도 확인 필요
      if (!mounted) return;

      setState(() => isRoomLoading = false);
    }
  }

  void _nextRoom() {
    if (roomList.isNotEmpty) {
      setState(() {
        currentRoomIndex = (currentRoomIndex + 1) % roomList.length;
      });
    }
  }

  void _prevRoom() {
    if (roomList.isNotEmpty) {
      setState(() {
        currentRoomIndex = (currentRoomIndex - 1 + roomList.length) % roomList.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isRoomLoading) {
      return const Card(
        margin: EdgeInsets.only(bottom: 16.0),
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (roomList.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.facilityName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('등록된 호실이 없습니다.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final currentRoom = roomList[currentRoomIndex];
    final roomId = currentRoom['roomId']?.toString() ?? currentRoom['id']?.toString() ?? '-';
    final roomName = currentRoom['roomName'] ?? currentRoom['name'] ?? '$roomId호';

    // 💡 현재 선택된 호실의 실시간 데이터 가로채기
    final roomRealtimeData = widget.deviceDataMap[roomId] ?? {};
    final tempPvValue = roomRealtimeData['temp_pv']?.toString() ?? '-';
    final tempSValue = roomRealtimeData['temp_sv']?.toString() ?? '-';
    final tempCompvalue = roomRealtimeData['temp_comp']?.toString() ?? '-';
    final defvalue = roomRealtimeData['deforest_def']?.toString() ?? '-';
    final emgvalue = roomRealtimeData['emergency_emg']?.toString() ?? '-';
    final emgcintvalue = roomRealtimeData['emergency_cint']?.toString() ?? '-';
    final emghighvalue = roomRealtimeData['emergency_high']?.toString() ?? '-';

    final Map<String, String> cardFields = {
      '현재 온도': tempPvValue != '-' ? '$tempPvValue ℃' : '-', // 💡 temp_pv 값 매핑
      '설정 온도': tempSValue != '-' ? '$tempSValue ℃' : '-', // 💡 temp_sv 값 매핑
      '컴프레셔 작동': tempCompvalue != '-' ? (tempCompvalue == '1' ? 'ON' : "OFF") : '-', // 💡 temp_sv 값 매핑
      '제상 작동': defvalue != '-' ? (tempCompvalue == '1' ? 'ON' : "OFF") : '-', // 💡 temp_sv 값 매핑
      '이상 발생': emgvalue != '-' ? (emgvalue == '1' ? 'ON' : "OFF") : '-', // 💡 temp_sv 값 매핑
      'CINT 발생': emgcintvalue != '-' ? (emgcintvalue == '1' ? 'ON' : "OFF") : '-', // 💡 temp_sv 값 매핑
      'high 발생': emghighvalue != '-' ? (emghighvalue == '1' ? 'ON' : "OFF") : '-', // 💡 temp_sv 값 매핑
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.facilityName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 16),
                      onPressed: roomList.length > 1 ? _prevRoom : null,
                      tooltip: '이전 방',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        '${currentRoomIndex + 1}/${roomList.length}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: roomList.length > 1 ? _nextRoom : null,
                      tooltip: '다음 방',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AllmonitoringCard(
            title: '$roomName 실시간 정보',
            fields: cardFields,
          ),
        ],
      ),
    );
  }
}