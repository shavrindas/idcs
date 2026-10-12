// ===============================================================
// 경로: lib/components/facility/monitoring/device_labels.dart
// 명세: 제어판 장비 항목의 표시 이름 (API 키 → 한국어/영어)
// ===============================================================
import 'package:flutter/widgets.dart';

/// Display names for the equipment fields the control panel shows.
///
/// These live here rather than in the .arb files on purpose. They are a domain
/// dictionary — 56 refrigeration terms that the people who know the equipment
/// have to be able to review and correct — and a side-by-side table is far
/// easier to check than 112 scattered translation entries.
///
/// The key is always the field name the backend sends (`temp_pv`). That is what
/// the panel stores its readings under, so a label can change without touching
/// the live data path.
class DeviceLabels {
  DeviceLabels._();

  /// api key -> (한국어, English)
  static const Map<String, (String, String)> _labels = {
    // 실제 온도
    'temp_comp': ('H_COMP', 'H_COMP'),
    'temp_pv': ('고내온도_#1', 'Room temp #1'),
    'temp_sv': ('설정값_#1', 'Setpoint #1'),
    'temp_hey': ('편차값_#1', 'Deviation #1'),
    'temp_zero': ('ZERO_#1', 'ZERO #1'),

    // 제상 정보
    'deforest_def': ('제상용 전자변', 'Defrost solenoid'),
    'deforest_dfcm': ('제상타임_#1', 'Defrost time #1'),
    'deforest_dfct': ('싸이클_#1', 'Cycle #1'),
    'deforest_sysm': ('시스템분_#1', 'System min #1'),
    'deforest_syst': ('시스템시간_#1', 'System hour #1'),

    // 이상 정보
    'emergency_cint': ('CINT', 'CINT'),
    'emergency_high': ('HIGH', 'HIGH'),
    'emergency_uf_ocr': ('UF/OCR', 'UF/OCR'),
    'emergency_locked': ('감금알람', 'Lock-in alarm'),
    'emergency_outtemp': ('토출온도이상', 'Discharge temp fault'),
    'emergency_gas': ('가스부족', 'Low refrigerant'),
    'emergency_tempsensor': ('온도센서이상', 'Temp sensor fault'),
    'emergency_defemg': ('역상방지이상', 'Phase reversal fault'),
    'emergency_lowsw': ('LOW 스위치', 'LOW switch'),
    'emergency_hottic': ('과열TIC', 'Overheat TIC'),
    'emergency_emg': ('ARLAM', 'Emergency'),
    'emergency_emgreset': ('RESET', 'RESET'),

    // 인버터 정보
    'inverter_error': ('인버터 에러', 'Inverter error'),
    'inverter_hz': ('Hz_#1', 'Hz #1'),
    'inverter_kw': ('KW_#1', 'kW #1'),
    'inverter_outv': ('출력전압_#1', 'Output V #1'),
    'inverter_outa': ('출력전류_#1', 'Output A #1'),
    'inverter_outhz': ('출력주파수_#1', 'Output Hz #1'),

    // 장비 정보
    'equipment_temp1': ('토출온도_#1', 'Discharge temp #1'),
    'equipment_press1': ('고압_#1', 'High pressure #1'),
    'equipment_press2': ('저압_#1', 'Low pressure #1'),

    // 제어 정보
    'control_runsw': ('운전SW', 'Run switch'),
    'control_roomtemp': ('룸온도스위치', 'Room temp switch'),
    'control_cffan1': ('방열기 팬 #1', 'Condenser fan #1'),
    'control_cffan2': ('방열기 팬 #2', 'Condenser fan #2'),
    'control_lsv': ('액 전자변', 'Liquid solenoid'),
    'control_ingsv': ('전자변', 'Solenoid valve'),
    'control_uffan': ('쿨러 팬', 'Cooler fan'),
    'control_tica': ('아날로그TC', 'Analog TC'),
    'control_efa': ('쿨러 팬 자동여부', 'Cooler fan auto'),
    'control_heatdelflag': ('히터정지', 'Heater stop'),
    'control_initdelflag': ('초기지연', 'Initial delay'),
    'control_compdelflag': ('콤프지연', 'Compressor delay'),
    'control_coolerdelflag': ('쿨러지연', 'Cooler delay'),
    'control_mdf': ('수동제상', 'Manual defrost'),
    'control_sw': ('컴퓨터 S/W', 'Computer S/W'),
    'control_runtimelow': ('운전시간_#1', 'Run time #1'),
    'control_runtimehigh': ('운전시간만_#1', 'Run hours #1'),
    'control_initdeltm': ('초기지연_#1', 'Initial delay #1'),
    'control_compdeltm': ('콤프지연_#1', 'Compressor delay #1'),
    'control_cooldeltm': ('쿨러지연타임_#1', 'Cooler delay #1'),
    'control_defdeltm': ('DF 지연_#1', 'DF delay #1'),

    // 같은 이름을 쓰던 짝. 예전 구조에서는 한국어 라벨이 겹쳐 서로를 덮어썼다.
    'control_initdelst': ('초기지연 설정_#1', 'Initial delay (set) #1'),
    'control_compdelst': ('H_콤프지연_#1', 'H compressor delay #1'),
    'control_cooldelst': ('쿨러지연 설정_#1', 'Cooler delay (set) #1'),
    'control_defdelst': ('DF 지연 설정_#1', 'DF delay (set) #1'),
  };

  /// The display name for a field, in the language the app is showing.
  /// Falls back to the raw key so an unmapped field is still visible and
  /// traceable rather than silently blank.
  static String of(BuildContext context, String apiKey) {
    final pair = _labels[apiKey];
    if (pair == null) return apiKey;
    return Localizations.localeOf(context).languageCode == 'en' ? pair.$2 : pair.$1;
  }
}
