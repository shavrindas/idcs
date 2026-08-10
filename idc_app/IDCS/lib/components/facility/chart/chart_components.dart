// ===============================================================
// 경로: lib/components/facility/chart/chart_components.dart
// 명세: 차트 시각화를 위한 화면 분할 Box 컴포넌트
// ===============================================================
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// Box #1: 차트 필터 박스 (해상도 및 조회 기간 설정)
class ChartFilterBox extends StatelessWidget {
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
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Box 1: 데이터 스코프 필터', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: currentScale,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '해상도',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
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
                  decoration: const InputDecoration(
                    labelText: '조회 기간',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
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
              ElevatedButton(
                onPressed: onApply,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: const Text('적용'),
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
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Box 2: 데이터 포인트 그룹 선택', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: availableGroups.map((group) {
              final isSelected = selectedGroupId == group['group_id'];
              return ChoiceChip(
                label: Text(group['group_name']),
                selected: isSelected,
                onSelected: (bool selected) {
                  if (selected) onGroupSelected(group['group_id']);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Box #3: 차트 렌더링 캔버스 영역
class ChartCanvasBox extends StatefulWidget {
  final Map<String, dynamic>? chartData;
  final bool isLoading;
  final bool isPanMode;

  const ChartCanvasBox({
    super.key,
    required this.chartData,
    required this.isLoading,
    this.isPanMode = true,
  });

  @override
  State<ChartCanvasBox> createState() => ChartCanvasBoxState();
}

class ChartCanvasBoxState extends State<ChartCanvasBox> {
  double? _currentMinX;
  double? _currentMaxX;

  double _baseMinX = double.infinity;
  double _baseMaxX = -double.infinity;

  // 줌 제스처용 임시 변수
  double _lastMinX = 0;
  double _lastMaxX = 0;
  double _startFocalPoint = 0; // 💡 시작 좌표 저장 변수 추가

  void resetViewport() {
    setState(() {
      _currentMinX = _baseMinX;
      _currentMaxX = _baseMaxX;
    });
  }

  @override
  void didUpdateWidget(covariant ChartCanvasBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chartData != oldWidget.chartData) {
      _calculateBaseBounds();
    }
  }

  void _calculateBaseBounds() {
    if (widget.chartData == null || widget.chartData!['data']['datasets'] == null) return;

    final List<dynamic> datasets = widget.chartData!['data']['datasets'];
    _baseMinX = double.infinity;
    _baseMaxX = -double.infinity;

    for (var ds in datasets) {
      for (var point in ds['data']) {
        final DateTime dt = DateTime.parse(point['timestamp']).toLocal();
        final double x = dt.millisecondsSinceEpoch.toDouble();
        if (x < _baseMinX) _baseMinX = x;
        if (x > _baseMaxX) _baseMaxX = x;
      }
    }

    _currentMinX = _baseMinX;
    _currentMaxX = _baseMaxX;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildContainer(child: const Center(child: CircularProgressIndicator()));
    }

    if (widget.chartData == null || widget.chartData!['data']['datasets'] == null || (widget.chartData!['data']['datasets'] as List).isEmpty) {
      return _buildContainer(child: const Center(child: Text('조회된 데이터가 없습니다.', style: TextStyle(color: Colors.grey))));
    }

    final List<dynamic> datasets = widget.chartData!['data']['datasets'];
    List<LineChartBarData> lineBars = [];

    double minY = double.infinity;
    double maxY = -double.infinity;
    final List<Color> colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal];

    if (_baseMinX == double.infinity) _calculateBaseBounds();

    for (int i = 0; i < datasets.length; i++) {
      final ds = datasets[i];
      final List<dynamic> dataPoints = ds['data'];
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
            color: colors[i % colors.length],
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
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
      return _buildContainer(child: const Center(child: Text('유효한 그래프 데이터가 없습니다.')));
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
          handleBuiltInTouches: !widget.isPanMode, // 💡 핵심 2: fl_chart가 터치 제스처를 강제로 뺏어가는 현상 완전 차단
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
          getDrawingHorizontalLine: (value) => const FlLine(color: Colors.black12, strokeWidth: 1),
          getDrawingVerticalLine: (value) => const FlLine(color: Colors.black12, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == _baseMinX || value == _baseMaxX) return const SizedBox.shrink();
                final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('HH:mm').format(dt),
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
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
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.black26)),
      ),
    );

    if (widget.isPanMode) {
      chartWidget = GestureDetector(
        behavior: HitTestBehavior.opaque, // 💡 여백 영역 터치 인식 활성화
        onScaleStart: (details) {
          _lastMinX = _currentMinX ?? _baseMinX;
          _lastMaxX = _currentMaxX ?? _baseMaxX;
          _startFocalPoint = details.localFocalPoint.dx; // 💡 핵심 1: 터치 시작점 X좌표 절대값 저장
        },
        onScaleUpdate: (details) {
          setState(() {
            final double range = _lastMaxX - _lastMinX;
            final double scale = details.scale;

            // 💡 시작점 기준 절대 이동 거리(dx) 계산
            final double dx = details.localFocalPoint.dx - _startFocalPoint;

            // 이동 속도/민감도 계산 (대략적인 컨테이너 가로 픽셀을 350으로 산정)
            final double timeShift = (range / 350) * dx;

            double newMinX = _lastMinX - timeShift;
            double newMaxX = _lastMaxX - timeShift;

            if (scale != 1.0) {
              final double newRange = range / scale;
              final double diff = (range - newRange) / 2;
              newMinX += diff;
              newMaxX -= diff;
            }

            // 범위 이탈 방지
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
          Text(
              'Box 3: 차트 캔버스 영역 (${widget.isPanMode ? "탐색 모드" : "툴팁 모드"})',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)
          ),
          const Divider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 16.0),
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
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
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
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          const Text('Box 4: 도구 ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
          const Spacer(),
          IconButton(
              icon: Icon(Icons.pan_tool, color: isPanMode ? Colors.blue : Colors.grey),
              onPressed: onTogglePanMode,
              tooltip: '이동 및 확대 모드'
          ),
          IconButton(icon: const Icon(Icons.show_chart), onPressed: null, tooltip: '기준선 (비활성)'),
          IconButton(icon: const Icon(Icons.text_fields), onPressed: null, tooltip: '메모 (비활성)'),
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: onResetViewport,
              tooltip: '시점 초기화'
          ),
        ],
      ),
    );
  }
}