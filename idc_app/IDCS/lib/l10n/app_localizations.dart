import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @settingsDeviceOnly.
  ///
  /// In ko, this message translates to:
  /// **'이 설정은 이 기기에만 적용됩니다.'**
  String get settingsDeviceOnly;

  /// No description provided for @settingsLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정'**
  String get languageSystem;

  /// No description provided for @languageKorean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @languageEnglish.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsTheme.
  ///
  /// In ko, this message translates to:
  /// **'화면 테마'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ko, this message translates to:
  /// **'밝게'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ko, this message translates to:
  /// **'어둡게'**
  String get themeDark;

  /// No description provided for @settingsPanel.
  ///
  /// In ko, this message translates to:
  /// **'제어판 화면'**
  String get settingsPanel;

  /// No description provided for @settingsPanelNote.
  ///
  /// In ko, this message translates to:
  /// **'호실에 들어갔을 때 보이는 실시간 제어판에만 적용됩니다.'**
  String get settingsPanelNote;

  /// No description provided for @panelBackground.
  ///
  /// In ko, this message translates to:
  /// **'배경'**
  String get panelBackground;

  /// No description provided for @panelOpacity.
  ///
  /// In ko, this message translates to:
  /// **'투명도'**
  String get panelOpacity;

  /// No description provided for @panelValueSize.
  ///
  /// In ko, this message translates to:
  /// **'숫자 크기'**
  String get panelValueSize;

  /// No description provided for @panelLedDigits.
  ///
  /// In ko, this message translates to:
  /// **'LED 숫자'**
  String get panelLedDigits;

  /// No description provided for @panelLedDigitsNote.
  ///
  /// In ko, this message translates to:
  /// **'숫자를 7세그먼트 표시기 모양으로 보여줍니다.'**
  String get panelLedDigitsNote;

  /// No description provided for @panelSampleLabel.
  ///
  /// In ko, this message translates to:
  /// **'고내온도'**
  String get panelSampleLabel;

  /// No description provided for @backgroundNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get backgroundNone;

  /// No description provided for @backgroundBlueprint.
  ///
  /// In ko, this message translates to:
  /// **'도면'**
  String get backgroundBlueprint;

  /// No description provided for @backgroundCoil.
  ///
  /// In ko, this message translates to:
  /// **'냉각 코일'**
  String get backgroundCoil;

  /// No description provided for @backgroundMetal.
  ///
  /// In ko, this message translates to:
  /// **'금속'**
  String get backgroundMetal;

  /// No description provided for @backgroundGrid.
  ///
  /// In ko, this message translates to:
  /// **'격자'**
  String get backgroundGrid;

  /// No description provided for @settingsAlarmStyle.
  ///
  /// In ko, this message translates to:
  /// **'알림 방식'**
  String get settingsAlarmStyle;

  /// No description provided for @alarmSound.
  ///
  /// In ko, this message translates to:
  /// **'소리'**
  String get alarmSound;

  /// No description provided for @alarmSoundNote.
  ///
  /// In ko, this message translates to:
  /// **'알람이 올 때 소리로 알립니다.'**
  String get alarmSoundNote;

  /// No description provided for @alarmVibration.
  ///
  /// In ko, this message translates to:
  /// **'진동'**
  String get alarmVibration;

  /// No description provided for @alarmVibrationNote.
  ///
  /// In ko, this message translates to:
  /// **'알람이 올 때 진동으로 알립니다.'**
  String get alarmVibrationNote;

  /// No description provided for @alarmLockScreen.
  ///
  /// In ko, this message translates to:
  /// **'잠금화면에 내용 표시'**
  String get alarmLockScreen;

  /// No description provided for @alarmLockScreenNote.
  ///
  /// In ko, this message translates to:
  /// **'꺼두면 잠금화면에서는 알람이 왔다는 사실만 보입니다.'**
  String get alarmLockScreenNote;

  /// No description provided for @alarmRepeat.
  ///
  /// In ko, this message translates to:
  /// **'다시 알림'**
  String get alarmRepeat;

  /// No description provided for @alarmRepeatNote.
  ///
  /// In ko, this message translates to:
  /// **'알람을 확인하지 못했을 때 설정한 간격으로 최대 {count}번까지 다시 알려줍니다.'**
  String alarmRepeatNote(int count);

  /// No description provided for @alarmRepeatNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get alarmRepeatNone;

  /// No description provided for @alarmRepeatMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분'**
  String alarmRepeatMinutes(int minutes);

  /// No description provided for @fieldEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get fieldPassword;

  /// No description provided for @fieldNewPassword.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호'**
  String get fieldNewPassword;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재입력'**
  String get fieldConfirmPassword;

  /// No description provided for @fieldName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get fieldName;

  /// No description provided for @fieldPhoneOptional.
  ///
  /// In ko, this message translates to:
  /// **'전화번호 (선택)'**
  String get fieldPhoneOptional;

  /// No description provided for @fieldVerificationCode.
  ///
  /// In ko, this message translates to:
  /// **'인증 코드'**
  String get fieldVerificationCode;

  /// No description provided for @showPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 표시'**
  String get showPassword;

  /// No description provided for @actionCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get actionCancel;

  /// No description provided for @actionSubmit.
  ///
  /// In ko, this message translates to:
  /// **'입력 완료'**
  String get actionSubmit;

  /// No description provided for @orDivider.
  ///
  /// In ko, this message translates to:
  /// **'또는'**
  String get orDivider;

  /// No description provided for @continueWithGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Google로 계속하기'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In ko, this message translates to:
  /// **'Apple로 계속하기'**
  String get continueWithApple;

  /// No description provided for @login.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get login;

  /// No description provided for @loginWelcomeTitle.
  ///
  /// In ko, this message translates to:
  /// **'다시 만나서 반가워요'**
  String get loginWelcomeTitle;

  /// No description provided for @loginWelcomeSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'계정 정보를 입력하고 로그인해주세요.'**
  String get loginWelcomeSubtitle;

  /// No description provided for @loginMissingFields.
  ///
  /// In ko, this message translates to:
  /// **'이메일과 비밀번호를 모두 입력해주세요.'**
  String get loginMissingFields;

  /// No description provided for @keepSignedIn.
  ///
  /// In ko, this message translates to:
  /// **'로그인 상태 유지하기'**
  String get keepSignedIn;

  /// No description provided for @noAccountQuestion.
  ///
  /// In ko, this message translates to:
  /// **'계정이 없으신가요? '**
  String get noAccountQuestion;

  /// No description provided for @signUp.
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get signUp;

  /// No description provided for @signupTitle.
  ///
  /// In ko, this message translates to:
  /// **'계정 만들기'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'아래 정보를 입력하고 계정을 생성해주세요.'**
  String get signupSubtitle;

  /// No description provided for @signupCreateAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정 생성'**
  String get signupCreateAccount;

  /// No description provided for @signupMissingFields.
  ///
  /// In ko, this message translates to:
  /// **'필수 항목을 모두 입력해주세요.'**
  String get signupMissingFields;

  /// No description provided for @signupEmailRequired.
  ///
  /// In ko, this message translates to:
  /// **'이메일을 입력해주세요.'**
  String get signupEmailRequired;

  /// No description provided for @signupEmailUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'이메일 정보를 가져올 수 없습니다. 설정에서 이메일을 허용해주세요.'**
  String get signupEmailUnavailable;

  /// No description provided for @signupAppleEmailMissing.
  ///
  /// In ko, this message translates to:
  /// **'애플 계정의 이메일 정보가 누락되었습니다.\n원활한 서비스 이용을 위해 이메일을 직접 입력해주세요.'**
  String get signupAppleEmailMissing;

  /// No description provided for @findId.
  ///
  /// In ko, this message translates to:
  /// **'아이디 찾기'**
  String get findId;

  /// No description provided for @findIdSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'가입하신 이메일을 입력하면 계정 정보를 확인해드려요.'**
  String get findIdSubtitle;

  /// No description provided for @findIdEmailRequired.
  ///
  /// In ko, this message translates to:
  /// **'확인할 이메일을 입력해주세요.'**
  String get findIdEmailRequired;

  /// No description provided for @errorOccurred.
  ///
  /// In ko, this message translates to:
  /// **'오류 발생: {message}'**
  String errorOccurred(String message);

  /// No description provided for @findPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 찾기'**
  String get findPassword;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재설정'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'이메일 인증 후 새 비밀번호를 설정해주세요.'**
  String get resetPasswordSubtitle;

  /// No description provided for @resetStepEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일 인증'**
  String get resetStepEmail;

  /// No description provided for @resetSendCode.
  ///
  /// In ko, this message translates to:
  /// **'인증 코드 받기'**
  String get resetSendCode;

  /// No description provided for @resetStepCode.
  ///
  /// In ko, this message translates to:
  /// **'인증 코드 입력'**
  String get resetStepCode;

  /// No description provided for @resetVerifyCode.
  ///
  /// In ko, this message translates to:
  /// **'코드 확인'**
  String get resetVerifyCode;

  /// No description provided for @resetStepNewPassword.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호 설정'**
  String get resetStepNewPassword;

  /// No description provided for @resetTimeLeft.
  ///
  /// In ko, this message translates to:
  /// **'남은 시간 {time}'**
  String resetTimeLeft(String time);

  /// No description provided for @resetTimedOut.
  ///
  /// In ko, this message translates to:
  /// **'입력 시간이 초과되었습니다.'**
  String get resetTimedOut;

  /// No description provided for @resetCodeVerified.
  ///
  /// In ko, this message translates to:
  /// **'코드 인증 성공!'**
  String get resetCodeVerified;

  /// No description provided for @resetPasswordMismatch.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 일치하지 않습니다.'**
  String get resetPasswordMismatch;

  /// No description provided for @actionSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get actionSave;

  /// No description provided for @actionEdit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get actionEdit;

  /// No description provided for @actionEditing.
  ///
  /// In ko, this message translates to:
  /// **'수정 중'**
  String get actionEditing;

  /// No description provided for @actionLink.
  ///
  /// In ko, this message translates to:
  /// **'연동하기'**
  String get actionLink;

  /// No description provided for @actionLogout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get actionLogout;

  /// No description provided for @actionSearchClear.
  ///
  /// In ko, this message translates to:
  /// **'검색어 지우기'**
  String get actionSearchClear;

  /// No description provided for @fieldPhone.
  ///
  /// In ko, this message translates to:
  /// **'전화번호'**
  String get fieldPhone;

  /// No description provided for @fieldCurrentPassword.
  ///
  /// In ko, this message translates to:
  /// **'기존 비밀번호'**
  String get fieldCurrentPassword;

  /// No description provided for @loginMethod.
  ///
  /// In ko, this message translates to:
  /// **'로그인 방식'**
  String get loginMethod;

  /// No description provided for @noName.
  ///
  /// In ko, this message translates to:
  /// **'이름 없음'**
  String get noName;

  /// No description provided for @profileTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 정보'**
  String get profileTitle;

  /// No description provided for @profileNoChanges.
  ///
  /// In ko, this message translates to:
  /// **'변경된 내용이 없습니다.'**
  String get profileNoChanges;

  /// No description provided for @profileSaved.
  ///
  /// In ko, this message translates to:
  /// **'성공적으로 변경되었습니다.'**
  String get profileSaved;

  /// No description provided for @profileSettingsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'화면 테마, 제어판 화면, 알람 소리·진동'**
  String get profileSettingsSubtitle;

  /// No description provided for @profileTotalBoard.
  ///
  /// In ko, this message translates to:
  /// **'통합 소요 기록'**
  String get profileTotalBoard;

  /// No description provided for @passwordSection.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get passwordSection;

  /// No description provided for @passwordChange.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 변경'**
  String get passwordChange;

  /// No description provided for @passwordAllRequired.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 모두 입력해주세요.'**
  String get passwordAllRequired;

  /// No description provided for @passwordSameAsOld.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호가 기존 비밀번호와 동일합니다.'**
  String get passwordSameAsOld;

  /// No description provided for @withdrawTitle.
  ///
  /// In ko, this message translates to:
  /// **'계정 탈퇴'**
  String get withdrawTitle;

  /// No description provided for @withdrawNote.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴하면 계정 정보와 시설 소속 정보가 모두 삭제되며 되돌릴 수 없습니다.'**
  String get withdrawNote;

  /// No description provided for @withdrawConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'정말 탈퇴하시겠습니까?'**
  String get withdrawConfirmTitle;

  /// No description provided for @withdrawConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'계정 정보와 시설 소속 정보가 모두 삭제되며 되돌릴 수 없습니다.'**
  String get withdrawConfirmBody;

  /// No description provided for @withdrawConfirmAction.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴하기'**
  String get withdrawConfirmAction;

  /// No description provided for @alarmsAllTitle.
  ///
  /// In ko, this message translates to:
  /// **'전체 알람'**
  String get alarmsAllTitle;

  /// No description provided for @alarmSearchByFacility.
  ///
  /// In ko, this message translates to:
  /// **'시설 이름으로 검색...'**
  String get alarmSearchByFacility;

  /// No description provided for @alarmSearchByRoom.
  ///
  /// In ko, this message translates to:
  /// **'룸 이름으로 검색...'**
  String get alarmSearchByRoom;

  /// No description provided for @alarmSearchByName.
  ///
  /// In ko, this message translates to:
  /// **'알람 이름으로 검색...'**
  String get alarmSearchByName;

  /// No description provided for @alarmFieldName.
  ///
  /// In ko, this message translates to:
  /// **'알람 명'**
  String get alarmFieldName;

  /// No description provided for @alarmFieldRoom.
  ///
  /// In ko, this message translates to:
  /// **'룸 이름'**
  String get alarmFieldRoom;

  /// No description provided for @alarmFieldFacility.
  ///
  /// In ko, this message translates to:
  /// **'시설 이름'**
  String get alarmFieldFacility;

  /// No description provided for @alarmStatusAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get alarmStatusAll;

  /// No description provided for @alarmStatusActive.
  ///
  /// In ko, this message translates to:
  /// **'진행중'**
  String get alarmStatusActive;

  /// No description provided for @alarmStatusEnded.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get alarmStatusEnded;

  /// No description provided for @alarmGroupToggle.
  ///
  /// In ko, this message translates to:
  /// **'묶어서 보기'**
  String get alarmGroupToggle;

  /// No description provided for @alarmShort.
  ///
  /// In ko, this message translates to:
  /// **'알람'**
  String get alarmShort;

  /// No description provided for @statusNormal.
  ///
  /// In ko, this message translates to:
  /// **'정상'**
  String get statusNormal;

  /// No description provided for @statusActiveAlarms.
  ///
  /// In ko, this message translates to:
  /// **'진행 중 알람'**
  String get statusActiveAlarms;

  /// No description provided for @countCases.
  ///
  /// In ko, this message translates to:
  /// **'{label} {count}건'**
  String countCases(String label, int count);

  /// No description provided for @facilitiesTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 시설'**
  String get facilitiesTitle;

  /// No description provided for @facilitiesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'등록된 시설이 없습니다.'**
  String get facilitiesEmpty;

  /// No description provided for @facilitiesNoneVisible.
  ///
  /// In ko, this message translates to:
  /// **'조회할 수 있는 시설이 없습니다.'**
  String get facilitiesNoneVisible;

  /// No description provided for @roomsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'등록된 호실이 없습니다.'**
  String get roomsEmpty;

  /// No description provided for @roomCount.
  ///
  /// In ko, this message translates to:
  /// **'호실 {count}개'**
  String roomCount(int count);

  /// No description provided for @permissionLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'권한 조회 실패: {message}'**
  String permissionLoadFailed(String message);

  /// No description provided for @errorPrefix.
  ///
  /// In ko, this message translates to:
  /// **'오류: {message}'**
  String errorPrefix(String message);

  /// No description provided for @chartFilterTitle.
  ///
  /// In ko, this message translates to:
  /// **'조회 조건'**
  String get chartFilterTitle;

  /// No description provided for @chartRoom.
  ///
  /// In ko, this message translates to:
  /// **'호실'**
  String get chartRoom;

  /// No description provided for @chartRoomUnnamed.
  ///
  /// In ko, this message translates to:
  /// **'이름 없는 호실'**
  String get chartRoomUnnamed;

  /// No description provided for @chartResolution.
  ///
  /// In ko, this message translates to:
  /// **'해상도'**
  String get chartResolution;

  /// No description provided for @chartRes10s.
  ///
  /// In ko, this message translates to:
  /// **'10초 단위'**
  String get chartRes10s;

  /// No description provided for @chartRes1m.
  ///
  /// In ko, this message translates to:
  /// **'1분 단위'**
  String get chartRes1m;

  /// No description provided for @chartRes5m.
  ///
  /// In ko, this message translates to:
  /// **'5분 단위'**
  String get chartRes5m;

  /// No description provided for @chartRes1h.
  ///
  /// In ko, this message translates to:
  /// **'1시간 단위'**
  String get chartRes1h;

  /// No description provided for @chartRange.
  ///
  /// In ko, this message translates to:
  /// **'조회 기간'**
  String get chartRange;

  /// No description provided for @chartRange1h.
  ///
  /// In ko, this message translates to:
  /// **'최근 1시간'**
  String get chartRange1h;

  /// No description provided for @chartRange12h.
  ///
  /// In ko, this message translates to:
  /// **'최근 12시간'**
  String get chartRange12h;

  /// No description provided for @chartRange1d.
  ///
  /// In ko, this message translates to:
  /// **'최근 1일'**
  String get chartRange1d;

  /// No description provided for @chartRange7d.
  ///
  /// In ko, this message translates to:
  /// **'최근 7일'**
  String get chartRange7d;

  /// No description provided for @chartRange15d.
  ///
  /// In ko, this message translates to:
  /// **'최근 15일'**
  String get chartRange15d;

  /// No description provided for @chartApply.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get chartApply;

  /// No description provided for @chartGroups.
  ///
  /// In ko, this message translates to:
  /// **'데이터 그룹'**
  String get chartGroups;

  /// No description provided for @chartNoGroups.
  ///
  /// In ko, this message translates to:
  /// **'등록된 그룹이 없습니다.'**
  String get chartNoGroups;

  /// No description provided for @chartPickManually.
  ///
  /// In ko, this message translates to:
  /// **'직접 선택'**
  String get chartPickManually;

  /// No description provided for @chartPickItems.
  ///
  /// In ko, this message translates to:
  /// **'표시할 항목을 고르세요'**
  String get chartPickItems;

  /// No description provided for @chartGroupItems.
  ///
  /// In ko, this message translates to:
  /// **'이 그룹에 묶인 항목'**
  String get chartGroupItems;

  /// No description provided for @chartTooManySeries.
  ///
  /// In ko, this message translates to:
  /// **'{shown}개를 한 번에 그리면 알아보기 어렵습니다. {limit}개 이하를 권합니다.'**
  String chartTooManySeries(int shown, int limit);

  /// No description provided for @chartSeriesN.
  ///
  /// In ko, this message translates to:
  /// **'시리즈 {index}'**
  String chartSeriesN(int index);

  /// No description provided for @chartSummary.
  ///
  /// In ko, this message translates to:
  /// **'구간 요약'**
  String get chartSummary;

  /// No description provided for @chartMin.
  ///
  /// In ko, this message translates to:
  /// **'최소'**
  String get chartMin;

  /// No description provided for @chartAvg.
  ///
  /// In ko, this message translates to:
  /// **'평균'**
  String get chartAvg;

  /// No description provided for @chartMax.
  ///
  /// In ko, this message translates to:
  /// **'최대'**
  String get chartMax;

  /// No description provided for @chartNoData.
  ///
  /// In ko, this message translates to:
  /// **'조회된 데이터가 없습니다.'**
  String get chartNoData;

  /// No description provided for @chartNoValidData.
  ///
  /// In ko, this message translates to:
  /// **'유효한 그래프 데이터가 없습니다.'**
  String get chartNoValidData;

  /// No description provided for @chartLowerLimit.
  ///
  /// In ko, this message translates to:
  /// **'하한 {value}'**
  String chartLowerLimit(String value);

  /// No description provided for @chartUpperLimit.
  ///
  /// In ko, this message translates to:
  /// **'상한 {value}'**
  String chartUpperLimit(String value);

  /// No description provided for @chartHideBaseline.
  ///
  /// In ko, this message translates to:
  /// **'기준선 숨기기'**
  String get chartHideBaseline;

  /// No description provided for @chartShowBaseline.
  ///
  /// In ko, this message translates to:
  /// **'기준선 표시'**
  String get chartShowBaseline;

  /// No description provided for @backToFacilities.
  ///
  /// In ko, this message translates to:
  /// **'내 시설 목록으로'**
  String get backToFacilities;

  /// No description provided for @facilityFallbackName.
  ///
  /// In ko, this message translates to:
  /// **'시설 {id}'**
  String facilityFallbackName(String id);

  /// No description provided for @navMonitoring.
  ///
  /// In ko, this message translates to:
  /// **'모니터링'**
  String get navMonitoring;

  /// No description provided for @navChart.
  ///
  /// In ko, this message translates to:
  /// **'차트'**
  String get navChart;

  /// No description provided for @navBoard.
  ///
  /// In ko, this message translates to:
  /// **'소요기록'**
  String get navBoard;

  /// No description provided for @navMessenger.
  ///
  /// In ko, this message translates to:
  /// **'메신저'**
  String get navMessenger;

  /// No description provided for @navAlarm.
  ///
  /// In ko, this message translates to:
  /// **'알람'**
  String get navAlarm;

  /// No description provided for @alarmSearchByAlarmOrRoom.
  ///
  /// In ko, this message translates to:
  /// **'알람 명으로 검색...'**
  String get alarmSearchByAlarmOrRoom;

  /// No description provided for @alarmFieldRoomId.
  ///
  /// In ko, this message translates to:
  /// **'룸 ID'**
  String get alarmFieldRoomId;

  /// No description provided for @chartPageTitle.
  ///
  /// In ko, this message translates to:
  /// **'데이터 차트'**
  String get chartPageTitle;

  /// No description provided for @roomLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'호실 조회 실패: {message}'**
  String roomLoadFailed(String message);

  /// No description provided for @roomQueryFailed.
  ///
  /// In ko, this message translates to:
  /// **'호실 조회 오류: {message}'**
  String roomQueryFailed(String message);

  /// No description provided for @groupLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'그룹 로드 오류: {message}'**
  String groupLoadFailed(String message);

  /// No description provided for @chartFailed.
  ///
  /// In ko, this message translates to:
  /// **'차트 오류: {message}'**
  String chartFailed(String message);

  /// No description provided for @roomPickerTitle.
  ///
  /// In ko, this message translates to:
  /// **'호실 선택'**
  String get roomPickerTitle;

  /// No description provided for @panelControlBadge.
  ///
  /// In ko, this message translates to:
  /// **'제어'**
  String get panelControlBadge;

  /// No description provided for @panelInputHint.
  ///
  /// In ko, this message translates to:
  /// **'입력'**
  String get panelInputHint;

  /// No description provided for @panelConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get panelConfirm;

  /// No description provided for @panelValueRequired.
  ///
  /// In ko, this message translates to:
  /// **'보낼 값을 먼저 입력하세요.'**
  String get panelValueRequired;

  /// No description provided for @panelNotConnected.
  ///
  /// In ko, this message translates to:
  /// **'설비와 연결이 끊겨 있어 보낼 수 없습니다.'**
  String get panelNotConnected;

  /// No description provided for @panelCommandSent.
  ///
  /// In ko, this message translates to:
  /// **'{item} 값을 보냈습니다. 설비가 반영하면 값이 바뀝니다.'**
  String panelCommandSent(String item);

  /// No description provided for @panelCommandOk.
  ///
  /// In ko, this message translates to:
  /// **'{item} 설정이 반영되었습니다.'**
  String panelCommandOk(String item);

  /// No description provided for @panelCommandFailed.
  ///
  /// In ko, this message translates to:
  /// **'{item} 설정이 거부되었습니다.'**
  String panelCommandFailed(String item);

  /// No description provided for @chatGroupPickMembers.
  ///
  /// In ko, this message translates to:
  /// **'함께할 사람'**
  String get chatGroupPickMembers;

  /// No description provided for @chatGroupNoMembers.
  ///
  /// In ko, this message translates to:
  /// **'이 시설에 등록된 다른 사람이 없습니다.'**
  String get chatGroupNoMembers;

  /// No description provided for @chatGroupNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'방 이름을 입력하세요.'**
  String get chatGroupNameRequired;

  /// No description provided for @chatGroupMemberRequired.
  ///
  /// In ko, this message translates to:
  /// **'한 명 이상 선택하세요.'**
  String get chatGroupMemberRequired;

  /// No description provided for @chatGroupSelected.
  ///
  /// In ko, this message translates to:
  /// **'{count}명 선택'**
  String chatGroupSelected(int count);

  /// No description provided for @chatGroupCreated.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 방을 만들었습니다.'**
  String chatGroupCreated(String name);

  /// No description provided for @chatMembersLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'구성원 목록을 불러오지 못했습니다. {reason}'**
  String chatMembersLoadFailed(String reason);

  /// No description provided for @signupPasswordConfirm.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 확인'**
  String get signupPasswordConfirm;

  /// No description provided for @signupPasswordMismatch.
  ///
  /// In ko, this message translates to:
  /// **'두 비밀번호가 다릅니다.'**
  String get signupPasswordMismatch;

  /// No description provided for @signupPasswordTooShort.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 {min}자 이상이어야 합니다.'**
  String signupPasswordTooShort(int min);

  /// No description provided for @signupEmailInvalid.
  ///
  /// In ko, this message translates to:
  /// **'이메일 주소 형식이 맞는지 확인하세요.'**
  String get signupEmailInvalid;

  /// No description provided for @loginSuccess.
  ///
  /// In ko, this message translates to:
  /// **'로그인되었습니다.'**
  String get loginSuccess;

  /// No description provided for @signupSuccess.
  ///
  /// In ko, this message translates to:
  /// **'계정이 만들어졌습니다. 로그인해 주세요.'**
  String get signupSuccess;

  /// No description provided for @resetPasswordDone.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 변경되었습니다.'**
  String get resetPasswordDone;

  /// No description provided for @facilityRegisterDone.
  ///
  /// In ko, this message translates to:
  /// **'시설이 등록되었습니다.'**
  String get facilityRegisterDone;

  /// No description provided for @facilityUnlinkDone.
  ///
  /// In ko, this message translates to:
  /// **'시설 연결을 해제했습니다.'**
  String get facilityUnlinkDone;

  /// No description provided for @withdrawDone.
  ///
  /// In ko, this message translates to:
  /// **'계정이 삭제되었습니다.'**
  String get withdrawDone;

  /// No description provided for @chartSeriesSummary.
  ///
  /// In ko, this message translates to:
  /// **'{group} · {count}개 표시'**
  String chartSeriesSummary(String group, int count);

  /// No description provided for @roomSetpointShort.
  ///
  /// In ko, this message translates to:
  /// **'목표'**
  String get roomSetpointShort;

  /// No description provided for @roomStatusDefrost.
  ///
  /// In ko, this message translates to:
  /// **'제상'**
  String get roomStatusDefrost;

  /// No description provided for @roomStatusCompressor.
  ///
  /// In ko, this message translates to:
  /// **'콤프'**
  String get roomStatusCompressor;

  /// No description provided for @roomStatusOn.
  ///
  /// In ko, this message translates to:
  /// **'ON'**
  String get roomStatusOn;

  /// No description provided for @roomStatusOff.
  ///
  /// In ko, this message translates to:
  /// **'OFF'**
  String get roomStatusOff;

  /// No description provided for @chartNoRecordsFor.
  ///
  /// In ko, this message translates to:
  /// **'기록이 없는 항목: {names}'**
  String chartNoRecordsFor(String names);

  /// No description provided for @editorBodyHint.
  ///
  /// In ko, this message translates to:
  /// **'작업 내용을 적어 주세요.'**
  String get editorBodyHint;

  /// No description provided for @discardDraftTitle.
  ///
  /// In ko, this message translates to:
  /// **'쓰던 글을 버릴까요?'**
  String get discardDraftTitle;

  /// No description provided for @discardDraftBody.
  ///
  /// In ko, this message translates to:
  /// **'아직 올리지 않았습니다. 나가면 쓴 내용이 사라집니다.'**
  String get discardDraftBody;

  /// No description provided for @discardDraftKeep.
  ///
  /// In ko, this message translates to:
  /// **'계속 쓰기'**
  String get discardDraftKeep;

  /// No description provided for @discardDraftLeave.
  ///
  /// In ko, this message translates to:
  /// **'버리고 나가기'**
  String get discardDraftLeave;

  /// No description provided for @discardChangesTitle.
  ///
  /// In ko, this message translates to:
  /// **'바꾼 내용을 버릴까요?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesBody.
  ///
  /// In ko, this message translates to:
  /// **'아직 저장하지 않았습니다. 나가면 바꾼 내용이 사라집니다.'**
  String get discardChangesBody;

  /// No description provided for @chartSafeRangeTitle.
  ///
  /// In ko, this message translates to:
  /// **'안전 범위 선'**
  String get chartSafeRangeTitle;

  /// No description provided for @chartSafeRangeHint.
  ///
  /// In ko, this message translates to:
  /// **'항목마다 정해 둔 상·하한을 가로 점선으로 겹쳐 그립니다.'**
  String get chartSafeRangeHint;

  /// No description provided for @chartSafeRangeNone.
  ///
  /// In ko, this message translates to:
  /// **'선택한 항목에 정해진 상·하한이 없습니다.'**
  String get chartSafeRangeNone;

  /// No description provided for @navOverview.
  ///
  /// In ko, this message translates to:
  /// **'개괄'**
  String get navOverview;

  /// No description provided for @overviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'전체 현황'**
  String get overviewTitle;

  /// No description provided for @overviewSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'시설 이름으로 찾기'**
  String get overviewSearchHint;

  /// No description provided for @overviewRoomCount.
  ///
  /// In ko, this message translates to:
  /// **'호실 {count}곳'**
  String overviewRoomCount(int count);

  /// No description provided for @overviewNoFacilities.
  ///
  /// In ko, this message translates to:
  /// **'등록된 시설이 없습니다.'**
  String get overviewNoFacilities;

  /// No description provided for @overviewAllNormal.
  ///
  /// In ko, this message translates to:
  /// **'모든 호실 정상'**
  String get overviewAllNormal;

  /// No description provided for @overviewWatching.
  ///
  /// In ko, this message translates to:
  /// **'호실 {count}곳 감시 중'**
  String overviewWatching(int count);

  /// No description provided for @overviewAttention.
  ///
  /// In ko, this message translates to:
  /// **'확인할 호실 {count}곳'**
  String overviewAttention(int count);

  /// No description provided for @roomStateDrift.
  ///
  /// In ko, this message translates to:
  /// **'이탈'**
  String get roomStateDrift;

  /// No description provided for @roomStateNoData.
  ///
  /// In ko, this message translates to:
  /// **'값 없음'**
  String get roomStateNoData;

  /// No description provided for @roomStatusFault.
  ///
  /// In ko, this message translates to:
  /// **'이상'**
  String get roomStatusFault;

  /// No description provided for @roomStatusCint.
  ///
  /// In ko, this message translates to:
  /// **'CINT'**
  String get roomStatusCint;

  /// No description provided for @roomStatusHigh.
  ///
  /// In ko, this message translates to:
  /// **'HIGH'**
  String get roomStatusHigh;

  /// No description provided for @searchNoResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다.'**
  String get searchNoResults;

  /// No description provided for @alarmsNone.
  ///
  /// In ko, this message translates to:
  /// **'조회할 수 있는 알람이 없습니다.'**
  String get alarmsNone;

  /// No description provided for @alarmNameMissing.
  ///
  /// In ko, this message translates to:
  /// **'알람 이름 없음'**
  String get alarmNameMissing;

  /// No description provided for @roomNameMissing.
  ///
  /// In ko, this message translates to:
  /// **'호실 이름 없음'**
  String get roomNameMissing;

  /// No description provided for @facilityNameMissing.
  ///
  /// In ko, this message translates to:
  /// **'시설 이름 없음'**
  String get facilityNameMissing;

  /// No description provided for @facilityRegister.
  ///
  /// In ko, this message translates to:
  /// **'시설 등록'**
  String get facilityRegister;

  /// No description provided for @facilityAccessCode.
  ///
  /// In ko, this message translates to:
  /// **'시설 접근 코드'**
  String get facilityAccessCode;

  /// No description provided for @facilityRegistered.
  ///
  /// In ko, this message translates to:
  /// **'등록된 시설'**
  String get facilityRegistered;

  /// No description provided for @facilityUnlink.
  ///
  /// In ko, this message translates to:
  /// **'해제'**
  String get facilityUnlink;

  /// No description provided for @facilityRegisterFailed.
  ///
  /// In ko, this message translates to:
  /// **'등록 실패: {message}'**
  String facilityRegisterFailed(String message);

  /// No description provided for @facilityRegisterTitle.
  ///
  /// In ko, this message translates to:
  /// **'시설 등록 페이지'**
  String get facilityRegisterTitle;

  /// No description provided for @facilityRegisterAdminNote.
  ///
  /// In ko, this message translates to:
  /// **'관리자 및 개발자는 시설 등록이 필요하지 않습니다.'**
  String get facilityRegisterAdminNote;

  /// No description provided for @facilityUnnamed.
  ///
  /// In ko, this message translates to:
  /// **'이름 없는 시설'**
  String get facilityUnnamed;

  /// No description provided for @boardNewPost.
  ///
  /// In ko, this message translates to:
  /// **'새 글 작성'**
  String get boardNewPost;

  /// No description provided for @boardSearchAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get boardSearchAll;

  /// No description provided for @boardTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get boardTitle;

  /// No description provided for @boardAuthor.
  ///
  /// In ko, this message translates to:
  /// **'작성자'**
  String get boardAuthor;

  /// No description provided for @boardBody.
  ///
  /// In ko, this message translates to:
  /// **'내용'**
  String get boardBody;

  /// No description provided for @boardSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'검색어를 입력하세요'**
  String get boardSearchHint;

  /// No description provided for @actionSearch.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get actionSearch;

  /// No description provided for @boardEmpty.
  ///
  /// In ko, this message translates to:
  /// **'등록된 포스트가 없습니다.'**
  String get boardEmpty;

  /// No description provided for @boardPostMeta.
  ///
  /// In ko, this message translates to:
  /// **'[{facility}] 작성자: {author}'**
  String boardPostMeta(String facility, String author);

  /// No description provided for @pageFirst.
  ///
  /// In ko, this message translates to:
  /// **'첫 페이지'**
  String get pageFirst;

  /// No description provided for @pagePrev.
  ///
  /// In ko, this message translates to:
  /// **'이전 페이지'**
  String get pagePrev;

  /// No description provided for @pageNext.
  ///
  /// In ko, this message translates to:
  /// **'다음 페이지'**
  String get pageNext;

  /// No description provided for @pageLast.
  ///
  /// In ko, this message translates to:
  /// **'마지막 페이지'**
  String get pageLast;

  /// No description provided for @postNoTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목 없음'**
  String get postNoTitle;

  /// No description provided for @postMeta.
  ///
  /// In ko, this message translates to:
  /// **'작성자: {author} · 작성일: {date}'**
  String postMeta(String author, String date);

  /// No description provided for @actionDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get actionDelete;

  /// No description provided for @commentsCount.
  ///
  /// In ko, this message translates to:
  /// **'댓글 {count}'**
  String commentsCount(int count);

  /// No description provided for @commentDelete.
  ///
  /// In ko, this message translates to:
  /// **'댓글 삭제'**
  String get commentDelete;

  /// No description provided for @commentsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'등록된 댓글이 없습니다.'**
  String get commentsEmpty;

  /// No description provided for @commentHint.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 입력하세요...'**
  String get commentHint;

  /// No description provided for @commentSubmit.
  ///
  /// In ko, this message translates to:
  /// **'등록'**
  String get commentSubmit;

  /// No description provided for @postLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'게시글 로드 실패: {message}'**
  String postLoadFailed(String message);

  /// No description provided for @postDeleted.
  ///
  /// In ko, this message translates to:
  /// **'삭제되었습니다.'**
  String get postDeleted;

  /// No description provided for @postDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패: {message}'**
  String postDeleteFailed(String message);

  /// No description provided for @commentFailed.
  ///
  /// In ko, this message translates to:
  /// **'댓글 작성 실패: {message}'**
  String commentFailed(String message);

  /// No description provided for @commentDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'댓글 삭제 실패: {message}'**
  String commentDeleteFailed(String message);

  /// No description provided for @dataUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러올 수 없습니다.'**
  String get dataUnavailable;

  /// No description provided for @postDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'게시글 상세 조회'**
  String get postDetailTitle;

  /// No description provided for @imageAttachFailed.
  ///
  /// In ko, this message translates to:
  /// **'이미지 첨부 실패: {message}'**
  String imageAttachFailed(String message);

  /// No description provided for @postTitleRequired.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력해주세요.'**
  String get postTitleRequired;

  /// No description provided for @postCreated.
  ///
  /// In ko, this message translates to:
  /// **'게시글이 작성되었습니다.'**
  String get postCreated;

  /// No description provided for @postCreateFailed.
  ///
  /// In ko, this message translates to:
  /// **'게시글 작성 실패: {message}'**
  String postCreateFailed(String message);

  /// No description provided for @postCreateTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 게시글'**
  String get postCreateTitle;

  /// No description provided for @postCreateSubmit.
  ///
  /// In ko, this message translates to:
  /// **'게시글 등록하기'**
  String get postCreateSubmit;

  /// No description provided for @postSourceLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'원문 로드 실패: {message}'**
  String postSourceLoadFailed(String message);

  /// No description provided for @postUpdated.
  ///
  /// In ko, this message translates to:
  /// **'수정 완료되었습니다.'**
  String get postUpdated;

  /// No description provided for @postUpdateFailed.
  ///
  /// In ko, this message translates to:
  /// **'수정 실패: {message}'**
  String postUpdateFailed(String message);

  /// No description provided for @postEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'게시글 수정'**
  String get postEditTitle;

  /// No description provided for @postEditSubmit.
  ///
  /// In ko, this message translates to:
  /// **'수정 완료하기'**
  String get postEditSubmit;

  /// No description provided for @totalBoardTitle.
  ///
  /// In ko, this message translates to:
  /// **'통합 소요 기록 (관리자)'**
  String get totalBoardTitle;

  /// No description provided for @totalBoardSearch.
  ///
  /// In ko, this message translates to:
  /// **'통합 검색 및 필터'**
  String get totalBoardSearch;

  /// No description provided for @boardPageTitle.
  ///
  /// In ko, this message translates to:
  /// **'소요 기록'**
  String get boardPageTitle;

  /// No description provided for @boardSearchTitle.
  ///
  /// In ko, this message translates to:
  /// **'게시글 검색'**
  String get boardSearchTitle;

  /// No description provided for @chatMenu.
  ///
  /// In ko, this message translates to:
  /// **'메뉴'**
  String get chatMenu;

  /// No description provided for @chatNoMessages.
  ///
  /// In ko, this message translates to:
  /// **'메시지가 없습니다.'**
  String get chatNoMessages;

  /// No description provided for @chatReply.
  ///
  /// In ko, this message translates to:
  /// **'답장'**
  String get chatReply;

  /// No description provided for @chatPinToggle.
  ///
  /// In ko, this message translates to:
  /// **'고정 토글'**
  String get chatPinToggle;

  /// No description provided for @chatReplyingTo.
  ///
  /// In ko, this message translates to:
  /// **'답장: {text}'**
  String chatReplyingTo(String text);

  /// No description provided for @actionClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get actionClose;

  /// No description provided for @chatAttach.
  ///
  /// In ko, this message translates to:
  /// **'첨부'**
  String get chatAttach;

  /// No description provided for @chatInputHint.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 입력하세요...'**
  String get chatInputHint;

  /// No description provided for @chatSend.
  ///
  /// In ko, this message translates to:
  /// **'보내기'**
  String get chatSend;

  /// No description provided for @chatRoomsManage.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 관리'**
  String get chatRoomsManage;

  /// No description provided for @chatGroupCreate.
  ///
  /// In ko, this message translates to:
  /// **'단체 채팅방 생성'**
  String get chatGroupCreate;

  /// No description provided for @chatRoomsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'참여 중인 채팅방이 없습니다.'**
  String get chatRoomsEmpty;

  /// No description provided for @chatRoomName.
  ///
  /// In ko, this message translates to:
  /// **'방 이름'**
  String get chatRoomName;

  /// No description provided for @chatInviteUsers.
  ///
  /// In ko, this message translates to:
  /// **'초대할 유저 ID (콤마로 구분)'**
  String get chatInviteUsers;

  /// No description provided for @actionCreate.
  ///
  /// In ko, this message translates to:
  /// **'생성'**
  String get actionCreate;

  /// No description provided for @chatLeaveRoom.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 나가기 (관리자는 단체방 삭제 가능)'**
  String get chatLeaveRoom;

  /// No description provided for @chatSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'메시지 검색...'**
  String get chatSearchHint;

  /// No description provided for @chatRoom.
  ///
  /// In ko, this message translates to:
  /// **'채팅방'**
  String get chatRoom;

  /// No description provided for @chatMembers.
  ///
  /// In ko, this message translates to:
  /// **'참여중인 유저 목록'**
  String get chatMembers;

  /// No description provided for @chatRoomFallback.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 {id}'**
  String chatRoomFallback(String id);

  /// No description provided for @navHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// No description provided for @appTagline.
  ///
  /// In ko, this message translates to:
  /// **'냉동창고 실시간 관제 · 모니터링 시스템'**
  String get appTagline;

  /// No description provided for @findIdCheck.
  ///
  /// In ko, this message translates to:
  /// **'가입 여부 확인하기'**
  String get findIdCheck;

  /// No description provided for @editorImageAttach.
  ///
  /// In ko, this message translates to:
  /// **'이미지 첨부'**
  String get editorImageAttach;

  /// No description provided for @loginMethodEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get loginMethodEmail;

  /// No description provided for @notFound.
  ///
  /// In ko, this message translates to:
  /// **'페이지를 찾을 수 없습니다.'**
  String get notFound;

  /// No description provided for @errorServerUnreachable.
  ///
  /// In ko, this message translates to:
  /// **'서버에 연결할 수 없습니다. 네트워크 상태를 확인해주세요.'**
  String get errorServerUnreachable;

  /// No description provided for @errorServerTimeout.
  ///
  /// In ko, this message translates to:
  /// **'서버 응답이 없습니다. 네트워크 상태를 확인해주세요.'**
  String get errorServerTimeout;

  /// No description provided for @errorRequestFailed.
  ///
  /// In ko, this message translates to:
  /// **'요청을 처리하지 못했습니다.'**
  String get errorRequestFailed;

  /// No description provided for @googleOnlyOnApp.
  ///
  /// In ko, this message translates to:
  /// **'구글 로그인은 앱에서만 사용할 수 있습니다.'**
  String get googleOnlyOnApp;

  /// No description provided for @appleOnlyOnApp.
  ///
  /// In ko, this message translates to:
  /// **'애플 로그인은 앱에서만 사용할 수 있습니다.'**
  String get appleOnlyOnApp;

  /// No description provided for @googleNotConfigured.
  ///
  /// In ko, this message translates to:
  /// **'구글 로그인이 아직 설정되지 않았습니다. Firebase 프로젝트에 이 앱의 OAuth 클라이언트(SHA-1 지문)를 등록해야 합니다.'**
  String get googleNotConfigured;

  /// No description provided for @googleSignInFailed.
  ///
  /// In ko, this message translates to:
  /// **'구글 로그인을 진행할 수 없습니다. ({reason})'**
  String googleSignInFailed(String reason);

  /// No description provided for @appleSignInFailed.
  ///
  /// In ko, this message translates to:
  /// **'애플 로그인을 진행할 수 없습니다. ({reason})'**
  String appleSignInFailed(String reason);

  /// No description provided for @googleDefaultName.
  ///
  /// In ko, this message translates to:
  /// **'구글유저'**
  String get googleDefaultName;

  /// No description provided for @appleDefaultName.
  ///
  /// In ko, this message translates to:
  /// **'애플유저'**
  String get appleDefaultName;

  /// No description provided for @notificationFallbackTitle.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get notificationFallbackTitle;

  /// No description provided for @alarmRepeatSuffix.
  ///
  /// In ko, this message translates to:
  /// **'{body} (다시 알림 {index}/{total})'**
  String alarmRepeatSuffix(String body, int index, int total);

  /// No description provided for @channelSoundVibe.
  ///
  /// In ko, this message translates to:
  /// **'알람 (소리+진동)'**
  String get channelSoundVibe;

  /// No description provided for @channelSoundVibeDesc.
  ///
  /// In ko, this message translates to:
  /// **'소리와 진동을 모두 사용하는 알람'**
  String get channelSoundVibeDesc;

  /// No description provided for @channelSoundOnly.
  ///
  /// In ko, this message translates to:
  /// **'알람 (소리만)'**
  String get channelSoundOnly;

  /// No description provided for @channelSoundOnlyDesc.
  ///
  /// In ko, this message translates to:
  /// **'소리만 사용하는 알람'**
  String get channelSoundOnlyDesc;

  /// No description provided for @channelVibeOnly.
  ///
  /// In ko, this message translates to:
  /// **'알람 (진동만)'**
  String get channelVibeOnly;

  /// No description provided for @channelVibeOnlyDesc.
  ///
  /// In ko, this message translates to:
  /// **'진동만 사용하는 알람'**
  String get channelVibeOnlyDesc;

  /// No description provided for @channelSilent.
  ///
  /// In ko, this message translates to:
  /// **'알람 (무음)'**
  String get channelSilent;

  /// No description provided for @channelSilentDesc.
  ///
  /// In ko, this message translates to:
  /// **'소리와 진동 없이 표시만 하는 알람'**
  String get channelSilentDesc;

  /// No description provided for @panelPageTitle.
  ///
  /// In ko, this message translates to:
  /// **'시설 ID: {id} 실시간 제어판'**
  String panelPageTitle(String id);

  /// No description provided for @panelCardInfo.
  ///
  /// In ko, this message translates to:
  /// **'시설 기본 정보'**
  String get panelCardInfo;

  /// No description provided for @panelCardTemp.
  ///
  /// In ko, this message translates to:
  /// **'실제 온도'**
  String get panelCardTemp;

  /// No description provided for @panelCardDefrost.
  ///
  /// In ko, this message translates to:
  /// **'제상 정보'**
  String get panelCardDefrost;

  /// No description provided for @panelCardFaults.
  ///
  /// In ko, this message translates to:
  /// **'이상 정보'**
  String get panelCardFaults;

  /// No description provided for @panelCardInverter.
  ///
  /// In ko, this message translates to:
  /// **'인버터 정보'**
  String get panelCardInverter;

  /// No description provided for @panelCardEquipment.
  ///
  /// In ko, this message translates to:
  /// **'장비 정보'**
  String get panelCardEquipment;

  /// No description provided for @panelCardControl.
  ///
  /// In ko, this message translates to:
  /// **'제어 정보'**
  String get panelCardControl;

  /// No description provided for @panelInfoFacilityId.
  ///
  /// In ko, this message translates to:
  /// **'시설 ID'**
  String get panelInfoFacilityId;

  /// No description provided for @panelInfoRoomId.
  ///
  /// In ko, this message translates to:
  /// **'호실 ID'**
  String get panelInfoRoomId;

  /// No description provided for @panelInfoManagerId.
  ///
  /// In ko, this message translates to:
  /// **'담당 관리자 ID'**
  String get panelInfoManagerId;

  /// No description provided for @panelInfoStatus.
  ///
  /// In ko, this message translates to:
  /// **'운영 상태'**
  String get panelInfoStatus;

  /// No description provided for @panelStatusActive.
  ///
  /// In ko, this message translates to:
  /// **'정상 작동 중 (ACTIVE)'**
  String get panelStatusActive;

  /// No description provided for @chartShowAllPoints.
  ///
  /// In ko, this message translates to:
  /// **'전체 보기 ({count})'**
  String chartShowAllPoints(int count);

  /// No description provided for @chartShowLess.
  ///
  /// In ko, this message translates to:
  /// **'접기'**
  String get chartShowLess;

  /// No description provided for @pageOf.
  ///
  /// In ko, this message translates to:
  /// **'{current} / {total}'**
  String pageOf(int current, int total);

  /// No description provided for @boardSearchClear.
  ///
  /// In ko, this message translates to:
  /// **'검색어 지우기'**
  String get boardSearchClear;

  /// No description provided for @panelCurrentTemp.
  ///
  /// In ko, this message translates to:
  /// **'고내온도'**
  String get panelCurrentTemp;

  /// No description provided for @panelSetpoint.
  ///
  /// In ko, this message translates to:
  /// **'설정값'**
  String get panelSetpoint;

  /// No description provided for @unitCelsius.
  ///
  /// In ko, this message translates to:
  /// **'°C'**
  String get unitCelsius;

  /// No description provided for @panelWaitingData.
  ///
  /// In ko, this message translates to:
  /// **'데이터를 기다리는 중'**
  String get panelWaitingData;

  /// No description provided for @panelUpdatedJustNow.
  ///
  /// In ko, this message translates to:
  /// **'방금 업데이트'**
  String get panelUpdatedJustNow;

  /// No description provided for @panelUpdatedSecondsAgo.
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초 전 업데이트'**
  String panelUpdatedSecondsAgo(int seconds);

  /// No description provided for @panelUpdatedMinutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 전 업데이트'**
  String panelUpdatedMinutesAgo(int minutes);

  /// No description provided for @panelNoSignal.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분째 신호가 없습니다'**
  String panelNoSignal(int minutes);

  /// No description provided for @alarmsNoneActive.
  ///
  /// In ko, this message translates to:
  /// **'지금 진행 중인 알람이 없습니다'**
  String get alarmsNoneActive;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
