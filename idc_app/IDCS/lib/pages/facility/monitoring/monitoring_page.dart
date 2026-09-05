import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/facility/monitoring/monitoring.dart';
import 'package:idcs/main.dart';
import 'dart:convert';
import 'dart:async';
import 'package:idcs/services/common/web_socket_service.dart';
import 'package:idcs/services/common/facility_api_service.dart';
import 'package:idcs/components/indices/main_index/main_index_components.dart';

class MonitoringPage extends StatefulWidget {
  final String userId;
  final String facilityId;
  final String roomId;

  const MonitoringPage({super.key, required this.userId, required this.facilityId, required this.roomId});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  bool _isLoading = true;
  List<dynamic> _rooms = [];
  // 웹소켓 통신 클래스 인스턴스 생성
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription<String>? _wsSubscription; // 스트림 구독 해제를 위한 객체

  // 평평한 1층 딕셔너리 데이터 구조
  late Map<String, String> infoData;
  Map<String, String> realtempData = {'H_COMP': 'NA', '고내온도_#1': 'NA', '설정값_#1': 'NA', '편차값_#1': 'NA', 'ZERO_#1': 'NA'};
  Map<String, String> deforestData = {'제상용 전자변': 'NA', '제상타임_#1': 'NA', '싸이클_#1': 'NA', '시스템분_#1': 'NA', '시스템시간_#1': 'NA'};
  Map<String, String> emergencyData = {'CINT': 'NA', 'HIGH': 'NA', 'UF/OCR': 'NA', '감금알람': 'NA', '토출온도이상': 'NA', '가스부족': 'NA', '온도센서이상': 'NA', '역상방지이상': 'NA', 'LOW 스위치': 'NA', '과열TIC': 'NA', 'ARLAM': 'NA', 'RESET': 'NA'};
  Map<String, String> inverterData = {'인버터 에러': 'NA', 'Hz_#1': 'NA', 'KW_#1': 'NA', '출력전압_#1': 'NA', '출력전류_#1': 'NA', '출력주파수_#1': 'NA'};
  Map<String, String> equipmentData = {'토출온도_#1': 'NA', '고압_#1': 'NA', '저압_#1': 'NA'};
  Map<String, String> controlData = {'운전SW': 'NA', '룸온도스위치': 'NA', '방열기 팬 #1': 'NA', '방열기 팬 #2': 'NA', '액 전자변': 'NA', '전자변': 'NA', '쿨러 팬': 'NA', '아날로그TC': 'NA', '쿨러 팬 자동여부': 'NA', '히터정지': 'NA', '초기지연': 'NA', '콤프지연': 'NA', '쿨러지연': 'NA', '수동제상': 'NA', '컴퓨터 S/W': 'NA', '운전시간_#1': 'NA', '운전시간만_#1': 'NA', '초기지연_#1': 'NA', 'H_콤프지연_#1': 'NA', '쿨러지연타임_#1': 'NA', 'DF 지연_#1': 'NA'};
  static const Map<String, String> deviceKeyMap = {
    'control_runsw': '운전SW',
    'emergency_cint': 'CINT',
    'emergency_high': 'HIGH',
    'emergency_uf_ocr': 'UF/OCR',
    'emergency_locked': '감금알람',
    'emergency_outtemp': '토출온도이상',
    'emergency_gas': '가스부족',
    'emergency_tempsensor': '온도센서이상',
    'emergency_defemg': '역상방지이상',
    'emergency_lowsw': 'LOW 스위치',
    'emergency_hottic': '과열TIC',
    'control_roomtemp': '룸온도스위치',
    'temp_comp': 'H_COMP',
    'control_cffan1': '방열기 팬 #1',
    'control_cffan2': '방열기 팬 #2',
    'control_lsv': '액 전자변',
    'control_ingsv': '전자변',
    'control_uffan': '쿨러 팬',
    'deforest_def': '제상용 전자변',
    'emergency_emg': 'ARLAM',
    'control_tica': '아날로그TC',
    'control_efa': '쿨러 팬 자동여부',
    'control_heatdelflag': '히터정지',
    'control_initdelflag': '초기지연',
    'control_compdelflag': '콤프지연',
    'control_coolerdelflag': '쿨러지연',
    'control_mdf': '수동제상',
    'control_sw': '컴퓨터 S/W',
    'emergency_emgreset': 'RESET',
    'inverter_error': '인버터 에러',
    'equipment_temp1': '토출온도_#1',
    'temp_pv': '고내온도_#1',
    'temp_sv': '설정값_#1',
    'temp_hey': '편차값_#1',
    'temp_zero': 'ZERO_#1',
    'equipment_press1': '고압_#1',
    'equipment_press2': '저압_#1',
    'control_runtimelow': '운전시간_#1',
    'control_runtimehigh': '운전시간만_#1',
    'deforest_dfcm': '제상타임_#1',
    'deforest_dfct': '싸이클_#1',
    'deforest_sysm': '시스템분_#1',
    'deforest_syst': '시스템시간_#1',
    'control_initdelst': '초기지연_#1',
    'control_compdelst': 'H_콤프지연_#1',
    'control_cooldelst': '쿨러지연타임_#1',
    'control_defdelst': 'DF 지연_#1',
    'control_initdeltm': '초기지연_#1',
    'control_compdeltm': '콤프지연_#1',
    'control_cooldeltm': '쿨러지연타임_#1',
    'control_defdeltm': 'DF 지연_#1',
    'inverter_hz': 'Hz_#1',
    'inverter_kw': 'KW_#1',
    'inverter_outv': '출력전압_#1',
    'inverter_outa': '출력전류_#1',
    'inverter_outhz': '출력주파수_#1',
  };
  static final Map<String, String> reverseDeviceKeyMap = Map.fromEntries(
    deviceKeyMap.entries.map((entry) => MapEntry(entry.value, entry.key)),
  );

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

    _fetchFacilityData();
  }

  // 1. 유저 데이터(권한 등)를 불러오는 초기화 함수
  Future<void> _fetchFacilityData() async {
    setState(() {
      _isLoading = true; // 로딩 상태 활성화
    });

    try {
      final rooms = await FacilityApiService.getFacilityRooms(widget.facilityId);
      setState(() {
        _rooms = rooms;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('권한 조회 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // 로딩 상태 해제
        });
      }
    }
  }

  // 통신 클래스로부터 넘겨받은 날것의 데이터를 매핑하는 비즈니스 로직
  void _parseAndMapDeviceMessage(String rawJsonString) {
    try {
      final Map<String, dynamic> parsedJson = jsonDecode(rawJsonString);
      final Map<String, dynamic> parsedSJson = parsedJson['datas'];

      setState(() {
        for (var entry in parsedSJson.entries) {
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

  void remoteClickEvent(String label, String input) {// 1. 한글 라벨을 원본 장비 키(예: 'control_runsw')로 변환
    final String? rawKey = reverseDeviceKeyMap[label];

    if (rawKey == null) {
      print('매핑할 수 없는 키입니다: $label');
      return;
    }

    // 2. 서버 형식에 맞게 req_id 생성 (예: "1.control_runsw")
    final String reqId = '${widget.roomId}.$rawKey';

    Map<String, String> temp = {
      'type': "WR",
      'req_id': reqId,
      'req_val': input
    };
    if(_webSocketService.isConnected) {
      print(jsonEncode(temp));
      _webSocketService.send(jsonEncode(temp));
    }
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
            IntegratedFacilityBox(
                facilities: _rooms,
                onFacilityPressed: (roomId) {
                  // 터치 시 시설 라우팅용 nav 페이지로 이동
                  context.push('/facility_monitoring/${widget.userId}/${widget.facilityId}/$roomId');
                }),
            MonitoringCard(title: '시설 기본 정보', fields: infoData),
            MonitoringCard(title: '실제 온도', fields: realtempData, OnConfirm: remoteClickEvent),
            MonitoringCard(title: '제상 정보', fields: deforestData, OnConfirm: remoteClickEvent),
            MonitoringCard(title: '이상 정보', fields: emergencyData, OnConfirm: remoteClickEvent),
            MonitoringCard(title: '인버터 정보', fields: inverterData, OnConfirm: remoteClickEvent),
            MonitoringCard(title: '장비 정보', fields: equipmentData, OnConfirm: remoteClickEvent),
            MonitoringCard(title: '제어 정보', fields: controlData, OnConfirm: remoteClickEvent),
          ],
        ),
      ),
    );
  }
}