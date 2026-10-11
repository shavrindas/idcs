// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsDeviceOnly => '이 설정은 이 기기에만 적용됩니다.';

  @override
  String get settingsLanguage => '언어';

  @override
  String get languageSystem => '시스템 설정';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsTheme => '화면 테마';

  @override
  String get themeSystem => '시스템 설정';

  @override
  String get themeLight => '밝게';

  @override
  String get themeDark => '어둡게';

  @override
  String get settingsPanel => '제어판 화면';

  @override
  String get settingsPanelNote => '호실에 들어갔을 때 보이는 실시간 제어판에만 적용됩니다.';

  @override
  String get panelBackground => '배경';

  @override
  String get panelOpacity => '투명도';

  @override
  String get panelValueSize => '숫자 크기';

  @override
  String get panelLedDigits => 'LED 숫자';

  @override
  String get panelLedDigitsNote => '숫자를 7세그먼트 표시기 모양으로 보여줍니다.';

  @override
  String get panelSampleLabel => '고내온도';

  @override
  String get backgroundNone => '없음';

  @override
  String get backgroundBlueprint => '도면';

  @override
  String get backgroundCoil => '냉각 코일';

  @override
  String get backgroundMetal => '금속';

  @override
  String get backgroundGrid => '격자';

  @override
  String get settingsAlarmStyle => '알림 방식';

  @override
  String get alarmSound => '소리';

  @override
  String get alarmSoundNote => '알람이 올 때 소리로 알립니다.';

  @override
  String get alarmVibration => '진동';

  @override
  String get alarmVibrationNote => '알람이 올 때 진동으로 알립니다.';

  @override
  String get alarmLockScreen => '잠금화면에 내용 표시';

  @override
  String get alarmLockScreenNote => '꺼두면 잠금화면에서는 알람이 왔다는 사실만 보입니다.';

  @override
  String get alarmRepeat => '다시 알림';

  @override
  String alarmRepeatNote(int count) {
    return '알람을 확인하지 못했을 때 설정한 간격으로 최대 $count번까지 다시 알려줍니다.';
  }

  @override
  String get alarmRepeatNone => '없음';

  @override
  String alarmRepeatMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String get fieldEmail => '이메일';

  @override
  String get fieldPassword => '비밀번호';

  @override
  String get fieldNewPassword => '새 비밀번호';

  @override
  String get fieldConfirmPassword => '비밀번호 재입력';

  @override
  String get fieldName => '이름';

  @override
  String get fieldPhoneOptional => '전화번호 (선택)';

  @override
  String get fieldVerificationCode => '인증 코드';

  @override
  String get showPassword => '비밀번호 표시';

  @override
  String get actionCancel => '취소';

  @override
  String get actionSubmit => '입력 완료';

  @override
  String get orDivider => '또는';

  @override
  String get continueWithGoogle => 'Google로 계속하기';

  @override
  String get continueWithApple => 'Apple로 계속하기';

  @override
  String get login => '로그인';

  @override
  String get loginWelcomeTitle => '다시 만나서 반가워요';

  @override
  String get loginWelcomeSubtitle => '계정 정보를 입력하고 로그인해주세요.';

  @override
  String get loginMissingFields => '이메일과 비밀번호를 모두 입력해주세요.';

  @override
  String get keepSignedIn => '로그인 상태 유지하기';

  @override
  String get noAccountQuestion => '계정이 없으신가요? ';

  @override
  String get signUp => '회원가입';

  @override
  String get signupTitle => '계정 만들기';

  @override
  String get signupSubtitle => '아래 정보를 입력하고 계정을 생성해주세요.';

  @override
  String get signupCreateAccount => '계정 생성';

  @override
  String get signupMissingFields => '필수 항목을 모두 입력해주세요.';

  @override
  String get signupEmailRequired => '이메일을 입력해주세요.';

  @override
  String get signupEmailUnavailable => '이메일 정보를 가져올 수 없습니다. 설정에서 이메일을 허용해주세요.';

  @override
  String get signupAppleEmailMissing =>
      '애플 계정의 이메일 정보가 누락되었습니다.\n원활한 서비스 이용을 위해 이메일을 직접 입력해주세요.';

  @override
  String get findId => '아이디 찾기';

  @override
  String get findIdSubtitle => '가입하신 이메일을 입력하면 계정 정보를 확인해드려요.';

  @override
  String get findIdEmailRequired => '확인할 이메일을 입력해주세요.';

  @override
  String errorOccurred(String message) {
    return '오류 발생: $message';
  }

  @override
  String get findPassword => '비밀번호 찾기';

  @override
  String get resetPasswordTitle => '비밀번호 재설정';

  @override
  String get resetPasswordSubtitle => '이메일 인증 후 새 비밀번호를 설정해주세요.';

  @override
  String get resetStepEmail => '이메일 인증';

  @override
  String get resetSendCode => '인증 코드 받기';

  @override
  String get resetStepCode => '인증 코드 입력';

  @override
  String get resetVerifyCode => '코드 확인';

  @override
  String get resetStepNewPassword => '새 비밀번호 설정';

  @override
  String resetTimeLeft(String time) {
    return '남은 시간 $time';
  }

  @override
  String get resetTimedOut => '입력 시간이 초과되었습니다.';

  @override
  String get resetCodeVerified => '코드 인증 성공!';

  @override
  String get resetPasswordMismatch => '비밀번호가 일치하지 않습니다.';
}
