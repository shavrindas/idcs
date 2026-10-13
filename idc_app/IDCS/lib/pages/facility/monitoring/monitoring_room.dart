import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/indices/main_index/main_index_components.dart';
import 'package:idcs/components/shared/alarm_row.dart';
import 'package:idcs/services/common/alarm/alarm_api_service.dart';
import 'package:idcs/services/chart/chart_api_service.dart';
import 'package:idcs/services/common/facility_api_service.dart';
import 'package:idcs/services/common/web_socket_service.dart';
import 'package:idcs/main.dart';
import 'package:idcs/theme/app_theme.dart';
import '../../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/components/shared/app_toast.dart';

class MonitoringRoom extends StatefulWidget {
  final String userId;
  final String facilityId;

  const MonitoringRoom({
    super.key,
    required this.userId,
    required this.facilityId,
  });

  @override
  State<MonitoringRoom> createState() => _MonitoringRoomPage();
}

class _MonitoringRoomPage extends State<MonitoringRoom> {
  bool _isLoading = true;
  List<dynamic> _rooms = [];
  Map<int, int> _activeAlarmCounts = {};
  Map<int, double> _temperatures = {};

  /// 시설의 실시간 값. 호실 id -> (필드 이름 -> 값).
  ///
  /// 제어판이 쓰는 소켓과 같은 것이다. 이 소켓은 시설의 **모든 호실**을 한꺼번에
  /// 보내 주므로, 호실마다 따로 물을 필요 없이 목록에서 바로 현재 상태를
  /// 보여줄 수 있다. 한 호실씩 열어 봐야 알 수 있던 것을 첫 화면에서 보려는 것이
  /// 이 화면의 목적이다.
  final Map<int, Map<String, String>> _live = {};

  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription<String>? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _fetchFacilityData();

    _webSocketService.connect('${AppConfig.basewsUrl}/facilities/data/get/${widget.facilityId}');
    _wsSubscription = _webSocketService.messageStream.listen(_handleLiveMessage);
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _webSocketService.disconnect();
    super.dispose();
  }

  /// 소켓에서 온 한 덩어리를 호실별로 갈라 담는다.
  /// 키는 "호실.필드" 형태로 온다 (예: "23.temp_pv").
  void _handleLiveMessage(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      final datas = decoded is Map ? decoded['datas'] : null;
      if (datas is! Map) return;

      for (final entry in datas.entries) {
        final parts = entry.key.toString().split('.');
        if (parts.length != 2) continue;

        final roomId = int.tryParse(parts[0]);
        if (roomId == null) continue;

        (_live[roomId] ??= {})[parts[1]] = entry.value.toString();
      }
      if (mounted) setState(() {});
    } catch (_) {
      // 한 덩어리가 깨져 있어도 목록은 계속 돌아가야 한다.
    }
  }

  // 1. 유저 데이터(권한 등)를 불러오는 초기화 함수
  Future<void> _fetchFacilityData() async {
    setState(() {
      _isLoading = true; // 로딩 상태 활성화
    });

    try {
      final rooms = await FacilityApiService.getFacilityRooms(
        widget.facilityId,
      );
      final counts = await _loadActiveAlarmCounts();
      final temperatures = await _loadTemperatures();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _activeAlarmCounts = counts;
        _temperatures = temperatures;
      });
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        context.l10n.roomLoadFailed(describeApiError(context, e)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // 로딩 상태 해제
        });
      }
    }
  }

  /// Counts the facility's still-running alarms per room.
  /// A failure here only costs the badges, so the room list still opens.
  Future<Map<int, int>> _loadActiveAlarmCounts() async {
    try {
      final alarms = await AlarmApiService.getFacilitiesAlarms(
        widget.facilityId,
      );
      final counts = <int, int>{};
      for (final alarm in alarms.where(isAlarmActive)) {
        final roomId = alarm['room_id'];
        if (roomId is int) {
          counts[roomId] = (counts[roomId] ?? 0) + 1;
        }
      }
      return counts;
    } catch (_) {
      return {};
    }
  }

  /// Latest 고내온도 for every room, in one call.
  /// Like the alarm badges, a failure here only leaves the values blank —
  /// the user can still pick a room and read it on the panel.
  Future<Map<int, double>> _loadTemperatures() async {
    final id = int.tryParse(widget.facilityId);
    if (id == null) return {};
    try {
      return await ChartApiService.getLatestRoomTemperatures(id);
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    // The facility shell already provides the app bar (facility name + back) and
    // the bottom nav, so this page only draws its own section.
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchFacilityData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.roomPickerTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RoomGrid(
                    rooms: _rooms,
                    activeAlarmCounts: _activeAlarmCounts,
                    temperatures: _temperatures,
                    liveValues: _live,
                    onRoomPressed: (roomId) {
                      // 터치 시 호실 상세 제어판으로 이동
                      context.push(
                        '/facility_monitoring/${widget.userId}/${widget.facilityId}/$roomId',
                      );
                    },
                  ),
                ],
              ),
            ),
          );
  }
}
