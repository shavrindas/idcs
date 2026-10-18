// ===============================================================
// 경로: lib/components/facility/monitoring/field_meaning.dart
// 명세: 참/거짓 항목이 켜졌을 때·꺼졌을 때 각각 무슨 뜻인지
// ===============================================================
import 'package:flutter/widgets.dart';

/// 이 값이 좋은 소식인지 나쁜 소식인지, 아니면 그냥 상태인지.
enum Tone {
  /// 정상이라고 말할 수 있다.
  good,

  /// 사람이 가서 봐야 한다.
  bad,

  /// 좋고 나쁨이 없다. 지금 돌고 있는지 아닌지를 말할 뿐이다.
  /// 제상은 돌아도 정상이고 멈춰도 정상이다.
  neutral,
}

/// 참/거짓 한 항목의 뜻.
///
/// [DeviceLabels] 가 "이 값의 이름이 무엇인가"에 답한다면, 여기는 "그래서
/// 그게 무슨 뜻인가"에 답한다. 둘은 다른 질문이다 — '제상용 전자변: ON' 은
/// 이름과 값을 둘 다 알려주지만, 읽는 사람이 냉동 설비를 모르면 지금 좋은
/// 상황인지 나쁜 상황인지는 여전히 알 수 없다.
@immutable
class FieldMeaning {
  /// 켜졌을 때 (한국어, English).
  final (String, String) on;

  /// 꺼졌을 때.
  final (String, String) off;

  /// 켜진 쪽이 나쁜 소식인지. 이상 플래그가 그렇다.
  final bool onIsFault;

  const FieldMeaning(this.on, this.off, {this.onIsFault = false});

  Tone toneFor(bool isOn) {
    if (!onIsFault) return Tone.neutral;
    return isOn ? Tone.bad : Tone.good;
  }

  String word(BuildContext context, bool isOn) {
    final ko = Localizations.localeOf(context).languageCode == 'ko';
    final pair = isOn ? on : off;
    return ko ? pair.$1 : pair.$2;
  }

  /// api key -> 뜻.
  ///
  /// 전부 적지는 않았다. 여기 없는 항목은 ON/OFF 그대로 나간다 — 설비를 아는
  /// 사람이 확인해 주기 전에 뜻을 지어내는 것보다, 모른다고 두는 편이 낫다.
  static const Map<String, FieldMeaning> _meanings = {
    // 이상 플래그. 켜지면 사람이 가서 봐야 한다.
    'emergency_emg': (FieldMeaning(('비상정지', 'Emergency stop'), ('정상', 'Normal'), onIsFault: true)),
    'emergency_cint': (FieldMeaning(('발생', 'Active'), ('정상', 'Normal'), onIsFault: true)),
    'emergency_high': (FieldMeaning(('고압 이상', 'High pressure'), ('정상', 'Normal'), onIsFault: true)),
    'emergency_uf_ocr': (FieldMeaning(('발생', 'Active'), ('정상', 'Normal'), onIsFault: true)),
    'emergency_locked': (FieldMeaning(('감금 발생', 'Someone locked in'), ('정상', 'Normal'), onIsFault: true)),
    'emergency_outtemp': (FieldMeaning(('토출온도 이상', 'Discharge temp high'), ('정상', 'Normal'), onIsFault: true)),
    'emergency_gas': (FieldMeaning(('냉매 부족', 'Low refrigerant'), ('정상', 'Normal'), onIsFault: true)),
    'emergency_tempsensor': (FieldMeaning(('센서 이상', 'Sensor fault'), ('정상', 'Normal'), onIsFault: true)),
    'emergency_defemg': (FieldMeaning(('역상 발생', 'Phase reversed'), ('정상', 'Normal'), onIsFault: true)),
    'emergency_lowsw': (FieldMeaning(('동작', 'Tripped'), ('정상', 'Normal'), onIsFault: true)),
    'emergency_hottic': (FieldMeaning(('과열', 'Overheating'), ('정상', 'Normal'), onIsFault: true)),
    'inverter_error': (FieldMeaning(('에러', 'Error'), ('정상', 'Normal'), onIsFault: true)),

    // RESET 은 이상이 아니다. 사람이 복귀를 누른 상태를 뜻한다.
    'emergency_emgreset': (FieldMeaning(('복귀 중', 'Resetting'), ('대기', 'Idle'))),

    // 돌고 있는지 멈춰 있는지. 어느 쪽도 좋고 나쁨이 아니다.
    'control_runsw': (FieldMeaning(('운전 중', 'Running'), ('정지', 'Stopped'))),
    'temp_comp': (FieldMeaning(('작동', 'On'), ('정지', 'Off'))),
    'deforest_def': (FieldMeaning(('제상 중', 'Defrosting'), ('대기', 'Idle'))),
    'control_mdf': (FieldMeaning(('수동 제상 중', 'Manual defrost'), ('대기', 'Idle'))),
    'control_cffan1': (FieldMeaning(('작동', 'Running'), ('정지', 'Stopped'))),
    'control_cffan2': (FieldMeaning(('작동', 'Running'), ('정지', 'Stopped'))),
    'control_uffan': (FieldMeaning(('작동', 'Running'), ('정지', 'Stopped'))),
    'control_efa': (FieldMeaning(('자동', 'Auto'), ('수동', 'Manual'))),
    'control_lsv': (FieldMeaning(('열림', 'Open'), ('닫힘', 'Closed'))),
    'control_ingsv': (FieldMeaning(('열림', 'Open'), ('닫힘', 'Closed'))),
    'control_roomtemp': (FieldMeaning(('켜짐', 'On'), ('꺼짐', 'Off'))),

    // 지연은 '지금 기다리는 중'이라는 뜻이다. 고장이 아니라 보호 동작이다.
    'control_heatdelflag': (FieldMeaning(('지연 중', 'Waiting'), ('해제', 'Clear'))),
    'control_initdelflag': (FieldMeaning(('지연 중', 'Waiting'), ('해제', 'Clear'))),
    'control_compdelflag': (FieldMeaning(('지연 중', 'Waiting'), ('해제', 'Clear'))),
    'control_comdelflag': (FieldMeaning(('지연 중', 'Waiting'), ('해제', 'Clear'))),
    'control_coolerdelflag': (FieldMeaning(('지연 중', 'Waiting'), ('해제', 'Clear'))),
  };

  static FieldMeaning? forKey(String apiKey) => _meanings[apiKey];

  /// 이 항목이 켜졌을 때 '이상'으로 셀 항목인지.
  static bool isFaultFlag(String apiKey) => _meanings[apiKey]?.onIsFault ?? false;
}
