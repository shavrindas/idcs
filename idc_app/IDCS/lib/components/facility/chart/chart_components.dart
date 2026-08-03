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
  final String currentDataType;
  final String currentScale;
  final String currentTimeRange;
  final Function(String) onDataTypeChanged;
  final Function(String) onScaleChanged;
  final Function(String) onTimeRangeChanged;
  final VoidCallback onApply;

  const ChartFilterBox({
    super.key,
    required this.currentDataType,
    required this.currentScale,
    required this.currentTimeRange,
    required this.onDataTypeChanged,
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
          // 1행: 데이터 타입 & 해상도
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: currentDataType,
                  isExpanded: true, // 💡 자식 위젯 오버플로우 방지
                  decoration: const InputDecoration(
                    labelText: '데이터 타입',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'temp', child: Text('온도', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'gear', child: Text('장비 수치', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'static', child: Text('정적 장비', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'bool', child: Text('상태/이상(Bool)', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) { if (val != null) onDataTypeChanged(val); },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: currentScale,
                  isExpanded: true, // 💡 자식 위젯 오버플로우 방지
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
            ],
          ),
          const SizedBox(height: 8),
          // 2행: 조회 기간 & 적용 버튼
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: currentTimeRange,
                  isExpanded: true, // 💡 자식 위젯 오버플로우 방지
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

    // 1. 데이터 파싱 및 척도 계산
    final String dataType = chartData!['meta']['data_type'];
    final List<dynamic> datasets = chartData!['data']['datasets'];

    List<LineChartBarData> lineBars = [];
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    // 시리즈별 컬러 팔레트
    final List<Color> colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal
    ];

    for (int i = 0; i < datasets.length; i++) {
      final ds = datasets[i];
      final List<dynamic> dataPoints = ds['data'];
      List<FlSpot> spots = [];

      for (var point in dataPoints) {
        // 타임스탬프를 X축 좌표(Milliseconds)로 변환
        final DateTime dt = DateTime.parse(point['timestamp']).toLocal();
        final double x = dt.millisecondsSinceEpoch.toDouble();

        double y = 0.0;
        if (dataType == 'temp' || dataType == 'gear' || dataType == 'static') {
          y = (point['mean'] as num?)?.toDouble() ?? 0.0;
        } else if (dataType == 'bool') {
          y = point['status'] == true ? 1.0 : 0.0;
        }

        spots.add(FlSpot(x, y));

        // 차트 축 한계선 갱신
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }

      if (spots.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: true, // 곡선 처리
            color: colors[i % colors.length],
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false), // 기본 점 숨김 (성능 및 가시성)
            belowBarData: BarAreaData(show: false),
          ),
        );
      }
    }

    // 데이터가 점 1개뿐이거나 모든 값이 동일할 때의 Y축 여백(Padding) 예외 처리
    if (minY == double.infinity || maxY == -double.infinity) {
      minY = 0; maxY = 10;
    } else if (minY == maxY) {
      minY -= 5; maxY += 5;
    } else {
      final padding = (maxY - minY) * 0.1; // 상하 10% 여백
      minY -= padding; maxY += padding;
    }

    // 예외 처리: 데이터가 비어있을 때
    if (lineBars.isEmpty) {
      return _buildContainer(child: const Center(child: Text('유효한 그래프 데이터가 없습니다.')));
    }

    // 2. 렌더링
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
                  // 터치(툴팁) 설정
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
                  // 격자선 설정
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) => const FlLine(color: Colors.black12, strokeWidth: 1),
                    getDrawingVerticalLine: (value) => const FlLine(color: Colors.black12, strokeWidth: 1),
                  ),
                  // 축 타이틀 설정
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          // 최소, 최대 X값에 가까운 라벨은 겹침 방지를 위해 스킵
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