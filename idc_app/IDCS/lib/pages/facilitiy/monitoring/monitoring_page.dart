import 'package:flutter/material.dart';
import 'package:idcs/components/facilitiy/monitoring/monitoring.dart';
import 'package:idcs/main.dart';
import 'dart:convert';
import 'dart:async';
import 'package:idcs/services/common/web_socket_service.dart';
import 'package:idcs/main.dart';

class MonitoringPage extends StatefulWidget {
  final String userId;
  final String facilityId;
  final String roomId;

  const MonitoringPage({super.key, required this.userId, required this.facilityId, required this.roomId});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  // 웹소켓 통신 클래스 인스턴스 생성
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription<String>? _wsSubscription; // 스트림 구독 해제를 위한 객체

  // 평평한 1층 딕셔너리 데이터 구조
  late Map<String, String> infoData;
  Map<String, String> realtempData = {'현재 온도': 'NA', '설정 온도': 'NA', '편차': 'NA', '영점': 'NA', '컴프레셔': 'NA'};
  Map<String, String> deforestData = {'제상 주기': 'NA', '제상 시간': 'NA', '제상 타이머': 'NA', '제상 종료 타이머': 'NA', '제상 가동 중': 'NA', '수동 제상': 'NA'};
  Map<String, String> emergencyData = {'이상': 'NA', 'C.INT_EOCR': 'NA', '고압': 'NA', '팬 이상': 'NA', '감금알람': 'NA', '압력센서이상': 'NA', '온도센서이상': 'NA', '컴프레셔 과열': 'NA', '컴프레셔 저압': 'NA', '컴프레셔 역회전': 'NA', '인버터 이상': 'NA'};
  Map<String, String> inverterData = {'전류량': 'NA', '전압': 'NA', '입력 전압': 'NA', '출력 전압': 'NA', '설정 회전수': 'NA', '실제 회전수': 'NA'};
  Map<String, String> equipmentData = {'팽창변 가동': 'NA', '팽창변 가동2': 'NA', '팽창변 가동3': 'NA', '컴프레셔1호 온도': 'NA', '컴프레셔1호 압력(입력)': 'NA', '컴프레셔1호 압력(출력)': 'NA','컴프레셔2호 온도': 'NA', '컴프레셔2호 압력(입력)': 'NA', '컴프레셔2호 압력(출력)': 'NA', '열 교환기 온도': 'NA',  '물탱크 온도': 'NA'};
  Map<String, String> controlData = {'운전 상태': 'NA', '운전 시간': 'NA', '컴프레셔 가동시간': 'NA', '운전 지연': 'NA', '컴프레셔 지연': 'NA', '제상 지연': 'NA', '쿨러 지연': 'NA', '아날로그 운전': 'NA', '아날로그 온도계 사용': 'NA', '제상 과열': 'NA'};

  // 디바이스 수신 키 ➔ 앱 내부 딕셔너리 키 매핑 사전
  static const Map<String, String> deviceKeyMap = {
    'temppv': '현재 온도',
    'tempsv': '설정 온도',
    'temphey': '편차',
    'tempzero': '영점',
    'comp': '컴프레셔',
    'def': '제상 가동 중',
    'emg': '이상',
    'DFC': '제상 주기',
    'DFT': '제상 시간',
    'SYSH': '제상 타이머',
    'SYSM': '제상 종료 타이머',
    'runsw': '운전 상태',
    'runtime': '운전 시간',
    'cruntime': '컴프레셔 가동시간',
    'rundel': '운전 지연',
    'compdel': '컴프레셔 지연',
    'cooldel': '쿨러 지연',
    'defdel': '제상 지연',
    'comp1temp': '컴프레셔1호 온도',
    'comp1press1': '컴프레셔1호 압력(입력)',
    'comp1press2': '컴프레셔1호 압력(출력)',
    'comp2temp': '컴프레셔2호 온도',
    'comp2press1': '컴프레셔2호 압력(입력)',
    'comp2press2': '컴프레셔2호 압력(출력)',
    'transtemp': '열 교환기 온도',
    'emg_cinteocr': 'C.INT_EOCR',
    'emg_high': '고압',
    'emg_fan': '팬 이상',
    'emg_lock': '감금알람',
    'emg_press': '압력센서이상',
    'emp_temp': '온도센서이상',
    'emp_hot': '컴프레셔 과열',
    'emp_low': '컴프레셔 저압',
    'emp_rotation': '컴프레셔 역회전',
    'emp_inv': '인버터 이상',
    'expan': '팽창변 가동',
    'expan2': '팽창변 가동2',
    'expan3': '팽창변 가동3',
    'lsv': '아날로그 운전',
    'rtc': '아날로그 온도계 사용',
    'dth': '제상 과열'
  };

  @override
  void initState() {
    super.initState();
    infoData = {
      '시설 ID': widget.facilityId,
      '호실 ID': widget.roomId,
      '담당 관리자 ID': widget.userId,
      '운영 상태': '정상 작동 중 (ACTIVE)',
    };

    // 💡 [핵심] 페이지 진입 시 웹소켓 서비스 연결 및 스트림 구독 시작
    _webSocketService.connect('${AppConfig.basewsUrl}/facilities/data/get/${widget.facilityId}');

    // 서비스 내부에서 데이터가 들어올 때마다 매핑 함수를 작동시킴
    _wsSubscription = _webSocketService.messageStream.listen((rawJson) {
      _parseAndMapDeviceMessage(rawJson);
    });
  }

  // 통신 클래스로부터 넘겨받은 날것의 데이터를 매핑하는 비즈니스 로직
  void _parseAndMapDeviceMessage(String rawJsonString) {
    try {
      final Map<String, dynamic> parsedJson = jsonDecode(rawJsonString);

      setState(() {
        for (var entry in parsedJson.entries) {
          // 방법 1 적용 예시 (키 조립)
          final List<String> parts = entry.key.split('.');

          if(int.parse(widget.roomId) != int.parse(parts[0]))
            continue;

          final String? appKey = deviceKeyMap[parts[1]];

          if (appKey != null) {
            final String newValue = entry.value.toString();
            if (realtempData.containsKey(appKey)) {
              realtempData[appKey] = newValue;
            } else if(deforestData.containsKey(appKey)) {
              deforestData[appKey] = newValue;
            } else if(emergencyData.containsKey(appKey)) {
              emergencyData[appKey] = newValue;
            } else if(inverterData.containsKey(appKey)) {
              inverterData[appKey] = newValue;
            } else if(equipmentData.containsKey(appKey)) {
              equipmentData[appKey] = newValue;
            } else if(controlData.containsKey(appKey)) {
              controlData[appKey] = newValue;
            }
          }
        }
      });
    } catch (e) {
      print('에러: $e');
    }
  }

  @override
  void dispose() {
    // 💡 매우 중요: 메모리 누수 방지를 위해 페이지를 나갈 때 스트림 구독을 해제하고 통신을 닫습니다.
    _wsSubscription?.cancel();
    _webSocketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('시설 ID: ${widget.facilityId} 실시간 제어판'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MonitoringCard(title: '시설 기본 정보', fields: infoData),
            MonitoringCard(title: '실제 온도', fields: realtempData),
            MonitoringCard(title: '제상 정보', fields: deforestData),
            MonitoringCard(title: '이상 정보', fields: emergencyData),
            MonitoringCard(title: '인버터 정보', fields: inverterData),
            MonitoringCard(title: '장비 정보', fields: equipmentData),
            MonitoringCard(title: '제어 정보', fields: controlData),
          ],
        ),
      ),
    );
  }
}