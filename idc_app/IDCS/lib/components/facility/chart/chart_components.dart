// ===============================================================
// 경로: lib/components/facility/chart/chart_components.dart
// 명세: 차트 시각화를 위한 화면 분할 Box 컴포넌트
// ===============================================================
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:idcs/theme/app_theme.dart';

/// Box #1: 차트 검색 스코프 박스 (명시적 기간 설정)
class ChartSearchScopeBox extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;
  final String autoScale; // 자동 계산된 단위를 보여주기 위함
  final VoidCallback onSelectStartTime;
  final VoidCallback onSelectEndTime;
  final VoidCallback onSearch;

  const ChartSearchScopeBox({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.autoScale,
    required this.onSelectStartTime,
    required this.onSelectEndTime,
    required this.onSearch,
  });

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '조회 기간',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '단위: $autoScale',
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onSelectStartTime,
              icon: const Icon(Icons.calendar_today_outlined, size: 15),
              label: Text(_formatDate(startTime), style: const TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('~', style: TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onSelectEndTime,
              icon: const Icon(Icons.calendar_today_outlined, size: 15),
              label: Text(_formatDate(endTime), style: const TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: onSearch,
              style: ElevatedButton.styleFrom(minimumSize: const Size(64, 44)),
              child: const Text('검색'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Box #2: 데이터 포인트(시리즈) 선택 박스
class ChartSeriesBox extends StatelessWidget {
  final List<Map<String, dynamic>> availableGroups;
  final int? selectedGroupId;
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

/// Box #3: 차트 렌더링 캔버스 영역
class ChartCanvasBox extends StatefulWidget {
  final Map<String, dynamic>? chartData;
  final bool isLoading;
  final bool isPanMode;
  // 검색 기준 시간을 직접 받아와서 축을 고정시킴
  final DateTime searchedStartTime;
  final DateTime searchedEndTime;

  const ChartCanvasBox({
    super.key,
    required this.chartData,
    required this.isLoading,
    required this.searchedStartTime,
    required this.searchedEndTime,
    this.isPanMode = true,
  });

  @override
  State<ChartCanvasBox> createState() => ChartCanvasBoxState();
}

class ChartCanvasBoxState extends State<ChartCanvasBox> {
  double? _currentMinX;
  double? _currentMaxX;

  late double _baseMinX;
  late double _baseMaxX;

  double _lastMinX = 0;
  double _lastMaxX = 0;
  double _startFocalPoint = 0;

  void resetViewport() {
    setState(() {
      _currentMinX = _baseMinX;
      _currentMaxX = _baseMaxX;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculateBaseBounds();
  }

  @override
  void didUpdateWidget(covariant ChartCanvasBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchedStartTime != oldWidget.searchedStartTime ||
        widget.searchedEndTime != oldWidget.searchedEndTime ||
        widget.chartData != oldWidget.chartData) {
      _calculateBaseBounds();
    }
  }

  void _calculateBaseBounds() {
    // 데이터 속 포인트 시간과 무관하게 검색 기간으로 X축 영역을 완벽히 고정
    _baseMinX = widget.searchedStartTime.millisecondsSinceEpoch.toDouble();
    _baseMaxX = widget.searchedEndTime.millisecondsSinceEpoch.toDouble();

    _currentMinX = _baseMinX;
    _currentMaxX = _baseMaxX;
  }

  static const List<Color> _seriesColors = [
    AppColors.primary,
    Color(0xFFE0575B),
    Color(0xFF2FAE66),
    Color(0xFFE0A32E),
    Color(0xFF9B6BEA),
    Color(0xFF16A6A6),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildContainer(child: const Center(child: CircularProgressIndicator()));
    }

    // 데이터가 없어도 에러 메시지를 띄우지 않고 빈 배열로 그리드를 그려주기 위해 안전하게 호출
    final List<dynamic> datasets = widget.chartData?['data']?['datasets'] ?? [];
    List<LineChartBarData> lineBars = [];

    double minY = double.infinity;
    double maxY = -double.infinity;

    for (int i = 0; i < datasets.length; i++) {
      final ds = datasets[i];
      final List<dynamic> dataPoints = ds['data'] ?? [];
      List<FlSpot> spots = [];

      for (var point in dataPoints) {
        final DateTime dt = DateTime.parse(point['timestamp']).toLocal();
        final double x = dt.millisecondsSinceEpoch.toDouble();

        double y = 0.0;
        if (point.containsKey('mean')) {
          y = (point['mean'] as num?)?.toDouble() ?? 0.0;
        } else if (point.containsKey('status')) {
          y = point['status'] == true ? 1.0 : 0.0;
        }

        spots.add(FlSpot(x, y));
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }

      if (spots.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _seriesColors[i % _seriesColors.length],
            barWidth: 2.4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        );
      }
    }

    // 데이터가 없어 무한대일 경우 기본 Y축 설정 (빈 공간 렌더링용)
    if (minY == double.infinity || maxY == -double.infinity) {
      minY = 0; maxY = 10;
    } else if (minY == maxY) {
      minY -= 5; maxY += 5;
    } else {
      final padding = (maxY - minY) * 0.1;
      minY -= padding; maxY += padding;
    }

    Widget chartWidget = LineChart(
      LineChartData(
        minX: _currentMinX ?? _baseMinX,
        maxX: _currentMaxX ?? _baseMaxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: lineBars,
        clipData: const FlClipData.all(),
        lineTouchData: LineTouchData(
          enabled: !widget.isPanMode,
          handleBuiltInTouches: !widget.isPanMode,
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
                // 시작/종료 축에는 텍스트가 잘리지 않도록 비움
                if (value == _baseMinX || value == _baseMaxX) return const SizedBox.shrink();
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
        borderData: FlBorderData(show: true, border: Border.all(color: AppColors.outline)),
      ),
    );

    if (widget.isPanMode) {
      chartWidget = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: (details) {
          _lastMinX = _currentMinX ?? _baseMinX;
          _lastMaxX = _currentMaxX ?? _baseMaxX;
          _startFocalPoint = details.localFocalPoint.dx;
        },
        onScaleUpdate: (details) {
          setState(() {
            final double range = _lastMaxX - _lastMinX;
            final double scale = details.scale;

            final double dx = details.localFocalPoint.dx - _startFocalPoint;
            final double timeShift = (range / 350) * dx;

            double newMinX = _lastMinX - timeShift;
            double newMaxX = _lastMaxX - timeShift;

            if (scale != 1.0) {
              final double newRange = range / scale;
              final double diff = (range - newRange) / 2;
              newMinX += diff;
              newMaxX -= diff;
            }

            if (newMinX < _baseMinX) {
              newMaxX += (_baseMinX - newMinX);
              newMinX = _baseMinX;
            }
            if (newMaxX > _baseMaxX) {
              newMinX -= (newMaxX - _baseMaxX);
              newMaxX = _baseMaxX;
            }
            if (newMinX < _baseMinX) newMinX = _baseMinX;
            if (newMaxX < newMinX + 60000) newMaxX = newMinX + 60000;

            _currentMinX = newMinX;
            _currentMaxX = newMaxX;
          });
        },
        child: chartWidget,
      );
    }

    return _buildContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                widget.isPanMode ? '탐색 모드' : '툴팁 모드',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 8.0),
              child: chartWidget,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      padding: const EdgeInsets.all(16.0),
      child: child,
    );
  }
}

/// Box #4: 차트 도구 박스 (제어 및 어노테이션 도구)
class ChartToolBox extends StatelessWidget {
  final bool isPanMode;
  final VoidCallback onTogglePanMode;
  final VoidCallback onResetViewport;

  const ChartToolBox({
    super.key,
    required this.isPanMode,
    required this.onTogglePanMode,
    required this.onResetViewport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(Icons.pan_tool_alt_outlined, color: isPanMode ? AppColors.primary : AppColors.textSecondary),
            onPressed: onTogglePanMode,
            tooltip: '이동 및 확대 모드',
          ),
          IconButton(
            icon: const Icon(Icons.show_chart_rounded, color: AppColors.textSecondary),
            onPressed: null,
            tooltip: '기준선 (비활성)',
          ),
          IconButton(
            icon: const Icon(Icons.text_fields_rounded, color: AppColors.textSecondary),
            onPressed: null,
            tooltip: '메모 (비활성)',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            onPressed: onResetViewport,
            tooltip: '시점 초기화',
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
