import 'package:flutter/material.dart';
import 'package:idcs/components/facility/monitoring/monitoring.dart';
import 'package:idcs/main.dart';
import 'dart:convert';
import 'dart:async';
import 'package:idcs/services/common/web_socket_service.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
import 'package:idcs/components/facility/monitoring/panel_summary_card.dart';
import 'package:idcs/services/common/facility_api_service.dart';
import 'package:idcs/theme/panel_background.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/components/facility/monitoring/device_labels.dart';
import 'package:idcs/components/shared/app_toast.dart';

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

  /// 마지막으로 값이 들어온 시각. 요약 카드가 이 값으로 신선도를 보여준다.
  DateTime? _lastUpdate;

  /// '몇 초 전'이 멈춰 있지 않도록 주기적으로 다시 그린다.
  Timer? _freshnessTicker;

  /// 앱바에 띄울 호실 이름. 시설 ID 보다 현장에서 쓰는 이름이 쓸모 있다.
  String? _roomName;

  /// 보내 놓고 설비 응답을 기다리는 제어 명령. req_id -> 화면에 쓸 항목 이름.
  ///
  /// 설비가 값을 실제로 바꾸기까지는 시간이 걸리고, 거부할 수도 있다. 보낸
  /// 사실과 반영된 사실을 구분해서 알려 주려면 어느 요청이 떠 있는지 알아야 한다.
  final Map<String, String> _pendingCommands = {};

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

    _freshnessTicker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });

    _loadRoomName();
  }

  Future<void> _loadRoomName() async {
    try {
      final rooms = await FacilityApiService.getFacilityRooms(widget.facilityId);
      final match = rooms.firstWhere(
        (r) => r['id'].toString() == widget.roomId,
        orElse: () => null,
      );
      if (mounted && match != null) setState(() => _roomName = match['name']);
    } catch (_) {
      // 이름을 못 불러와도 제어판 자체는 그대로 쓸 수 있으므로 조용히 넘어간다.
    }
  }

  // 통신 클래스로부터 넘겨받은 날것의 데이터를 매핑하는 비즈니스 로직
  void _parseAndMapDeviceMessage(String rawJsonString) {
    try {
      final Map<String, dynamic> parsedJson = jsonDecode(rawJsonString);

      // 제어 응답은 계측값과 같은 소켓으로 돌아온다. 서버 버전에 따라 그대로
      // 오기도 하고 datas 안에 싸여 오기도 해서 양쪽을 다 본다.
      if (parsedJson['status'] != null) {
        _handleCommandResponse(parsedJson);
        return;
      }

      final dynamic rawDatas = parsedJson['datas'];
      if (rawDatas is! Map<String, dynamic>) return;
      if (rawDatas['status'] != null) {
        _handleCommandResponse(rawDatas);
        return;
      }
      final Map<String, dynamic> parsedSJson = rawDatas;

      setState(() {
        _lastUpdate = DateTime.now();
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
    _freshnessTicker?.cancel();
    _wsSubscription?.cancel();
    _webSocketService.disconnect();
    super.dispose();
  }

  /// 제어판에서 값을 보낼 때. 행이 들고 있는 키가 이미 서버 필드 이름이라
  /// 따로 변환할 것이 없다.
  /// 제어판에서 '확인'을 눌렀을 때. 보냈으면 true 를 돌려주고, 그때만 입력칸을
  /// 비운다.
  ///
  /// 예전에는 연결이 끊겨 있으면 아무 일도 없이 조용히 넘어갔다. 누른 사람은
  /// 값이 들어간 줄 알고 자리를 뜨는데, 실제로는 아무것도 보내지지 않았다.
  bool remoteClickEvent(String key, String input) {
    final l10n = context.l10n;
    final label = DeviceLabels.of(context, key);
    final value = input.trim();

    if (value.isEmpty) {
      AppToast.warning(context, l10n.panelValueRequired);
      return false;
    }

    if (!_webSocketService.isConnected) {
      AppToast.error(context, l10n.panelNotConnected);
      return false;
    }

    // 서버 형식에 맞게 req_id 생성 (예: "23.control_runsw")
    final String reqId = '${widget.roomId}.$key';
    _pendingCommands[reqId] = label;

    _webSocketService.send(jsonEncode({
      'type': 'WR',
      'req_id': reqId,
      'req_val': value,
    }));

    AppToast.info(context, l10n.panelCommandSent(label));
    return true;
  }

  /// 설비가 제어 명령에 답했을 때. 응답이 영영 안 올 수도 있으므로, 이건
  /// 보낸 사실을 알리는 토스트를 대신하는 게 아니라 그 뒤에 덧붙는다.
  void _handleCommandResponse(Map<String, dynamic> packet) {
    final reqId = packet['request_id']?.toString() ?? packet['req_id']?.toString();
    if (reqId == null) return;

    final label = _pendingCommands.remove(reqId);
    if (label == null || !mounted) return;

    final ok = (packet['status']?.toString() ?? '').toUpperCase().contains('SUCCESS');
    final l10n = context.l10n;
    if (ok) {
      AppToast.success(context, l10n.panelCommandOk(label));
    } else {
      AppToast.error(context, l10n.panelCommandFailed(label));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MonitoringViewSettings>(
      valueListenable: MonitoringViewController.settings,
      builder: (context, view, _) => Scaffold(
        appBar: AppBar(
          title: Text(_roomName ?? context.l10n.panelPageTitle(widget.facilityId)),
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
                  // 시설 ID·호실 ID·관리자 ID 를 띄우던 카드를 걷어내고, 이 화면을
                  // 여는 이유인 '지금 몇 도인가'를 맨 위에 둔다.
                  PanelSummaryCard(
                    currentTemp: realtempData['temp_pv'] ?? 'NA',
                    setpoint: realtempData['temp_sv'] ?? 'NA',
                    lastUpdate: _lastUpdate,
                    view: view,
                  ),
                  const SizedBox(height: 16),
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