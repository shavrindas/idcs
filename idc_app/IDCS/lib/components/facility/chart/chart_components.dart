// ===============================================================
// 경로: lib/components/facility/chart/chart_components.dart
// 명세: 차트 시각화를 위한 화면 분할 Box 컴포넌트
// ===============================================================
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/l10n/l10n_context.dart';

/// Box #1: 차트 필터 박스 (해상도 및 조회 기간 설정)
class ChartFilterBox extends StatelessWidget {
  // [수정: 데이터 타입 종속성 해제]
  // chart_group_table의 구조와 그룹핑이 단일 데이터 타입(temp, gear 등)을 가리지 않고
  // 복합적인 데이터 포인트 롤을 한 번에 렌더링할 수 있도록 변경되었습니다.
  // 이에 따라 기존에 존재하던 currentDataType 및 onDataTypeChanged 파라미터를 완전히 제거했습니다.
  final String currentScale;
  final String currentTimeRange;
  final Function(String) onScaleChanged;
  final Function(String) onTimeRangeChanged;
  final VoidCallback onApply;

  /// 조회 대상 호실. 예전에는 1번 호실로 고정되어 있어 다른 호실에서는 차트가 아예 뜨지 않았다.
  final List<dynamic> rooms;
  final int? selectedRoomId;
  final Function(int) onRoomChanged;

  const ChartFilterBox({
    super.key,
    required this.currentScale,
    required this.currentTimeRange,
    required this.onScaleChanged,
    required this.onTimeRangeChanged,
    required this.onApply,
    required this.rooms,
    required this.selectedRoomId,
    required this.onRoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: context.l10n.chartFilterTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int>(
            value: selectedRoomId,
            isExpanded: true,
            decoration: InputDecoration(labelText: context.l10n.chartRoom),
            items: rooms
                .map(
                  (room) => DropdownMenuItem<int>(
                    value: room['id'] is int ? room['id'] : int.tryParse(room['id'].toString()),
                    child: Text(room['name']?.toString() ?? context.l10n.chartRoomUnnamed, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) onRoomChanged(val);
            },
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: currentScale,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: context.l10n.chartResolution),
                  items: [
                    DropdownMenuItem(
                      value: '10s',
                      child: Text(context.l10n.chartRes10s, overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: '1m',
                      child: Text(context.l10n.chartRes1m, overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: '5m',
                      child: Text(context.l10n.chartRes5m, overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: '1h',
                      child: Text(context.l10n.chartRes1h, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) onScaleChanged(val);
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: currentTimeRange,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: context.l10n.chartRange),
                  items: [
                    DropdownMenuItem(
                      value: '1h',
                      child: Text(context.l10n.chartRange1h, overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: '12h',
                      child: Text(context.l10n.chartRange12h, overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: '1d',
                      child: Text(context.l10n.chartRange1d, overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: '7d',
                      child: Text(context.l10n.chartRange7d, overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: '15d',
                      child: Text(context.l10n.chartRange15d, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) onTimeRangeChanged(val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 58,
                child: ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18)),
                  child: Text(context.l10n.chartApply),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Box #2: 데이터 포인트(시리즈) 선택 박스
class ChartSeriesBox extends StatelessWidget {
  final List<Map<String, dynamic>> availableGroups; // 이제 개별 role이 아닌 Group 리스트를 받습니다.
  final int? selectedGroupId; // 라디오 버튼처럼 단일 선택으로 변경 (차트 하나당 한 그룹)
  final Function(int) onGroupSelected;

  /// 그룹과 상관없이 호실의 항목을 직접 고르는 모드.
  final bool directMode;
  final VoidCallback onDirectModeSelected;

  /// 호실에 등록된 전체 포인트 롤. 그룹 API는 이름을 주지 않아 따로 받아 맞춘다.
  final List<dynamic> roles;

  /// 지금 차트에 그릴 롤. 그룹을 고르면 그룹의 롤로 채워지고, 여기서 개별로 끄고 켤 수 있다.
  final Set<int> visibleRoleIds;
  final Function(int, bool) onRoleToggled;

  const ChartSeriesBox({
    super.key,
    required this.availableGroups,
    required this.selectedGroupId,
    required this.onGroupSelected,
    required this.directMode,
    required this.onDirectModeSelected,
    required this.roles,
    required this.visibleRoleIds,
    required this.onRoleToggled,
  });

  int? _roleId(dynamic role) => role['role_id'] is int ? role['role_id'] : int.tryParse(role['role_id'].toString());

  /// 체크박스로 보여줄 항목. 그룹 모드면 그룹에 묶인 것만, 직접 선택이면 전체.
  List<dynamic> get _shownRoles {
    if (directMode) return roles;

    final group = availableGroups.where((g) => g['group_id'] == selectedGroupId).firstOrNull;
    if (group == null) return const [];

    final groupRoleIds = (group['role_ids'] as List?)?.whereType<int>().toSet() ?? <int>{};
    return roles.where((r) => groupRoleIds.contains(_roleId(r))).toList();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shownRoles;

    return _SectionCard(
      title: context.l10n.chartGroups,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (availableGroups.isEmpty && !directMode)
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(context.l10n.chartNoGroups, style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
            ),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              ...availableGroups.map((group) {
                final isSelected = !directMode && selectedGroupId == group['group_id'];
                return _chip(
                  context,
                  label: group['group_name'],
                  selected: isSelected,
                  onSelected: () => onGroupSelected(group['group_id']),
                );
              }),
              _chip(context, label: context.l10n.chartPickManually, selected: directMode, onSelected: onDirectModeSelected),
            ],
          ),
          if (shown.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: context.colors.outline),
            const SizedBox(height: 10),
            Text(
              directMode ? context.l10n.chartPickItems : context.l10n.chartGroupItems,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.textSecondary),
            ),
            // 선이 6개를 넘어가면 서로 가려서 추세를 읽기 어려워진다.
            if (visibleRoleIds.length > _readableSeriesLimit) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: context.colors.warning),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      context.l10n.chartTooManySeries(visibleRoleIds.length, _readableSeriesLimit),
                      style: TextStyle(fontSize: 12, color: context.colors.warning),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 168),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: shown.map((role) {
                    final id = _roleId(role);
                    final checked = id != null && visibleRoleIds.contains(id);
                    return FilterChip(
                      label: Text(role['role_name']?.toString() ?? context.l10n.noName),
                      selected: checked,
                      onSelected: id == null ? null : (val) => onRoleToggled(id, val),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: checked ? context.colors.primary : context.colors.textSecondary,
                      ),
                      showCheckmark: false,
                      selectedColor: context.colors.primary.withValues(alpha: 0.12),
                      backgroundColor: context.colors.background,
                      side: BorderSide(color: checked ? context.colors.primary : context.colors.outline),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      showCheckmark: false,
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        if (val) onSelected();
      },
      labelStyle: TextStyle(
        color: selected ? context.colors.onPrimary : context.colors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      selectedColor: context.colors.primary,
      backgroundColor: context.colors.background,
      side: BorderSide(color: selected ? context.colors.primary : context.colors.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

/// 한 차트에 이 개수를 넘게 그리면 선이 서로 가려 추세를 읽기 어렵다.
const int _readableSeriesLimit = 6;

/// 차트 위에 붙는 범례. 어떤 선이 어떤 항목인지 차트 안에서 바로 알 수 있게 한다.
/// 색 표시만으로는 부족하므로 선 모양(실선/파선/점선)도 함께 그린다.
class _ChartLegend extends StatelessWidget {
  final List<String> names;
  final List<List<int>?> dashes;
  final List<Color> colors;

  const _ChartLegend({required this.names, required this.dashes, required this.colors});

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: List.generate(names.length, (i) {
          final color = colors[i % colors.length];
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size(18, 2),
                painter: _LegendLinePainter(color: color, dash: dashes[i]),
              ),
              const SizedBox(width: 5),
              Text(
                names[i],
                style: TextStyle(fontSize: 12, color: context.colors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// 범례의 선 미리보기. 차트에 그려지는 것과 같은 파선 패턴을 재현한다.
class _LegendLinePainter extends CustomPainter {
  final Color color;
  final List<int>? dash;

  _LegendLinePainter({required this.color, required this.dash});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;
    if (dash == null) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }

    double x = 0;
    int i = 0;
    while (x < size.width) {
      final len = dash![i % dash!.length].toDouble();
      if (i.isEven) {
        canvas.drawLine(Offset(x, y), Offset((x + len).clamp(0, size.width), y), paint);
      }
      x += len;
      i++;
    }
  }

  @override
  bool shouldRepaint(_LegendLinePainter old) => old.color != color || old.dash != dash;
}

/// 시리즈별 선 모양. 색을 못 쓰는 상황(색각 이상, 흑백 인쇄)에서도 구분되게 한다.
/// null이면 실선.
const List<List<int>?> _seriesDashPatterns = [
  null, // 실선
  [6, 3], // 파선
  [2, 3], // 점선
  [10, 3, 2, 3], // 일점쇄선
  [8, 4],
  [3, 2, 8, 2],
];

// 시리즈 색상 팔레트는 테마마다 달라야 해서(어두운 배경에서 진한 색이 안 보인다)
// AppPalette.chartSeries로 옮겼다. 통계 박스와 캔버스가 같은 순서로 순회하므로
// 항상 같은 색이 매칭된다.

/// 조회된 구간의 최소/평균/최대값을 시리즈별로 요약해서 보여주는 박스.
/// 그래프를 눈으로 훑지 않아도 한눈에 수치 요약을 볼 수 있게 한다.
class ChartStatsBox extends StatelessWidget {
  final Map<String, dynamic>? chartData;

  const ChartStatsBox({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> datasets = chartData?['data']?['datasets'] ?? [];
    if (datasets.isEmpty) return const SizedBox.shrink();

    final List<_SeriesStat> stats = [];
    for (int i = 0; i < datasets.length; i++) {
      final ds = datasets[i];
      final List<dynamic> points = ds['data'] ?? [];
      if (points.isEmpty) continue;

      double sum = 0;
      int count = 0;
      double? minVal;
      double? maxVal;

      for (final p in points) {
        // 온도/기어처럼 집계된 min/max가 있으면 그것을, 없으면(정적/불리언) mean·status만 사용.
        final double? mean = (p['mean'] as num?)?.toDouble();
        final double? pMin = (p['min'] as num?)?.toDouble() ?? mean;
        final double? pMax = (p['max'] as num?)?.toDouble() ?? mean;
        final double? statusVal = p.containsKey('status') ? (p['status'] == true ? 1.0 : 0.0) : null;

        final double? value = mean ?? statusVal;
        if (value != null) {
          sum += value;
          count++;
        }
        if (pMin != null) minVal = (minVal == null) ? pMin : (pMin < minVal ? pMin : minVal);
        if (pMax != null) maxVal = (maxVal == null) ? pMax : (pMax > maxVal ? pMax : maxVal);
        if (statusVal != null) {
          minVal = (minVal == null) ? statusVal : (statusVal < minVal ? statusVal : minVal);
          maxVal = (maxVal == null) ? statusVal : (statusVal > maxVal ? statusVal : maxVal);
        }
      }

      if (count == 0 && minVal == null) continue;

      stats.add(
        _SeriesStat(
          name: ds['display_name'] ?? ds['role_name'] ?? context.l10n.chartSeriesN(i + 1),
          color: context.colors.chartSeries[i % context.colors.chartSeries.length],
          min: minVal,
          avg: count > 0 ? sum / count : null,
          max: maxVal,
        ),
      );
    }

    if (stats.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: context.l10n.chartSummary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: stats
            .map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _statChip(context, context.l10n.chartMin, s.min),
                    const SizedBox(width: 6),
                    _statChip(context, context.l10n.chartAvg, s.avg),
                    const SizedBox(width: 6),
                    _statChip(context, context.l10n.chartMax, s.max),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _statChip(BuildContext context, String label, double? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: context.colors.background, borderRadius: BorderRadius.circular(8)),
      child: Text(
        '$label ${value != null ? value.toStringAsFixed(1) : '-'}',
        style: TextStyle(fontSize: 12, color: context.colors.textSecondary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SeriesStat {
  final String name;
  final Color color;
  final double? min;
  final double? avg;
  final double? max;

  _SeriesStat({required this.name, required this.color, this.min, this.avg, this.max});
}

/// Box #3: 차트 렌더링 캔버스 영역
class ChartCanvasBox extends StatelessWidget {
  final Map<String, dynamic>? chartData;
  final bool isLoading;
  final bool showTargetLines;

  const ChartCanvasBox({super.key, required this.chartData, required this.isLoading, this.showTargetLines = true});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildContainer(context, child: const Center(child: CircularProgressIndicator()));
    }

    if (chartData == null ||
        chartData!['data']['datasets'] == null ||
        (chartData!['data']['datasets'] as List).isEmpty) {
      return _buildContainer(
        context,
        child: Center(
          child: Text(context.l10n.chartNoData, style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
        ),
      );
    }

    // [수정] 백엔드에서 data_type을 제거했으므로 해당 변수 추출(String dataType = ...) 구문을 삭제했습니다.
    final List<dynamic> datasets = chartData!['data']['datasets'];
    final List<dynamic> alarms = chartData!['data']['alarms'] ?? [];

    List<LineChartBarData> lineBars = [];
    List<HorizontalLine> targetLines = [];
    // 범례와 툴팁에서 쓸 시리즈 이름/선 모양 (lineBars와 같은 순서)
    final List<String> seriesNames = [];
    final List<List<int>?> seriesDashes = [];
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    final List<Color> colors = context.colors.chartSeries;

    for (int i = 0; i < datasets.length; i++) {
      final ds = datasets[i];
      final List<dynamic> dataPoints = ds['data'];
      List<FlSpot> spots = [];
      final Color seriesColor = colors[i % colors.length];

      // target_value, target_low_limit 등은 Null일 수 있으므로 파싱 방어 추가.
      // 데이터 자체 범위와 무관하게 "안전 기준선"을 그리는 데 사용한다.
      final String? rawLow = ds['target_low_limit'];
      final String? rawHigh = ds['target_high_limit'];
      final double? targetLow = rawLow != null ? double.tryParse(rawLow) : null;
      final double? targetHigh = rawHigh != null ? double.tryParse(rawHigh) : null;

      for (var point in dataPoints) {
        final DateTime dt = DateTime.parse(point['timestamp']).toLocal();
        final double x = dt.millisecondsSinceEpoch.toDouble();

        double y = 0.0;

        // [수정] 전역 dataType 대신 개별 포인트 내부의 key(mean vs status) 존재 여부로 파악합니다.
        if (point.containsKey('mean')) {
          y = (point['mean'] as num?)?.toDouble() ?? 0.0;
        } else if (point.containsKey('status')) {
          y = point['status'] == true ? 1.0 : 0.0;
        }

        spots.add(FlSpot(x, y));

        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }

      if (spots.isNotEmpty) {
        // 색만으로 시리즈를 구분하면 색각 이상이나 흑백 출력(포스터·인쇄)에서 구분이 안 된다.
        // 실선/파선/점선을 함께 돌려 색 없이도 구분되게 한다.
        seriesNames.add(ds['display_name'] ?? ds['role_name'] ?? context.l10n.chartSeriesN(i + 1));
        final dash = _seriesDashPatterns[i % _seriesDashPatterns.length];
        seriesDashes.add(dash);

        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: seriesColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dashArray: dash,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        );

        if (showTargetLines) {
          if (targetLow != null) {
            targetLines.add(_targetLine(targetLow, seriesColor, context.l10n.chartLowerLimit(targetLow.toStringAsFixed(1))));
            if (targetLow < minY) minY = targetLow;
            if (targetLow > maxY) maxY = targetLow;
          }
          if (targetHigh != null) {
            targetLines.add(_targetLine(targetHigh, seriesColor, context.l10n.chartUpperLimit(targetHigh.toStringAsFixed(1))));
            if (targetHigh < minY) minY = targetHigh;
            if (targetHigh > maxY) maxY = targetHigh;
          }
        }
      }
    }

    // 조회 기간 안에서 발생한 알람을 세로 점선으로 표시해, 수치 변화와 알람 발생 시점을 한눈에 대조할 수 있게 한다.
    List<VerticalLine> alarmLines = [];
    if (minX != double.infinity && maxX != -double.infinity) {
      for (final a in alarms) {
        final DateTime? ts = DateTime.tryParse(a['timestamp']?.toString() ?? '')?.toLocal();
        if (ts == null) continue;
        final double x = ts.millisecondsSinceEpoch.toDouble();
        if (x < minX || x > maxX) continue;
        final String name = a['alarm_name']?.toString() ?? context.l10n.alarmShort;
        alarmLines.add(
          VerticalLine(
            x: x,
            color: context.colors.error.withValues(alpha: 0.7),
            strokeWidth: 1.5,
            dashArray: [4, 4],
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              style: TextStyle(fontSize: 12, color: context.colors.error, fontWeight: FontWeight.w700),
              labelResolver: (line) => name,
            ),
          ),
        );
      }
    }

    if (minY == double.infinity || maxY == -double.infinity) {
      minY = 0;
      maxY = 10;
    } else if (minY == maxY) {
      minY -= 5;
      maxY += 5;
    } else {
      final padding = (maxY - minY) * 0.1;
      minY -= padding;
      maxY += padding;
    }

    if (lineBars.isEmpty) {
      return _buildContainer(
        context,
        child: Center(
          child: Text(context.l10n.chartNoValidData, style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
        ),
      );
    }

    return _buildContainer(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChartLegend(names: seriesNames, dashes: seriesDashes, colors: colors),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 8.0),
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: lineBars,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      // 기본 배경은 어두운 회색 고정이라 어두운 테마에서 차트와 섞인다.
                      getTooltipColor: (_) =>
                          context.colors.isDark ? context.colors.background : const Color(0xFF2B3843),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final dt = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                          final timeStr = DateFormat('MM-dd HH:mm').format(dt);
                          // 여러 선이 겹칠 때 어느 시리즈의 값인지 알 수 없어 이름을 함께 보여준다.
                          final name = spot.barIndex < seriesNames.length ? seriesNames[spot.barIndex] : '';
                          return LineTooltipItem(
                            '$name\n$timeStr\n${spot.y.toStringAsFixed(1)}',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(color: context.colors.outline, strokeWidth: 1),
                    getDrawingVerticalLine: (value) => FlLine(color: context.colors.outline, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value == minX || value == maxX) return const SizedBox.shrink();
                          final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('HH:mm').format(dt),
                              style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(horizontalLines: targetLines, verticalLines: alarmLines),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 기준선(안전 범위 상/하한)을 시리즈와 같은 색의 점선으로 표시한다.
  HorizontalLine _targetLine(double y, Color color, String label) {
    return HorizontalLine(
      y: y,
      color: color.withValues(alpha: 0.6),
      strokeWidth: 1.5,
      dashArray: [6, 4],
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.topRight,
        padding: const EdgeInsets.only(right: 4, bottom: 2),
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
        labelResolver: (line) => label,
      ),
    );
  }

  // 차트 캔버스는 화면의 핵심 콘텐츠이므로 주변 설정 카드보다 한 단계 부각시킨다.
  Widget _buildContainer(BuildContext context, {required Widget child}) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.colors.softShadow,
      ),
      padding: const EdgeInsets.all(16.0),
      child: child,
    );
  }
}

/// Box #4: 차트 도구 박스 (제어 및 어노테이션 도구)
class ChartToolBox extends StatelessWidget {
  final bool showTargetLines;
  final ValueChanged<bool> onToggleTargetLines;

  const ChartToolBox({super.key, required this.showTargetLines, required this.onToggleTargetLines});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: context.l10n.chartTools,
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            icon: Icon(Icons.pan_tool_outlined, color: context.colors.textSecondary),
            onPressed: null,
            tooltip: context.l10n.chartPanDisabled,
          ),
          IconButton(
            icon: Icon(
              Icons.show_chart_rounded,
              color: showTargetLines ? context.colors.primary : context.colors.textSecondary,
            ),
            onPressed: () => onToggleTargetLines(!showTargetLines),
            tooltip: showTargetLines ? context.l10n.chartHideBaseline : context.l10n.chartShowBaseline,
          ),
          IconButton(
            icon: Icon(Icons.text_fields_rounded, color: context.colors.textSecondary),
            onPressed: null,
            tooltip: context.l10n.chartNoteDisabled,
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.colors.primary),
            onPressed: () {},
            tooltip: context.l10n.chartResetView,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textSecondary),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
