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
