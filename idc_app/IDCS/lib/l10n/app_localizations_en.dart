// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDeviceOnly => 'These settings apply to this device only.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get themeSystem => 'System default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsPanel => 'Control panel';

  @override
  String get settingsPanelNote =>
      'Applies only to the live control panel shown inside a room.';

  @override
  String get panelBackground => 'Background';

  @override
  String get panelOpacity => 'Transparency';

  @override
  String get panelValueSize => 'Reading size';

  @override
  String get panelLedDigits => 'LED digits';

  @override
  String get panelLedDigitsNote => 'Show numbers as a seven-segment display.';

  @override
  String get panelSampleLabel => 'Room temp';

  @override
  String get backgroundNone => 'None';

  @override
  String get backgroundBlueprint => 'Blueprint';

  @override
  String get backgroundCoil => 'Cooling coil';

  @override
  String get backgroundMetal => 'Metal';

  @override
  String get backgroundGrid => 'Grid';

  @override
  String get settingsAlarmStyle => 'Alarm alerts';

  @override
  String get alarmSound => 'Sound';

  @override
  String get alarmSoundNote => 'Play a sound when an alarm arrives.';

  @override
  String get alarmVibration => 'Vibration';

  @override
  String get alarmVibrationNote => 'Vibrate when an alarm arrives.';

  @override
  String get alarmLockScreen => 'Show details on lock screen';

  @override
  String get alarmLockScreenNote =>
      'When off, the lock screen only shows that an alarm arrived.';

  @override
  String get alarmRepeat => 'Remind again';

  @override
  String alarmRepeatNote(int count) {
    return 'If an alarm goes unread, remind you at the chosen interval up to $count more times.';
  }

  @override
  String get alarmRepeatNone => 'Off';

  @override
  String alarmRepeatMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldNewPassword => 'New password';

  @override
  String get fieldConfirmPassword => 'Re-enter password';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldPhoneOptional => 'Phone (optional)';

  @override
  String get fieldVerificationCode => 'Verification code';

  @override
  String get showPassword => 'Show password';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSubmit => 'Done';

  @override
  String get orDivider => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get login => 'Sign in';

  @override
  String get loginWelcomeTitle => 'Welcome back';

  @override
  String get loginWelcomeSubtitle => 'Enter your account details to sign in.';

  @override
  String get loginMissingFields => 'Please enter both your email and password.';

  @override
  String get keepSignedIn => 'Keep me signed in';

  @override
  String get noAccountQuestion => 'Don\'t have an account? ';

  @override
  String get signUp => 'Sign up';

  @override
  String get signupTitle => 'Create an account';

  @override
  String get signupSubtitle =>
      'Fill in the details below to create your account.';

  @override
  String get signupCreateAccount => 'Create account';

  @override
  String get signupMissingFields => 'Please fill in all required fields.';

  @override
  String get signupEmailRequired => 'Please enter an email address.';

  @override
  String get signupEmailUnavailable =>
      'Your email could not be read. Please allow email access in settings.';

  @override
  String get signupAppleEmailMissing =>
      'Your Apple account did not share an email address.\nPlease enter one so the service works properly.';

  @override
  String get findId => 'Find my ID';

  @override
  String get findIdSubtitle =>
      'Enter the email you signed up with and we\'ll look up your account.';

  @override
  String get findIdEmailRequired => 'Please enter the email to look up.';

  @override
  String errorOccurred(String message) {
    return 'Something went wrong: $message';
  }

  @override
  String get findPassword => 'Forgot password';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordSubtitle =>
      'Verify your email, then set a new password.';

  @override
  String get resetStepEmail => 'Verify email';

  @override
  String get resetSendCode => 'Send code';

  @override
  String get resetStepCode => 'Enter the code';

  @override
  String get resetVerifyCode => 'Verify code';

  @override
  String get resetStepNewPassword => 'Set a new password';

  @override
  String resetTimeLeft(String time) {
    return 'Time left $time';
  }

  @override
  String get resetTimedOut => 'Time ran out. Please start again.';

  @override
  String get resetCodeVerified => 'Code verified.';

  @override
  String get resetPasswordMismatch => 'The passwords do not match.';
}
