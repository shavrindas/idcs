// ===============================================================
// 경로: lib/components/facility/chart/chart_components.dart
// 명세: 차트 시각화를 위한 화면 분할 Box 컴포넌트
// ===============================================================
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:idcs/components/facility/monitoring/device_labels.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/components/shared/alarm_row.dart';
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
                    value: room['id'] is int
                        ? room['id']
                        : int.tryParse(room['id'].toString()),
                    child: Text(
                      room['name']?.toString() ?? context.l10n.chartRoomUnnamed,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                  decoration: InputDecoration(
                    labelText: context.l10n.chartResolution,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '10s',
                      child: Text(
                        context.l10n.chartRes10s,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: '1m',
                      child: Text(
                        context.l10n.chartRes1m,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: '5m',
                      child: Text(
                        context.l10n.chartRes5m,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: '1h',
                      child: Text(
                        context.l10n.chartRes1h,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                  decoration: InputDecoration(
                    labelText: context.l10n.chartRange,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '1h',
                      child: Text(
                        context.l10n.chartRange1h,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: '12h',
                      child: Text(
                        context.l10n.chartRange12h,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: '1d',
                      child: Text(
                        context.l10n.chartRange1d,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: '7d',
                      child: Text(
                        context.l10n.chartRange7d,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: '15d',
                      child: Text(
                        context.l10n.chartRange15d,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
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
class ChartSeriesBox extends StatefulWidget {
  final List<Map<String, dynamic>>
  availableGroups; // 이제 개별 role이 아닌 Group 리스트를 받습니다.
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

  @override
  State<ChartSeriesBox> createState() => _ChartSeriesBoxState();
}

class _ChartSeriesBoxState extends State<ChartSeriesBox> {
  /// 접었을 때 보여줄 칩 개수. 호실에 롤이 40개가 넘는 곳도 있어 전부 펴면
  /// 차트가 화면 밖으로 밀려난다.
  static const int _collapsedCount = 12;

  bool _expanded = false;

  /// 카드 자체를 펼쳐 둘지.
  ///
  /// 기본은 접어 둔다. 그룹 칩과 항목 칩이 모두 펼쳐져 있으면 카드 하나가
  /// 화면 두 배 높이가 되어, 정작 보러 온 차트까지 한참을 쓸어내려야 했다.
  /// 무엇이 켜져 있는지는 접은 상태에서도 제목 옆에 보인다.
  bool _open = false;

  int? _roleId(dynamic role) => role['role_id'] is int
      ? role['role_id']
      : int.tryParse(role['role_id'].toString());

  /// 체크박스로 보여줄 항목. 그룹 모드면 그룹에 묶인 것만, 직접 선택이면 전체.
  List<dynamic> get _shownRoles {
    if (widget.directMode) return widget.roles;

    final group = widget.availableGroups
        .where((g) => g['group_id'] == widget.selectedGroupId)
        .firstOrNull;
    if (group == null) return const [];

    final groupRoleIds =
        (group['role_ids'] as List?)?.whereType<int>().toSet() ?? <int>{};
    return widget.roles
        .where((r) => groupRoleIds.contains(_roleId(r)))
        .toList();
  }

  /// 접었을 때 제목 옆에 붙는 한 줄. 지금 무엇을 보고 있는지 알려 준다.
  String _summary(BuildContext context) {
    final l10n = context.l10n;
    if (widget.directMode) {
      return l10n.chartSeriesSummary(
        l10n.chartPickManually,
        widget.visibleRoleIds.length,
      );
    }

    final group = widget.availableGroups
        .where((g) => g['group_id'] == widget.selectedGroupId)
        .firstOrNull;
    if (group == null) return l10n.chartNoGroups;

    return l10n.chartSeriesSummary(
      group['group_name']?.toString() ?? l10n.noName,
      widget.visibleRoleIds.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shownRoles;

    return _SectionCard(
      title: context.l10n.chartGroups,
      onHeaderTap: () => setState(() => _open = !_open),
      headerSummary: _open ? null : _summary(context),
      trailing: Icon(
        _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
        color: context.colors.textSecondary,
      ),
      child: !_open
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.availableGroups.isEmpty && !widget.directMode)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      context.l10n.chartNoGroups,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    ...widget.availableGroups.map((group) {
                      final isSelected =
                          !widget.directMode &&
                          widget.selectedGroupId == group['group_id'];
                      return _chip(
                        context,
                        label: group['group_name'],
                        selected: isSelected,
                        onSelected: () =>
                            widget.onGroupSelected(group['group_id']),
                      );
                    }),
                    _chip(
                      context,
                      label: context.l10n.chartPickManually,
                      selected: widget.directMode,
                      onSelected: widget.onDirectModeSelected,
                    ),
                  ],
                ),
                if (shown.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, color: context.colors.outline),
                  const SizedBox(height: 10),
                  Text(
                    widget.directMode
                        ? context.l10n.chartPickItems
                        : context.l10n.chartGroupItems,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  // 선이 6개를 넘어가면 서로 가려서 추세를 읽기 어려워진다.
                  if (widget.visibleRoleIds.length > readableSeriesLimit) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: context.colors.warning,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            context.l10n.chartTooManySeries(
                              widget.visibleRoleIds.length,
                              readableSeriesLimit,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  // 안쪽에 스크롤을 두면 이 영역 위에서 쓸어올릴 때 페이지 대신 칩이
                  // 움직여 화면이 멈춘 것처럼 느껴진다. 대신 일부만 보여주고
                  // 펼치기로 늘린다 — 스크롤은 페이지 하나만 갖는다.
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final role
                          in (_expanded ? shown : shown.take(_collapsedCount)))
                        _roleChip(context, role),
                    ],
                  ),
                  if (shown.length > _collapsedCount) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(() => _expanded = !_expanded),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _expanded
                              ? context.l10n.chartShowLess
                              : context.l10n.chartShowAllPoints(shown.length),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
                // 카드 아래 여백. 접었을 때는 제목만 남아야 해서 _SectionCard 가
                // 아래쪽 여백을 주지 않는다.
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _roleChip(BuildContext context, dynamic role) {
    final id = _roleId(role);
    final checked = id != null && widget.visibleRoleIds.contains(id);
    return FilterChip(
      label: Text(_pointLabel(context, role['role_name'])),
      selected: checked,
      onSelected: id == null ? null : (val) => widget.onRoleToggled(id, val),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: checked ? context.colors.primary : context.colors.textSecondary,
      ),
      showCheckmark: false,
      selectedColor: context.colors.primary.withValues(alpha: 0.12),
      backgroundColor: context.colors.background,
      side: BorderSide(
        color: checked ? context.colors.primary : context.colors.outline,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
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
      side: BorderSide(
        color: selected ? context.colors.primary : context.colors.outline,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

/// 한 차트에 이 개수를 넘게 그리면 선이 서로 가려 추세를 읽기 어렵다.
/// 측정 항목의 표시 이름.
///
/// 서버가 내려주는 role_name 은 `control_cffan1` 같은 DB 필드 이름이라, 그대로
/// 두면 현장에서 어느 장비인지 알아볼 수 없다. 제어판과 같은 사전을 쓰므로
/// 두 화면에서 같은 항목이 같은 이름으로 보인다.
String _pointLabel(BuildContext context, dynamic roleName) {
  final raw = roleName?.toString() ?? '';
  return raw.isEmpty ? context.l10n.noName : DeviceLabels.of(context, raw);
}

/// 차트 범례에 쓸 이름. 서버가 따로 붙여 둔 이름이 있으면 그쪽을 존중한다.
String _seriesLabel(BuildContext context, dynamic dataset, int index) {
  final display = dataset['display_name']?.toString();
  if (display != null && display.isNotEmpty) return display;

  final raw = dataset['role_name']?.toString();
  if (raw == null || raw.isEmpty) return context.l10n.chartSeriesN(index + 1);
  return DeviceLabels.of(context, raw);
}

/// 한 차트에 겹쳐 그려도 읽을 수 있는 선의 개수.
///
/// 이 숫자는 보기 좋으라고 정한 값이 아니다. 선이 이보다 많아지면 눈금 범위가
/// 가장 큰 값에 맞춰 늘어나 온도처럼 좁은 범위의 값은 바닥에 눌려 평평해지고,
/// 색도 서로 구별되지 않는다. 그래서 자동 선택은 여기서 멈추고, 더 보려면
/// 사용자가 직접 켠다.
const int readableSeriesLimit = 6;

/// 차트 위에 붙는 범례. 어떤 선이 어떤 항목인지 차트 안에서 바로 알 수 있게 한다.
/// 색 표시만으로는 부족하므로 선 모양(실선/파선/점선)도 함께 그린다.
class _ChartLegend extends StatelessWidget {
  final List<String> names;
  final List<List<int>?> dashes;
  final List<Color> colors;

  const _ChartLegend({
    required this.names,
    required this.dashes,
    required this.colors,
  });

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
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
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
        canvas.drawLine(
          Offset(x, y),
          Offset((x + len).clamp(0, size.width), y),
          paint,
        );
      }
      x += len;
      i++;
    }
  }

  @override
  bool shouldRepaint(_LegendLinePainter old) =>
      old.color != color || old.dash != dash;
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
        final double? statusVal = p.containsKey('status')
            ? (p['status'] == true ? 1.0 : 0.0)
            : null;

        final double? value = mean ?? statusVal;
        if (value != null) {
          sum += value;
          count++;
        }
        if (pMin != null) {
          minVal = (minVal == null) ? pMin : (pMin < minVal ? pMin : minVal);
        }
        if (pMax != null) {
          maxVal = (maxVal == null) ? pMax : (pMax > maxVal ? pMax : maxVal);
        }
        if (statusVal != null) {
          minVal = (minVal == null)
              ? statusVal
              : (statusVal < minVal ? statusVal : minVal);
          maxVal = (maxVal == null)
              ? statusVal
              : (statusVal > maxVal ? statusVal : maxVal);
        }
      }

      if (count == 0 && minVal == null) continue;

      stats.add(
        _SeriesStat(
          name: _seriesLabel(context, ds, i),
          color:
              context.colors.chartSeries[i % context.colors.chartSeries.length],
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
                      decoration: BoxDecoration(
                        color: s.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
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
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label ${value != null ? value.toStringAsFixed(1) : '-'}',
        style: TextStyle(
          fontSize: 12,
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
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

  _SeriesStat({
    required this.name,
    required this.color,
    this.min,
    this.avg,
    this.max,
  });
}

/// Box #3: 차트 렌더링 캔버스 영역
class ChartCanvasBox extends StatelessWidget {
  final Map<String, dynamic>? chartData;
  final bool isLoading;
  final bool showTargetLines;

  const ChartCanvasBox({
    super.key,
    required this.chartData,
    required this.isLoading,
    this.showTargetLines = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildContainer(
        context,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (chartData == null ||
        chartData!['data']['datasets'] == null ||
        (chartData!['data']['datasets'] as List).isEmpty) {
      return _buildContainer(
        context,
        child: Center(
          child: Text(
            context.l10n.chartNoData,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
          ),
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

    // 고른 항목인데 기간 안에 기록이 하나도 없는 것들. 예전에는 그냥 안 그려져서,
    // 사용자는 왜 아무 일도 일어나지 않는지 알 수 없었다.
    final List<String> emptySeries = [];

    for (int i = 0; i < datasets.length; i++) {
      final ds = datasets[i];
      final List<dynamic> dataPoints = ds['data'];
      List<FlSpot> spots = [];
      final Color seriesColor = colors[i % colors.length];

      // 켜짐/꺼짐 값은 그 사이를 부드럽게 잇는 곡선으로 그리면 안 된다.
      // 중간값이 존재하지 않는데도 0.4 쯤을 지나는 것처럼 보인다.
      final bool isSwitchSeries =
          dataPoints.isNotEmpty && (dataPoints.first as Map).containsKey('status');

      // target_value, target_low_limit 등은 Null일 수 있으므로 파싱 방어 추가.
      // 데이터 자체 범위와 무관하게 "안전 기준선"을 그리는 데 사용한다.
      final String? rawLow = ds['target_low_limit'];
      final String? rawHigh = ds['target_high_limit'];
      final double? targetLow = rawLow != null ? double.tryParse(rawLow) : null;
      final double? targetHigh = rawHigh != null
          ? double.tryParse(rawHigh)
          : null;

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

      if (spots.isEmpty) {
        emptySeries.add(_seriesLabel(context, ds, i));
      }

      if (spots.isNotEmpty) {
        // 색만으로 시리즈를 구분하면 색각 이상이나 흑백 출력(포스터·인쇄)에서 구분이 안 된다.
        // 실선/파선/점선을 함께 돌려 색 없이도 구분되게 한다.
        seriesNames.add(_seriesLabel(context, ds, i));
        final dash = _seriesDashPatterns[i % _seriesDashPatterns.length];
        seriesDashes.add(dash);

        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: !isSwitchSeries,
            isStepLineChart: isSwitchSeries,
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
            targetLines.add(
              _targetLine(
                targetLow,
                seriesColor,
                context.l10n.chartLowerLimit(targetLow.toStringAsFixed(1)),
              ),
            );
            if (targetLow < minY) minY = targetLow;
            if (targetLow > maxY) maxY = targetLow;
          }
          if (targetHigh != null) {
            targetLines.add(
              _targetLine(
                targetHigh,
                seriesColor,
                context.l10n.chartUpperLimit(targetHigh.toStringAsFixed(1)),
              ),
            );
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
        final DateTime? ts = DateTime.tryParse(
          a['timestamp']?.toString() ?? '',
        )?.toLocal();
        if (ts == null) continue;
        final double x = ts.millisecondsSinceEpoch.toDouble();
        if (x < minX || x > maxX) continue;
        final String name = alarmDisplayName(context, a['alarm_name']);
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
              style: TextStyle(
                fontSize: 12,
                color: context.colors.error,
                fontWeight: FontWeight.w700,
              ),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.chartNoValidData,
                style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
              ),
              if (emptySeries.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    context.l10n.chartNoRecordsFor(emptySeries.join(', ')),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return _buildContainer(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChartLegend(
            names: seriesNames,
            dashes: seriesDashes,
            colors: colors,
          ),
          // 그려진 것이 있어도, 고른 항목 중 기록이 없는 게 있으면 말해 준다.
          // 말하지 않으면 사용자는 그 항목을 껐다 켜기만 반복하게 된다.
          if (emptySeries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                context.l10n.chartNoRecordsFor(emptySeries.join(', ')),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
              ),
            ),
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
                      getTooltipColor: (_) => context.colors.isDark
                          ? context.colors.background
                          : const Color(0xFF2B3843),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final dt = DateTime.fromMillisecondsSinceEpoch(
                            spot.x.toInt(),
                          );
                          final timeStr = DateFormat('MM-dd HH:mm').format(dt);
                          // 여러 선이 겹칠 때 어느 시리즈의 값인지 알 수 없어 이름을 함께 보여준다.
                          final name = spot.barIndex < seriesNames.length
                              ? seriesNames[spot.barIndex]
                              : '';
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
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: context.colors.outline, strokeWidth: 1),
                    getDrawingVerticalLine: (value) =>
                        FlLine(color: context.colors.outline, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value == minX || value == maxX) {
                            return const SizedBox.shrink();
                          }
                          final dt = DateTime.fromMillisecondsSinceEpoch(
                            value.toInt(),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('HH:mm').format(dt),
                              style: TextStyle(
                                fontSize: 11,
                                color: context.colors.textSecondary,
                              ),
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
                            style: TextStyle(
                              fontSize: 11,
                              color: context.colors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: targetLines,
                    verticalLines: alarmLines,
                  ),
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
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w700,
        ),
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
/// 차트 위에 안전 범위 선을 겹쳐 그릴지 고르는 자리.
///
/// 예전에는 '탐색 도구' 라는 이름으로 아이콘 네 개가 오른쪽에 몰려 있었는데,
/// 그중 실제로 동작하는 건 하나뿐이었다. 이동·메모는 아예 비활성이었고
/// 새로고침은 빈 함수(onPressed: () {})라 눌러도 아무 일이 없었다. 무엇을 하는
/// 단추인지도 아이콘만 봐서는 알 수 없었다.
///
/// 되는 것 하나만 남기고, 이름과 설명을 붙였다.
class ChartToolBox extends StatelessWidget {
  final bool showTargetLines;
  final ValueChanged<bool> onToggleTargetLines;

  /// 지금 그려진 시리즈. 상·하한이 하나도 없으면 켜도 달라지는 게 없으므로
  /// 그 사실을 알려 준다 — 눌러도 아무 일이 없는 이유가 바로 이것이었다.
  final Map<String, dynamic>? chartData;

  /// 기준값을 직접 넣는 창을 여는 손잡이. 자주 쓸 자리가 아니라서 작은
  /// 글자 버튼 하나로만 내보낸다 — 평소에는 눈에 걸리지 않아야 한다.
  final VoidCallback? onEditLimits;

  const ChartToolBox({
    super.key,
    required this.showTargetLines,
    required this.onToggleTargetLines,
    this.chartData,
    this.onEditLimits,
  });

  /// 실제로 기준선이 그려질 항목이 있는지.
  ///
  /// 상·하한이 정해져 있어도 그 기간에 기록이 없으면 선은 그려지지 않는다
  /// (차트가 점이 있는 시리즈에만 기준선을 붙인다). 그래서 둘 다 본다 —
  /// 켤 수는 있는데 아무 일도 일어나지 않는 상태를 만들지 않기 위해서다.
  bool get _hasAnyLimit {
    final datasets = chartData?['data']?['datasets'];
    if (datasets is! List) return false;

    return datasets.any((ds) {
      if (ds is! Map) return false;
      final hasLimit = ds['target_low_limit'] != null || ds['target_high_limit'] != null;
      final points = ds['data'];
      return hasLimit && points is List && points.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final usable = _hasAnyLimit;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: colors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.chartSafeRangeTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: usable ? colors.textPrimary : colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  usable
                      ? context.l10n.chartSafeRangeHint
                      : context.l10n.chartSafeRangeNone,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.3),
                ),
                if (onEditLimits != null) ...[
                  const SizedBox(height: 2),
                  // 밑줄 친 작은 글자 하나. 버튼처럼 칠해 두면 이 카드에서
                  // 제일 먼저 눈에 들어오는데, 실제로는 거의 쓰지 않는 길이다.
                  InkWell(
                    onTap: onEditLimits,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        context.l10n.chartLimitsEdit,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.textSecondary,
                          decoration: TextDecoration.underline,
                          decorationColor: colors.textSecondary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: showTargetLines && usable,
            onChanged: usable ? onToggleTargetLines : null,
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

  /// 제목 줄을 눌러 카드를 접고 펼 수 있게 한다.
  final VoidCallback? onHeaderTap;

  /// 접혀 있을 때 제목 아래에 붙는 한 줄. 열어 보지 않아도 지금 무엇이
  /// 선택돼 있는지 알 수 있어야 접어 두는 의미가 있다.
  final String? headerSummary;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
    this.onHeaderTap,
    this.headerSummary,
  });

  @override
  Widget build(BuildContext context) {
    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textSecondary,
                ),
              ),
              if (headerSummary != null) ...[
                const SizedBox(height: 4),
                Text(
                  headerSummary!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.colors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 제목 줄 전체가 손가락에 닿아야 한다. 화살표만 누를 수 있으면
          // 접히는 카드인 줄 모른다.
          if (onHeaderTap != null)
            InkWell(
              onTap: onHeaderTap,
              child: Padding(padding: const EdgeInsets.all(16), child: header),
            )
          else
            Padding(padding: const EdgeInsets.all(16), child: header),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              onHeaderTap != null ? 0 : 16,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
