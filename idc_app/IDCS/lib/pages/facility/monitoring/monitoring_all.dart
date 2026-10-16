// ===============================================================
// 경로: lib/pages/facility/monitoring/monitoring_all.dart
// 명세: 내가 맡은 모든 시설의 호실을 한 화면에서 본다
// ===============================================================
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/facility/monitoring/room_status.dart';
import 'package:idcs/components/shared/alarm_row.dart';
import 'package:idcs/components/shared/app_toast.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/main.dart';
import 'package:idcs/services/common/alarm/alarm_api_service.dart';
import 'package:idcs/services/common/api_client.dart';
import 'package:idcs/services/common/facility_api_service.dart';
import 'package:idcs/services/common/facility_shortcut.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
import 'package:idcs/services/common/user_api_service.dart';
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

  /// 호실 id -> 아직 끝나지 않은 알람 수.
  ///
  /// 실시간 값의 emergency_* 플래그만 보면 '내 시설'의 호실 목록과 답이
  /// 어긋난다. 그쪽은 알람 API 를 보고 빨갛게 칠하는데, 여기서 "모든 호실
  /// 정상"이라고 적어 두면 둘 중 하나는 거짓말이 된다.
  final Map<int, int> _alarmCounts = {};

  bool _isLoading = true;

  /// 관리자는 웹 콘솔에서 시설을 관리하므로 코드 등록 버튼을 내보내지 않는다.
  bool _isAdmin = false;

  /// 시설이 하나뿐일 때 그 시설로 한 번 넘어갔는지. 당겨서 새로고침할 때마다
  /// 다시 넘어가면 이 화면에 머무를 수가 없다.
  bool _jumped = false;

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
      final role = await UserApiService.getUserRole(widget.userId);
      final facilities = await FacilityApiService.getFacilities(widget.userId);

      // 시설마다 호실과 알람을 한 번씩 묻는다. 순서대로 기다리면 시설 수만큼
      // 느려지므로 전부 한꺼번에 보낸다.
      final roomsFuture = Future.wait(
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
      final alarmsFuture = Future.wait(
        facilities.map((f) async {
          try {
            final alarms =
                await AlarmApiService.getFacilitiesAlarms(f['id'].toString());
            return alarms.where(isAlarmActive).toList();
          } catch (_) {
            // 알람을 못 받으면 배지만 빠진다. 목록은 계속 보여준다.
            return <dynamic>[];
          }
        }),
      );

      final rooms = await roomsFuture;
      final counts = <int, int>{};
      for (final list in await alarmsFuture) {
        for (final alarm in list) {
          final roomId = alarm['room_id'];
          if (roomId is int) counts[roomId] = (counts[roomId] ?? 0) + 1;
        }
      }

      if (!mounted) return;
      setState(() {
        _isAdmin = role == 'ADMIN' || role == 'DEVELOPER';
        _facilities = facilities;
        _roomsByFacility
          ..clear()
          ..addEntries(rooms);
        _alarmCounts
          ..clear()
          ..addAll(counts);
      });
      _maybeOpenOnlyFacility(facilities);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, describeApiError(context, e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 시설이 하나뿐이면 이 화면은 한 줄짜리 목록이라 매번 한 번씩 더 눌러야
  /// 하는 자리밖에 안 된다. 그 시설로 바로 들어간다.
  ///
  /// push 가 아니라 go 로 간다. 스택을 갈아 끼우지 않으면 시설에서 뒤로 왔을 때
  /// 여기로 돌아오고, 돌아오자마자 또 들어가는 되돌이가 된다. 그 대신 시설 셸이
  /// 내 정보로 가는 길을 쥐고 있어야 해서 [FacilityShortcut] 을 먼저 세운다.
  void _maybeOpenOnlyFacility(List<dynamic> facilities) {
    final sole = facilities.length == 1;
    FacilityShortcut.markSoleFacility(sole);
    if (!sole || _jumped || !mounted) return;
    _jumped = true;
    context.go('/facility/${widget.userId}/${facilities.first['id']}/monitoring');
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

  /// 이 호실이 지금 어떤 상태인지.
  ///
  /// 알람 API 를 시설마다 또 부르지 않고, 이미 받고 있는 실시간 값에서 읽는다.
  RoomStatus _statusOf(int roomId) => RoomStatus.from(
        _live[roomId] ?? const {},
        alarmCount: _alarmCounts[roomId] ?? 0,
      );

  /// 지금 화면이 맡고 있는 호실 전부의 상태. 검색어와 무관하게 전부 센다 —
  /// 맨 위 요약 띠가 답하는 질문은 "어딘가 문제가 있나" 이고, 그 답이
  /// 검색창에 뭘 적었는지에 따라 달라지면 안 된다.
  Map<int, RoomStatus> get _allStatuses {
    final out = <int, RoomStatus>{};
    for (final rooms in _roomsByFacility.values) {
      for (final r in rooms) {
        if (r['id'] is int) out[r['id'] as int] = _statusOf(r['id'] as int);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final facilities = _shownFacilities;
    final statuses = _allStatuses;

    return ValueListenableBuilder<MonitoringViewSettings>(
      valueListenable: MonitoringViewController.settings,
      builder: (context, view, _) => Scaffold(
        // 알람과 내 정보는 아래 탭이 아니라 헤더에 둔다. 이 화면이 하는 일은
        // '지금 어떤가'를 보는 것 하나뿐이라 아래에 탭 줄을 둘 이유가 없다.
        appBar: AppBar(
          title: Text(context.l10n.overviewTitle),
          centerTitle: true,
          actions: [
            if (!_isAdmin)
              IconButton(
                icon: const Icon(Icons.add_business_outlined),
                tooltip: context.l10n.facilityRegister,
                onPressed: () => context.push('/facility_register/${widget.userId}'),
              ),
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              tooltip: context.l10n.navAlarm,
              onPressed: () => context.push('/index/${widget.userId}/alarm'),
            ),
            IconButton(
              icon: const Icon(Icons.person_outline_rounded),
              tooltip: context.l10n.profileTitle,
              onPressed: () => context.push('/index/${widget.userId}/profile'),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (statuses.isNotEmpty) _OverviewSummaryBand(statuses: statuses.values.toList()),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        isDense: true,
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
                            // 아래 탭 줄이 없는 화면이라 제스처 바가 마지막
                            // 카드 위에 겹친다. 그만큼을 바닥에 더 둔다.
                            padding: EdgeInsets.fromLTRB(
                              16,
                              10,
                              16,
                              20 + MediaQuery.of(context).padding.bottom,
                            ),
                              itemCount: facilities.length,
                              itemBuilder: (context, index) {
                                final facility = facilities[index];
                                final facilityId = facility['id'].toString();
                                final rooms = _roomsByFacility[facilityId] ?? const [];

                                return _FacilitySection(
                                  name: facility['name']?.toString() ?? context.l10n.facilityUnnamed,
                                  rooms: rooms,
                                  liveValues: _live,
                                  statuses: statuses,
                                  ledDigits: view.ledDigits,
                                  onRoomPressed: (roomId) => context.push(
                                    '/facility_monitoring/${widget.userId}/$facilityId/$roomId',
                                  ),
                                  onFacilityPressed: () => context.push(
                                    '/facility/${widget.userId}/$facilityId/monitoring',
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// 화면 맨 위 한 줄 요약.
///
/// 이 화면을 여는 이유는 "지금 다 괜찮은가" 하나다. 그런데 그 답을 얻으려면
/// 카드를 전부 훑어야 했다 — 호실이 서른 개면 서른 개를 다 봐야 '없다'를
/// 확인할 수 있다. 그 한 가지를 글자로 먼저 답해 둔다. 괜찮으면 초록 한 줄만
/// 보고 화면을 닫을 수 있고, 아니면 몇 곳이 왜 걸렸는지 바로 읽는다.
class _OverviewSummaryBand extends StatelessWidget {
  final List<RoomStatus> statuses;

  const _OverviewSummaryBand({required this.statuses});

  int _count(RoomCondition c) =>
      statuses.where((s) => s.condition == c).length;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    final faults = _count(RoomCondition.fault);
    final drifts = _count(RoomCondition.drifting);
    final offline = _count(RoomCondition.offline);
    final attention = faults + drifts;

    // 색은 가장 나쁜 쪽을 따른다. 이상이 하나라도 있으면 빨강이고, 그 다음이
    // 설정값 이탈, 둘 다 없으면 초록이다. '값 없음'만 있을 때는 고장은 아니지만
    // 정상이라고 말할 근거도 없으므로 초록까지는 가지 않는다.
    final Color accent;
    if (faults > 0) {
      accent = colors.error;
    } else if (drifts > 0) {
      accent = colors.warning;
    } else if (offline > 0 && offline == statuses.length) {
      accent = colors.textSecondary;
    } else {
      accent = colors.success;
    }

    final breakdown = <String>[
      if (faults > 0) '${l10n.roomStatusFault} $faults',
      if (drifts > 0) '${l10n.roomStateDrift} $drifts',
      if (offline > 0) '${l10n.roomStateNoData} $offline',
    ];

    final title = attention == 0 ? l10n.overviewAllNormal : l10n.overviewAttention(attention);
    final subtitle = breakdown.isEmpty
        ? l10n.overviewWatching(statuses.length)
        : '${l10n.overviewWatching(statuses.length)} · ${breakdown.join(' · ')}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.16),
            ),
            child: Icon(
              attention == 0 ? Icons.verified_rounded : Icons.warning_amber_rounded,
              size: 20,
              color: accent,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: colors.textSecondary),
                ),
              ],
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
  final Map<int, RoomStatus> statuses;
  final bool ledDigits;
  final Function(int) onRoomPressed;

  /// 시설 이름 줄을 누르면 그 시설 안(차트·기록·알람)으로 들어간다.
  /// '내 시설' 목록이 없어진 뒤로는 여기가 유일한 입구다.
  final VoidCallback onFacilityPressed;

  const _FacilitySection({
    required this.name,
    required this.rooms,
    required this.liveValues,
    required this.statuses,
    required this.ledDigits,
    required this.onRoomPressed,
    required this.onFacilityPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // 스크롤해서 내려온 뒤에도 시설 이름 줄만 보고 이 시설이 괜찮은지 알아야
    // 한다. 맨 위 요약 띠는 그때 화면 밖이다.
    final attention = rooms
        .where((r) => r['id'] is int && (statuses[r['id'] as int]?.needsAttention ?? false))
        .length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onFacilityPressed,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(2, 5, 2, 5),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      // 누를 수 있는 줄이라는 표시. 이 줄이 시설 안으로 가는
                      // 유일한 입구라 눈에 띄어야 한다.
                      Icon(Icons.chevron_right_rounded, size: 19, color: colors.textSecondary),
                      const Spacer(),
                      if (attention > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$attention',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: colors.error),
                          ),
                        )
                      else if (rooms.isNotEmpty)
                        Text(
                          context.l10n.overviewRoomCount(rooms.length),
                          style: TextStyle(fontSize: 12, color: colors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // '내 시설' 안의 호실 목록보다 한 칸에 더 많이 담는다. 그쪽은 호실을
          // 고르러 가는 목록이고, 이 화면은 여러 시설을 한눈에 훑는 자리라
          // 보여줄 것이 다르다. 생김새는 같이 간다.
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              // 표시등 두 줄까지 들어가는 높이. 더 납작하게 두면 잘린다.
              childAspectRatio: 1.46,
            ),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final roomId = room['id'];

              return _OverviewRoomCard(
                name: room['name']?.toString() ?? '',
                values: liveValues[roomId] ?? const {},
                status: statuses[roomId] ?? RoomStatus.from(const {}),
                ledDigits: ledDigits,
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
///
/// 달라진 것은 값이 아니라 읽는 순서다. 왼쪽 띠와 숫자 색이 상태를 먼저
/// 말하고, 설정값과의 차이가 그 근거를 대고, 표시등은 확인하러 들어갈지
/// 말지를 정한 뒤에 본다.
class _OverviewRoomCard extends StatelessWidget {
  final String name;
  final Map<String, String> values;
  final RoomStatus status;
  final bool ledDigits;
  final VoidCallback onTap;

  const _OverviewRoomCard({
    required this.name,
    required this.values,
    required this.status,
    required this.ledDigits,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    final accent = status.accent(colors);
    final attention = status.needsAttention;
    final temp = status.temp;
    final deviation = status.deviation;

    // 값이 들어온 것만 표시등으로 내건다. 안 오는 값을 꺼진 등으로 그리면
    // 꺼져 있다는 뜻으로 읽힌다.
    final lamps = <Widget>[
      for (final entry in <(String, String, bool)>[
        ('deforest_def', l10n.roomStatusDefrost, false),
        ('temp_comp', l10n.roomStatusCompressor, false),
        ('emergency_emg', l10n.roomStatusFault, true),
        ('emergency_cint', l10n.roomStatusCint, true),
        ('emergency_high', l10n.roomStatusHigh, true),
      ])
        if (RoomStatus.asSwitch(values[entry.$1]) != null)
          StateLamp(
            label: entry.$2,
            on: RoomStatus.asSwitch(values[entry.$1])!,
            danger: entry.$3,
          ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: colors.cardShadow,
      ),
      child: Material(
        // 걸린 카드만 옅게 물들인다. 하얀 카드 열 장 사이에서 한 장이 붉으면
        // 읽지 않고도 찾아낼 수 있다.
        color: attention
            ? Color.alphaBlend(accent.withValues(alpha: 0.07), colors.surface)
            : colors.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: attention
                  ? Border.all(color: accent.withValues(alpha: 0.55), width: 1.2)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            // 빨간 카드가 왜 빨간지는 숫자로 말해 준다.
                            if (status.faultCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: colors.error.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  '${status.faultCount}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: colors.error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              temp == null ? '—' : temp.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 25,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                color: attention ? accent : colors.textPrimary,
                                // 제어판과 같은 7세그먼트 서체. 수치일 때만
                                // 쓴다 — '—' 를 7세그먼트로 그리면 읽을 수 없다.
                                fontFamily: temp != null && ledDigits
                                    ? MonitoringViewSettings.ledFontFamily
                                    : null,
                                letterSpacing: temp != null && ledDigits ? 1 : null,
                              ),
                            ),
                            if (temp != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 2, bottom: 2),
                                child: Text(
                                  l10n.unitCelsius,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        // 숫자 하나만으로는 그게 정상인지 알 수 없다. 설정값과
                        // 얼마나 벌어져 있는지가 실제로 보고 싶은 값이다.
                        Row(
                          children: [
                            if (status.setpoint != null)
                              Text(
                                '${l10n.roomSetpointShort} ${status.setpoint!.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textSecondary,
                                ),
                              ),
                            if (deviation != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                'Δ ${deviation >= 0 ? '+' : ''}${deviation.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: status.condition == RoomCondition.drifting
                                      ? colors.warning
                                      : colors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        // 표시등은 맨 아래에 모아 둔다. 줄 수가 언어마다 달라서
                        // 남는 높이를 여기서 먹는다.
                        Expanded(
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: lamps,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 상태 띠. 카드 아래를 가로로 긋는다 — 격자를 훑을 때
                // 색 줄만 따라가면 걸린 칸이 보인다.
                Container(height: 4, color: status.railColor(colors)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
