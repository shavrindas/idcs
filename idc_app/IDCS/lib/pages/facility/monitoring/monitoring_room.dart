import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/facility/monitoring/room_watch_view.dart';
import 'package:idcs/components/indices/main_index/main_index_components.dart';
import 'package:idcs/components/shared/alarm_row.dart';
import 'package:idcs/services/common/alarm/alarm_api_service.dart';
import 'package:idcs/services/chart/chart_api_service.dart';
import 'package:idcs/services/common/facility_api_service.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
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
      if (decoded is! Map) return;

      // 서버가 감싸서 보내던 때도 있고 그대로 보내는 때도 있다. 둘 다 받는다.
      final datas = decoded['datas'] ?? decoded;
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    // 눕히면 호실 하나를 지켜보는 화면으로 바뀐다. 목록은 "어디가 문제인가"를
    // 찾는 자리고, 찾고 난 뒤에는 그 호실이 어떻게 움직이는지 한동안 봐야 할
    // 때가 있다 — 제상 뒤에 온도가 제대로 내려오는지 같은 것이다. 이미 이
    // 화면이 시설의 모든 호실 값을 받고 있어서 따로 물을 것이 없다.
    //
    // 셸이 가로에서 앱바와 탭 줄을 걷어낸다(FacilityShellPage). 가로 높이는
    // 세로의 절반도 안 되는데 그 둘이 3분의 1을 먹는다.
    if (MediaQuery.orientationOf(context) == Orientation.landscape) {
      return ValueListenableBuilder<MonitoringViewSettings>(
        valueListenable: MonitoringViewController.settings,
        builder: (context, view, _) => RoomWatchPager(
          rooms: _rooms,
          liveValues: _live,
          alarmCounts: _activeAlarmCounts,
          ledDigits: view.ledDigits,
        ),
      );
    }

    // The facility shell already provides the app bar (facility name + back) and
    // the bottom nav, so this page only draws its own section.
    return RefreshIndicator(
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
