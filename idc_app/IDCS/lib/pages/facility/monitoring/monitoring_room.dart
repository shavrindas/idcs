import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/indices/main_index/main_index_components.dart';
import 'package:idcs/components/shared/alarm_row.dart';
import 'package:idcs/services/common/alarm/alarm_api_service.dart';
import 'package:idcs/services/common/facility_api_service.dart';
import 'package:idcs/theme/app_theme.dart';
import '../../../services/common/api_client.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/components/shared/app_toast.dart';

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
  Map<int, int> _activeAlarmCounts = {};

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
      final counts = await _loadActiveAlarmCounts();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _activeAlarmCounts = counts;
      });
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, context.l10n.roomLoadFailed(describeApiError(context, e)));
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
      final alarms = await AlarmApiService.getFacilitiesAlarms(widget.facilityId);
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
                    onRoomPressed: (roomId) {
                      // 터치 시 호실 상세 제어판으로 이동
                      context.push('/facility_monitoring/${widget.userId}/${widget.facilityId}/$roomId');
                    },
                  ),
                ],
              ),
            ),
          );
  }
}
