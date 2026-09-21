// ===============================================================
// 경로: lib/components/facility/chart/chart_components.dart
// 명세: 차트 시각화를 위한 화면 분할 Box 컴포넌트
// ===============================================================
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:idcs/theme/app_theme.dart';

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

  const ChartFilterBox({
    super.key,
    required this.currentScale,
    required this.currentTimeRange,
    required this.onScaleChanged,
    required this.onTimeRangeChanged,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '조회 조건',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: currentScale,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '해상도'),
              items: const [
                DropdownMenuItem(value: '10s', child: Text('10초 단위', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: '1m', child: Text('1분 단위', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: '5m', child: Text('5분 단위', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: '1h', child: Text('1시간 단위', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (val) { if (val != null) onScaleChanged(val); },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: currentTimeRange,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '조회 기간'),
              items: const [
                DropdownMenuItem(value: '1h', child: Text('최근 1시간', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: '12h', child: Text('최근 12시간', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: '1d', child: Text('최근 1일', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: '7d', child: Text('최근 7일', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: '15d', child: Text('최근 15일', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (val) { if (val != null) onTimeRangeChanged(val); },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 58,
            child: ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18)),
              child: const Text('적용'),
            ),
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

  const ChartSeriesBox({
    super.key,
    required this.availableGroups,
    required this.selectedGroupId,
    required this.onGroupSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '데이터 그룹',
      child: availableGroups.isEmpty
          ? const Text('등록된 그룹이 없습니다.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
          : Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: availableGroups.map((group) {
                final isSelected = selectedGroupId == group['group_id'];
                return ChoiceChip(
                  label: Text(group['group_name']),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    if (selected) onGroupSelected(group['group_id']);
                  },
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.outline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                );
              }).toList(),
            ),
    );
  }
}

/// 시리즈 색상 팔레트. 통계 박스와 캔버스가 같은 순서로 순회하므로 항상 같은 색이 매칭된다.
const List<Color> chartSeriesColors = [
  AppColors.primary, AppColors.error, AppColors.success, AppColors.warning, AppColors.primaryDark, Colors.teal,
];

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

      stats.add(_SeriesStat(
        name: ds['display_name'] ?? ds['role_name'] ?? '시리즈 ${i + 1}',
        color: chartSeriesColors[i % chartSeriesColors.length],
        min: minVal,
        avg: count > 0 ? sum / count : null,
        max: maxVal,
      ));
    }

    if (stats.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: '구간 요약',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: stats.map((s) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
              ),
              _statChip('최소', s.min),
              const SizedBox(width: 6),
              _statChip('평균', s.avg),
              const SizedBox(width: 6),
              _statChip('최대', s.max),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _statChip(String label, double? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
      child: Text(
        '$label ${value != null ? value.toStringAsFixed(1) : '-'}',
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
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

  const ChartCanvasBox({
    super.key,
    required this.chartData,
    required this.isLoading,
    this.showTargetLines = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildContainer(child: const Center(child: CircularProgressIndicator()));
    }

    if (chartData == null || chartData!['data']['datasets'] == null || (chartData!['data']['datasets'] as List).isEmpty) {
      return _buildContainer(
        child: const Center(
          child: Text('조회된 데이터가 없습니다.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
      );
    }

    // [수정] 백엔드에서 data_type을 제거했으므로 해당 변수 추출(String dataType = ...) 구문을 삭제했습니다.
    final List<dynamic> datasets = chartData!['data']['datasets'];
    final List<dynamic> alarms = chartData!['data']['alarms'] ?? [];

    List<LineChartBarData> lineBars = [];
    List<HorizontalLine> targetLines = [];
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    final List<Color> colors = chartSeriesColors;

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
        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: seriesColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        );

        if (showTargetLines) {
          if (targetLow != null) {
            targetLines.add(_targetLine(targetLow, seriesColor, '하한 ${targetLow.toStringAsFixed(1)}'));
            if (targetLow < minY) minY = targetLow;
            if (targetLow > maxY) maxY = targetLow;
          }
          if (targetHigh != null) {
            targetLines.add(_targetLine(targetHigh, seriesColor, '상한 ${targetHigh.toStringAsFixed(1)}'));
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
        final String name = a['alarm_name']?.toString() ?? '알람';
        alarmLines.add(
          VerticalLine(
            x: x,
            color: AppColors.error.withValues(alpha: 0.7),
            strokeWidth: 1.5,
            dashArray: [4, 4],
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              style: const TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w700),
              labelResolver: (line) => name,
            ),
          ),
        );
      }
    }

    if (minY == double.infinity || maxY == -double.infinity) {
      minY = 0; maxY = 10;
    } else if (minY == maxY) {
      minY -= 5; maxY += 5;
    } else {
      final padding = (maxY - minY) * 0.1;
      minY -= padding; maxY += padding;
    }

    if (lineBars.isEmpty) {
      return _buildContainer(
        child: const Center(child: Text('유효한 그래프 데이터가 없습니다.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
      );
    }

    return _buildContainer(
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
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final dt = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                    final timeStr = DateFormat('MM-dd HH:mm').format(dt);
                    return LineTooltipItem(
                      '$timeStr\n${spot.y.toStringAsFixed(1)}',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  }).toList();
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.outline, strokeWidth: 1),
              getDrawingVerticalLine: (value) => const FlLine(color: AppColors.outline, strokeWidth: 1),
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
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
        labelResolver: (line) => label,
      ),
    );
  }

  // 차트 캔버스는 화면의 핵심 콘텐츠이므로 주변 설정 카드보다 한 단계 부각시킨다.
  Widget _buildContainer({required Widget child}) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.soft,
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

  const ChartToolBox({
    super.key,
    required this.showTargetLines,
    required this.onToggleTargetLines,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '탐색 도구',
      child: Row(
        children: [
          const Spacer(),
          IconButton(icon: const Icon(Icons.pan_tool_outlined, color: AppColors.textSecondary), onPressed: null, tooltip: '이동 (비활성)'),
          IconButton(
            icon: Icon(
              Icons.show_chart_rounded,
              color: showTargetLines ? AppColors.primary : AppColors.textSecondary,
            ),
            onPressed: () => onToggleTargetLines(!showTargetLines),
            tooltip: showTargetLines ? '기준선 숨기기' : '기준선 표시',
          ),
          IconButton(icon: const Icon(Icons.text_fields_rounded, color: AppColors.textSecondary), onPressed: null, tooltip: '메모 (비활성)'),
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.primary), onPressed: () {}, tooltip: '시점 초기화'),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
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
