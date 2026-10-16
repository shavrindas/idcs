// ===============================================================
// 경로: lib/pages/facility/monitoring/monitoring_all.dart
// 명세: 내가 맡은 모든 시설의 호실을 한 화면에서 본다
// ===============================================================
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/indices/main_index/main_index_components.dart';
import 'package:idcs/components/shared/app_toast.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/main.dart';
import 'package:idcs/services/common/api_client.dart';
import 'package:idcs/services/common/facility_api_service.dart';
import 'package:idcs/services/common/web_socket_service.dart';
import 'package:idcs/theme/app_theme.dart';

/// 맡은 시설이 여럿인 사람을 위한 화면.
///
/// 예전에는 시설 카드 하나가 호실 하나만 보여주고 ‹ 1/10 › 로 넘겨야 했다.
/// 열 개짜리 시설이면 전부 보는 데 열 번을 눌러야 하는데, 이 화면을 여는
/// 이유는 "지금 다 괜찮은가" 한 가지라 그 열 번이 통째로 군더더기다.
/// 이제 호실을 전부 펼치고, 시설이 늘어나면 아래로 이어진다.
///
/// 카드 안에 버튼을 두지 않는다. 카드 자체가 버튼이고, 누르면 그 호실의
/// 제어판으로 들어간다.
class MonitoringAll extends StatefulWidget {
  final String userId;

  const MonitoringAll({super.key, required this.userId});

  @override
  State<MonitoringAll> createState() => _MonitoringAllState();
}

class _MonitoringAllState extends State<MonitoringAll> {
  List<dynamic> _facilities = [];

  /// 시설 id -> 그 시설의 호실 목록.
  final Map<String, List<dynamic>> _roomsByFacility = {};

  /// 호실 id -> (필드 이름 -> 값). 소켓 하나가 내 시설 전부를 실어 보낸다.
  final Map<int, Map<String, String>> _live = {};

  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription<String>? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _load();

    _webSocketService.connect('${AppConfig.basewsUrl}/facilities/data/outget/${widget.userId}');
    _wsSubscription = _webSocketService.messageStream.listen(_handleLiveMessage);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _wsSubscription?.cancel();
    _webSocketService.disconnect();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final facilities = await FacilityApiService.getFacilities(widget.userId);

      // 시설마다 호실을 한 번씩 묻는다. 순서대로 기다리면 시설 수만큼 느려지므로
      // 한꺼번에 보낸다.
      final rooms = await Future.wait(
        facilities.map((f) async {
          final id = f['id'].toString();
          try {
            return MapEntry(id, await FacilityApiService.getFacilityRooms(id));
          } catch (_) {
            // 한 시설이 실패해도 나머지는 보여준다.
            return MapEntry(id, <dynamic>[]);
          }
        }),
      );

      if (!mounted) return;
      setState(() {
        _facilities = facilities;
        _roomsByFacility
          ..clear()
          ..addEntries(rooms);
      });
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, describeApiError(context, e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
      // 한 묶음이 깨져 있어도 화면은 계속 돌아가야 한다.
    }
  }

  List<dynamic> get _shownFacilities {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _facilities;
    return _facilities
        .where((f) => (f['name']?.toString() ?? '').toLowerCase().contains(q))
        .toList();
  }

  /// 이 호실에 지금 올라온 이상이 있는지.
  ///
  /// 알람 API 를 시설마다 또 부르지 않고, 이미 받고 있는 실시간 값에서 읽는다.
  /// emergency_* 중 하나라도 켜져 있으면 이상으로 본다.
  int _faultCount(int roomId) {
    final values = _live[roomId];
    if (values == null) return 0;

    return values.entries
        .where((e) => e.key.startsWith('emergency_') && _isOn(e.value))
        .length;
  }

  static bool _isOn(String raw) {
    final v = raw.trim().toUpperCase();
    return v == 'ON' || v == '1' || v == 'TRUE';
  }

  @override
  Widget build(BuildContext context) {
    final facilities = _shownFacilities;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.overviewTitle), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: context.l10n.overviewSearchHint,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: context.l10n.boardSearchClear,
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: facilities.isEmpty
                      ? Center(
                          child: Text(
                            _query.isEmpty
                                ? context.l10n.overviewNoFacilities
                                : context.l10n.searchNoResults,
                            style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          // 시설이 늘어나면 아래로 이어진다.
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: facilities.length,
                            itemBuilder: (context, index) {
                              final facility = facilities[index];
                              final facilityId = facility['id'].toString();
                              final rooms = _roomsByFacility[facilityId] ?? const [];

                              return _FacilitySection(
                                name: facility['name']?.toString() ?? context.l10n.facilityUnnamed,
                                rooms: rooms,
                                liveValues: _live,
                                faultCounts: {
                                  for (final r in rooms)
                                    if (r['id'] is int) r['id'] as int: _faultCount(r['id'] as int),
                                },
                                onRoomPressed: (roomId) => context.push(
                                  '/facility_monitoring/${widget.userId}/$facilityId/$roomId',
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

/// 시설 한 곳: 이름 한 줄과 그 아래 호실 전부.
class _FacilitySection extends StatelessWidget {
  final String name;
  final List<dynamic> rooms;
  final Map<int, Map<String, String>> liveValues;
  final Map<int, int> faultCounts;
  final Function(int) onRoomPressed;

  const _FacilitySection({
    required this.name,
    required this.rooms,
    required this.liveValues,
    required this.faultCounts,
    required this.onRoomPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (rooms.isNotEmpty)
                  Text(
                    context.l10n.overviewRoomCount(rooms.length),
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
              ],
            ),
          ),
          // '내 시설' 안의 호실 목록보다 한 칸에 더 많이 담는다. 그쪽은 호실을
          // 고르러 가는 목록이고, 이 화면은 여러 시설을 한눈에 훑는 자리라
          // 보여줄 것이 다르다. 생김새(그림자·모서리·알람 테두리)는 같이 간다.
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              // 칩이 두 줄까지 늘어난다. 더 납작하게 두면 마지막 줄이 잘린다.
              childAspectRatio: 1.32,
            ),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final roomId = room['id'];

              return _OverviewRoomCard(
                name: room['name']?.toString() ?? '',
                values: liveValues[roomId] ?? const {},
                hasFault: (faultCounts[roomId] ?? 0) > 0,
                onTap: () => onRoomPressed(roomId),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 개괄 화면의 호실 한 칸.
///
/// 설민이 처음 만든 카드가 보여주던 일곱 가지를 그대로 담는다 — 현재 온도,
/// 설정 온도, 콤프, 제상, 이상, CINT, HIGH. 호실을 하나씩 넘겨 보던 것을
/// 전부 펼치면서 값이 줄어 버리면, 넘겨 보던 때보다 못해진다.
class _OverviewRoomCard extends StatelessWidget {
  final String name;
  final Map<String, String> values;
  final bool hasFault;
  final VoidCallback onTap;

  const _OverviewRoomCard({
    required this.name,
    required this.values,
    required this.hasFault,
    required this.onTap,
  });

  /// 설비는 ON/OFF 로 보내기도 하고 1/0 으로 보내기도 한다. 알 수 없는 값이면
  /// null — 그 칸은 아예 내보내지 않는다. 안 오는 값을 'OFF' 로 그리면
  /// 꺼져 있다는 뜻으로 읽힌다.
  bool? _switchOf(String key) {
    final v = values[key]?.trim().toUpperCase();
    if (v == null || v.isEmpty || v == 'NA' || v == '-') return null;
    if (v == 'ON' || v == 'TRUE') return true;
    if (v == 'OFF' || v == 'FALSE') return false;

    // 같은 상태가 숫자로 오기도 한다 — '1'/'0' 뿐 아니라 '0.0' 처럼도 온다
    // (temp_comp 가 그렇다). 0이면 꺼짐, 그 밖의 수는 켜짐으로 읽는다.
    final n = double.tryParse(v);
    return n == null ? null : n != 0;
  }

  double? _numberOf(String key) => double.tryParse(values[key]?.trim() ?? '');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    final temp = _numberOf('temp_pv');
    final setpoint = _numberOf('temp_sv');

    // 값이 들어온 것만 칩으로 내건다.
    final pills = <Widget>[
      for (final entry in <(String, String, bool)>[
        ('deforest_def', l10n.roomStatusDefrost, false),
        ('temp_comp', l10n.roomStatusCompressor, false),
        ('emergency_emg', l10n.roomStatusFault, true),
        ('emergency_cint', l10n.roomStatusCint, true),
        ('emergency_high', l10n.roomStatusHigh, true),
      ])
        if (_switchOf(entry.$1) != null)
          StatePill(label: entry.$2, on: _switchOf(entry.$1)!, danger: entry.$3),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: colors.cardShadow,
      ),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: hasFault ? Border.all(color: colors.error) : null,
            ),
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      temp == null ? '—' : temp.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 24,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (temp != null)
                      Text(
                        l10n.unitCelsius,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary),
                      ),
                    const Spacer(),
                    if (setpoint != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${l10n.roomSetpointShort} ${setpoint.toStringAsFixed(1)}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: pills,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
