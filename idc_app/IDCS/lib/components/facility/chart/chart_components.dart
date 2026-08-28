// ===============================================================
// 경로: lib/components/facility/chart/chart_components.dart
// 명세: 차트 시각화를 위한 화면 분할 Box 컴포넌트
// ===============================================================
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';

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
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Box 1: 데이터 스코프 필터', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          const SizedBox(height: 12),

          // [수정: 데이터 타입 종속성 해제]
          // 기존 데이터 타입 선택 드롭다운이 있던 위치입니다.
          // 데이터 타입 구분이 사라졌으므로, 해상도와 조회 기간을 한 줄(Row)로 병합하여 UI를 간소화했습니다.
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

class ChartCanvasBox extends StatelessWidget {
  final Map<String, dynamic>? chartData;
  final bool isLoading;

  const ChartCanvasBox({super.key, required this.chartData, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildContainer(child: const Center(child: CircularProgressIndicator()));
    }

    if (chartData == null || chartData!['data']['datasets'] == null || (chartData!['data']['datasets'] as List).isEmpty) {
      return _buildContainer(child: const Center(child: Text('조회된 데이터가 없습니다.', style: TextStyle(color: Colors.grey))));
    }

    // [수정] 백엔드에서 data_type을 제거했으므로 해당 변수 추출(String dataType = ...) 구문을 삭제했습니다.
    final List<dynamic> datasets = chartData!['data']['datasets'];

    List<LineChartBarData> lineBars = [];
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    final List<Color> colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal
    ];

    for (int i = 0; i < datasets.length; i++) {
      final ds = datasets[i];
      final List<dynamic> dataPoints = ds['data'];
      List<FlSpot> spots = [];

      // [유저 예상 반영] target_value, target_low_limit 등이 Null일 수 있으므로 파싱 방어 추가
      // (이 값들은 향후 어노테이션 배경색을 칠할 때 활용될 예정입니다.)
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

    return _buildContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Box 3: 차트 캔버스 영역', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          const Divider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 16.0),
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
                          if (value == minX || value == maxX) return const SizedBox.shrink();
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
              ),
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
  const ChartToolBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          const Text('Box 4: 도구 ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.pan_tool), onPressed: null, tooltip: '이동 (비활성)'),
          IconButton(icon: const Icon(Icons.show_chart), onPressed: null, tooltip: '기준선 (비활성)'),
          IconButton(icon: const Icon(Icons.text_fields), onPressed: null, tooltip: '메모 (비활성)'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {}, tooltip: '시점 초기화'),
        ],
      ),
    );
  }
}