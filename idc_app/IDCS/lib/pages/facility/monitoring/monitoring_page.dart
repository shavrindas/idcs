import 'package:flutter/material.dart';
import 'package:idcs/components/facility/monitoring/monitoring.dart';
import 'package:idcs/main.dart';
import 'dart:convert';
import 'dart:async';
import 'package:idcs/services/common/web_socket_service.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
import 'package:idcs/theme/panel_background.dart';
import 'package:idcs/l10n/l10n_context.dart';

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
  Map<String, String> realtempData = {'temp_comp': 'NA', 'temp_pv': 'NA', 'temp_sv': 'NA', 'temp_hey': 'NA', 'temp_zero': 'NA'};
  Map<String, String> deforestData = {'deforest_def': 'NA', 'deforest_dfcm': 'NA', 'deforest_dfct': 'NA', 'deforest_sysm': 'NA', 'deforest_syst': 'NA'};
  Map<String, String> emergencyData = {'emergency_cint': 'NA', 'emergency_high': 'NA', 'emergency_uf_ocr': 'NA', 'emergency_locked': 'NA', 'emergency_outtemp': 'NA', 'emergency_gas': 'NA', 'emergency_tempsensor': 'NA', 'emergency_defemg': 'NA', 'emergency_lowsw': 'NA', 'emergency_hottic': 'NA', 'emergency_emg': 'NA', 'emergency_emgreset': 'NA'};
  Map<String, String> inverterData = {'inverter_error': 'NA', 'inverter_hz': 'NA', 'inverter_kw': 'NA', 'inverter_outv': 'NA', 'inverter_outa': 'NA', 'inverter_outhz': 'NA'};
  Map<String, String> equipmentData = {'equipment_temp1': 'NA', 'equipment_press1': 'NA', 'equipment_press2': 'NA'};
  Map<String, String> controlData = {'control_runsw': 'NA', 'control_roomtemp': 'NA', 'control_cffan1': 'NA', 'control_cffan2': 'NA', 'control_lsv': 'NA', 'control_ingsv': 'NA', 'control_uffan': 'NA', 'control_tica': 'NA', 'control_efa': 'NA', 'control_heatdelflag': 'NA', 'control_initdelflag': 'NA', 'control_compdelflag': 'NA', 'control_coolerdelflag': 'NA', 'control_mdf': 'NA', 'control_sw': 'NA', 'control_runtimelow': 'NA', 'control_runtimehigh': 'NA', 'control_initdeltm': 'NA', 'control_compdelst': 'NA', 'control_cooldeltm': 'NA', 'control_defdeltm': 'NA'};
  /// 그룹 맵은 모두 서버가 보내는 필드 이름을 키로 쓴다. 화면에 보여줄 이름은
  /// DeviceLabels 가 그릴 때 붙이므로, 라벨을 바꿔도 데이터 경로는 그대로다.
  ///
  /// 예전에는 한국어 라벨이 키였는데, 서로 다른 필드가 같은 라벨을 쓰는 경우가
  /// 있어(초기지연_#1 등) 역방향 조회에서 한쪽이 덮여 사라졌다.
  Map<String, String> _groupFor(String key) {
    if (realtempData.containsKey(key)) return realtempData;
    if (deforestData.containsKey(key)) return deforestData;
    if (emergencyData.containsKey(key)) return emergencyData;
    if (inverterData.containsKey(key)) return inverterData;
    if (equipmentData.containsKey(key)) return equipmentData;
    return controlData;
  }

  @override
  void initState() {
    super.initState();
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
      final Map<String, dynamic> parsedSJson = parsedJson['datas'];

      setState(() {
        for (var entry in parsedSJson.entries) {
          // 키는 "호실.필드" 형태로 온다 (예: "23.temp_pv")
          final List<String> parts = entry.key.split('.');

          if (int.parse(widget.roomId) != int.parse(parts[0])) continue;

          final String key = parts[1];
          final group = _groupFor(key);
          if (group.containsKey(key)) {
            group[key] = entry.value.toString();
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

  /// 제어판에서 값을 보낼 때. 행이 들고 있는 키가 이미 서버 필드 이름이라
  /// 따로 변환할 것이 없다.
  void remoteClickEvent(String key, String input) {
    // 2. 서버 형식에 맞게 req_id 생성 (예: "1.control_runsw")
    final String reqId = '${widget.roomId}.$key';

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
    return ValueListenableBuilder<MonitoringViewSettings>(
      valueListenable: MonitoringViewController.settings,
      builder: (context, view, _) => Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.panelPageTitle(widget.facilityId)),
          centerTitle: true,
        ),
        // 배경이 패널 사이로 비쳐 보이도록 Scaffold는 비워 두고 Stack 맨 아래에 깐다.
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(child: PanelBackdrop(backgroundId: view.backgroundId)),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 이 카드만 장비 데이터가 아니라서 라벨을 그대로 쓴다.
                  MonitoringCard(
                    title: context.l10n.panelCardInfo,
                    fields: {
                      context.l10n.panelInfoFacilityId: widget.facilityId,
                      context.l10n.panelInfoRoomId: widget.roomId,
                      context.l10n.panelInfoManagerId: widget.userId,
                      context.l10n.panelInfoStatus: context.l10n.panelStatusActive,
                    },
                    view: view,
                  ),
                  MonitoringCard(title: context.l10n.panelCardTemp, fields: realtempData, view: view, deviceKeys: true, OnConfirm: remoteClickEvent),
                  MonitoringCard(title: context.l10n.panelCardDefrost, fields: deforestData, view: view, deviceKeys: true, OnConfirm: remoteClickEvent),
                  MonitoringCard(title: context.l10n.panelCardFaults, fields: emergencyData, view: view, deviceKeys: true, OnConfirm: remoteClickEvent),
                  MonitoringCard(title: context.l10n.panelCardInverter, fields: inverterData, view: view, deviceKeys: true, OnConfirm: remoteClickEvent),
                  MonitoringCard(title: context.l10n.panelCardEquipment, fields: equipmentData, view: view, deviceKeys: true, OnConfirm: remoteClickEvent),
                  MonitoringCard(title: context.l10n.panelCardControl, fields: controlData, view: view, deviceKeys: true, OnConfirm: remoteClickEvent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}