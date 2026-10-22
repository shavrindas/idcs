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
  String get settingsBackground => 'Background';

  @override
  String get settingsSnow => 'Snow in the background';

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

  @override
  String get actionSave => 'Save';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionEditing => 'Editing';

  @override
  String get actionLink => 'Link';

  @override
  String get actionLogout => 'Sign out';

  @override
  String get actionSearchClear => 'Clear search';

  @override
  String get fieldPhone => 'Phone';

  @override
  String get fieldCurrentPassword => 'Current password';

  @override
  String get loginMethod => 'Sign-in method';

  @override
  String get noName => 'No name';

  @override
  String get profileTitle => 'My profile';

  @override
  String get profileNoChanges => 'Nothing has changed.';

  @override
  String get profileSaved => 'Saved.';

  @override
  String get profileSettingsSubtitle =>
      'Appearance, control panel, alarm sound and vibration';

  @override
  String get profileTotalBoard => 'All work logs';

  @override
  String get passwordSection => 'Password';

  @override
  String get passwordChange => 'Change password';

  @override
  String get passwordAllRequired => 'Please fill in every password field.';

  @override
  String get passwordSameAsOld =>
      'The new password is the same as the current one.';

  @override
  String get withdrawTitle => 'Delete account';

  @override
  String get withdrawNote =>
      'Deleting your account removes your details and facility membership for good.';

  @override
  String get withdrawConfirmTitle => 'Delete your account?';

  @override
  String get withdrawConfirmBody =>
      'Your details and facility membership will be removed and cannot be restored.';

  @override
  String get withdrawConfirmAction => 'Delete';

  @override
  String get alarmsAllTitle => 'All alarms';

  @override
  String get alarmSearchByFacility => 'Search by facility…';

  @override
  String get alarmSearchByRoom => 'Search by room…';

  @override
  String get alarmSearchByName => 'Search by alarm name…';

  @override
  String get alarmFieldName => 'Alarm';

  @override
  String get alarmFieldRoom => 'Room';

  @override
  String get alarmFieldFacility => 'Facility';

  @override
  String get alarmRecentlyEnded => 'Recently ended';

  @override
  String get alarmStatusAll => 'All';

  @override
  String get alarmStatusActive => 'Active';

  @override
  String get alarmStatusEnded => 'Ended';

  @override
  String get alarmGroupToggle => 'Group repeats';

  @override
  String get alarmShort => 'Alarms';

  @override
  String get statusNormal => 'Normal';

  @override
  String get statusActiveAlarms => 'Active alarms';

  @override
  String countCases(String label, int count) {
    return '$label $count';
  }

  @override
  String get facilitiesTitle => 'My facilities';

  @override
  String get facilitiesEmpty => 'No facilities registered.';

  @override
  String get facilitiesNoneVisible => 'No facilities available to view.';

  @override
  String get roomsEmpty => 'No rooms registered.';

  @override
  String roomCount(int count) {
    return '$count rooms';
  }

  @override
  String permissionLoadFailed(String message) {
    return 'Could not load permissions: $message';
  }

  @override
  String errorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get chartFilterTitle => 'Query';

  @override
  String get chartRoom => 'Room';

  @override
  String get chartRoomUnnamed => 'Unnamed room';

  @override
  String get chartResolution => 'Resolution';

  @override
  String get chartRes10s => '10 seconds';

  @override
  String get chartRes1m => '1 minute';

  @override
  String get chartRes5m => '5 minutes';

  @override
  String get chartRes1h => '1 hour';

  @override
  String get chartRange => 'Period';

  @override
  String get chartRange1h => 'Last hour';

  @override
  String get chartRange12h => 'Last 12 hours';

  @override
  String get chartRange1d => 'Last day';

  @override
  String get chartRange7d => 'Last 7 days';

  @override
  String get chartRange15d => 'Last 15 days';

  @override
  String get chartApply => 'Apply';

  @override
  String get chartGroups => 'Data groups';

  @override
  String get chartNoGroups => 'No groups defined.';

  @override
  String get chartPickManually => 'Pick manually';

  @override
  String get chartPickItems => 'Choose what to plot';

  @override
  String get chartGroupItems => 'Points in this group';

  @override
  String chartTooManySeries(int shown, int limit) {
    return 'Plotting $shown at once is hard to read. $limit or fewer is easier.';
  }

  @override
  String chartSeriesN(int index) {
    return 'Series $index';
  }

  @override
  String get chartSummary => 'Range summary';

  @override
  String get chartMin => 'Min';

  @override
  String get chartAvg => 'Avg';

  @override
  String get chartMax => 'Max';

  @override
  String get chartNoData => 'No data for this query.';

  @override
  String get chartNoValidData => 'No plottable data.';

  @override
  String chartLowerLimit(String value) {
    return 'Low $value';
  }

  @override
  String chartUpperLimit(String value) {
    return 'High $value';
  }

  @override
  String get chartHideBaseline => 'Hide safe range';

  @override
  String get chartShowBaseline => 'Show safe range';

  @override
  String get backToFacilities => 'Back to my facilities';

  @override
  String facilityFallbackName(String id) {
    return 'Facility $id';
  }

  @override
  String get navMonitoring => 'Monitor';

  @override
  String get navChart => 'Charts';

  @override
  String get navBoard => 'Work log';

  @override
  String get navMessenger => 'Messages';

  @override
  String get navAlarm => 'Alarms';

  @override
  String get alarmSearchByAlarmOrRoom => 'Search by alarm name…';

  @override
  String get alarmFieldRoomId => 'Room ID';

  @override
  String get chartPageTitle => 'Data charts';

  @override
  String roomLoadFailed(String message) {
    return 'Could not load rooms: $message';
  }

  @override
  String roomQueryFailed(String message) {
    return 'Room lookup failed: $message';
  }

  @override
  String groupLoadFailed(String message) {
    return 'Could not load groups: $message';
  }

  @override
  String chartFailed(String message) {
    return 'Chart error: $message';
  }

  @override
  String get roomPickerTitle => 'Choose a room';

  @override
  String get panelControlBadge => 'Control';

  @override
  String get panelInputHint => 'Value';

  @override
  String get panelConfirm => 'Set';

  @override
  String get panelValueRequired => 'Enter a value first.';

  @override
  String get panelNotConnected =>
      'Not connected to the equipment — nothing was sent.';

  @override
  String panelCommandSent(String item) {
    return 'Sent to $item. The reading will change once the equipment applies it.';
  }

  @override
  String panelCommandOk(String item) {
    return '$item was applied.';
  }

  @override
  String panelCommandFailed(String item) {
    return '$item was rejected.';
  }

  @override
  String get chatGroupPickMembers => 'Who to include';

  @override
  String get chatGroupNoMembers =>
      'Nobody else is registered at this facility.';

  @override
  String get chatGroupNameRequired => 'Enter a room name.';

  @override
  String get chatGroupMemberRequired => 'Pick at least one person.';

  @override
  String chatGroupSelected(int count) {
    return '$count selected';
  }

  @override
  String chatGroupCreated(String name) {
    return 'Created \'$name\'.';
  }

  @override
  String chatMembersLoadFailed(String reason) {
    return 'Could not load the member list. $reason';
  }

  @override
  String get signupPasswordConfirm => 'Confirm password';

  @override
  String get signupPasswordMismatch => 'The two passwords do not match.';

  @override
  String signupPasswordTooShort(int min) {
    return 'Use at least $min characters.';
  }

  @override
  String get signupEmailInvalid => 'Check the email address format.';

  @override
  String get loginSuccess => 'Signed in.';

  @override
  String get signupSuccess => 'Account created. Please sign in.';

  @override
  String get resetPasswordDone => 'Your password has been changed.';

  @override
  String get facilityRegisterDone => 'Facility added.';

  @override
  String get facilityUnlinkDone => 'Facility unlinked.';

  @override
  String get withdrawDone => 'Your account has been deleted.';

  @override
  String chartSeriesSummary(String group, int count) {
    return '$group · $count shown';
  }

  @override
  String get roomSetpointShort => 'Set';

  @override
  String get roomStatusDefrost => 'Defrost';

  @override
  String get roomStatusCompressor => 'Comp';

  @override
  String get roomStatusOn => 'ON';

  @override
  String get roomStatusOff => 'OFF';

  @override
  String chartNoRecordsFor(String names) {
    return 'No records for: $names';
  }

  @override
  String get editorBodyHint => 'Write what happened.';

  @override
  String get discardDraftTitle => 'Discard this post?';

  @override
  String get discardDraftBody =>
      'It has not been published. Leaving will lose what you wrote.';

  @override
  String get discardDraftKeep => 'Keep writing';

  @override
  String get discardDraftLeave => 'Discard';

  @override
  String get discardChangesTitle => 'Discard your changes?';

  @override
  String get discardChangesBody =>
      'They have not been saved. Leaving will lose them.';

  @override
  String get chartLimitsEdit => 'Set limits manually';

  @override
  String get chartLimitsTitle => 'Limits';

  @override
  String get chartLimitsLow => 'Low';

  @override
  String get chartLimitsHigh => 'High';

  @override
  String get chartLimitsLocal =>
      'Saved on this device only. Alarms do not use these — for that they must be set on the point role in the web console.';

  @override
  String get chartLimitsSaved => 'Limits saved.';

  @override
  String get chartLimitsEmpty => 'No series is currently drawn.';

  @override
  String get chartSafeRangeTitle => 'Safe range lines';

  @override
  String get chartSafeRangeHint =>
      'Draws each point\'s high and low limit as a dashed line across the chart.';

  @override
  String get chartSafeRangeNone => 'The selected points have no limits set.';

  @override
  String get navOverview => 'Overview';

  @override
  String get overviewTitle => 'All facilities';

  @override
  String get overviewSearchHint => 'Find a facility';

  @override
  String overviewRoomCount(int count) {
    return '$count rooms';
  }

  @override
  String get overviewNoFacilities => 'No facilities registered.';

  @override
  String get overviewAllNormal => 'All rooms normal';

  @override
  String overviewWatching(int count) {
    return 'Watching $count rooms';
  }

  @override
  String overviewAttention(int count) {
    return '$count rooms to check';
  }

  @override
  String get roomStateDrift => 'Off target';

  @override
  String get roomStateNoData => 'No data';

  @override
  String get roomStateNormal => 'Normal';

  @override
  String overviewShowNoData(int count) {
    return 'Show $count rooms without data';
  }

  @override
  String get overviewHideNoData => 'Hide rooms without data';

  @override
  String get roomStatusFault => 'Fault';

  @override
  String get roomStatusCint => 'CINT';

  @override
  String get roomStatusHigh => 'HIGH';

  @override
  String get searchNoResults => 'No matches.';

  @override
  String get alarmsNone => 'No alarms to show.';

  @override
  String get alarmNameMissing => 'Unnamed alarm';

  @override
  String get roomNameMissing => 'Unnamed room';

  @override
  String get facilityNameMissing => 'Unnamed facility';

  @override
  String get facilityRegister => 'Add facility';

  @override
  String get facilityAccessCode => 'Facility access code';

  @override
  String get facilityRegistered => 'Registered facilities';

  @override
  String get facilityUnlink => 'Remove';

  @override
  String facilityRegisterFailed(String message) {
    return 'Could not register: $message';
  }

  @override
  String get facilityRegisterTitle => 'Add a facility';

  @override
  String get facilityRegisterAdminNote =>
      'Admins and developers do not need to register facilities.';

  @override
  String get facilityUnnamed => 'Unnamed facility';

  @override
  String get boardNewPost => 'New post';

  @override
  String get boardSearchAll => 'All';

  @override
  String get boardTitle => 'Title';

  @override
  String get boardAuthor => 'Author';

  @override
  String get boardBody => 'Body';

  @override
  String get boardSearchHint => 'Type to search';

  @override
  String get actionSearch => 'Search';

  @override
  String get boardEmpty => 'No posts yet.';

  @override
  String boardPostMeta(String facility, String author) {
    return '[$facility] by $author';
  }

  @override
  String get pageFirst => 'First page';

  @override
  String get pagePrev => 'Previous page';

  @override
  String get pageNext => 'Next page';

  @override
  String get pageLast => 'Last page';

  @override
  String get postNoTitle => 'Untitled';

  @override
  String postMeta(String author, String date) {
    return 'By $author · $date';
  }

  @override
  String get actionDelete => 'Delete';

  @override
  String commentsCount(int count) {
    return 'Comments $count';
  }

  @override
  String get commentDelete => 'Delete comment';

  @override
  String get commentsEmpty => 'No comments yet.';

  @override
  String get commentHint => 'Write a comment…';

  @override
  String get commentSubmit => 'Post';

  @override
  String postLoadFailed(String message) {
    return 'Could not load the post: $message';
  }

  @override
  String get postDeleted => 'Deleted.';

  @override
  String postDeleteFailed(String message) {
    return 'Could not delete: $message';
  }

  @override
  String commentFailed(String message) {
    return 'Could not post the comment: $message';
  }

  @override
  String commentDeleteFailed(String message) {
    return 'Could not delete the comment: $message';
  }

  @override
  String get dataUnavailable => 'Could not load the data.';

  @override
  String get postDetailTitle => 'Post';

  @override
  String imageAttachFailed(String message) {
    return 'Could not attach the image: $message';
  }

  @override
  String get postTitleRequired => 'Please enter a title.';

  @override
  String get postCreated => 'Post published.';

  @override
  String postCreateFailed(String message) {
    return 'Could not publish: $message';
  }

  @override
  String get postCreateTitle => 'New post';

  @override
  String get postCreateSubmit => 'Publish';

  @override
  String postSourceLoadFailed(String message) {
    return 'Could not load the original: $message';
  }

  @override
  String get postUpdated => 'Changes saved.';

  @override
  String postUpdateFailed(String message) {
    return 'Could not save: $message';
  }

  @override
  String get postEditTitle => 'Edit post';

  @override
  String get postEditSubmit => 'Save changes';

  @override
  String get totalBoardTitle => 'All work logs (admin)';

  @override
  String get totalBoardSearch => 'Search and filter';

  @override
  String get boardPageTitle => 'Work log';

  @override
  String get boardSearchTitle => 'Search posts';

  @override
  String get chatMenu => 'Menu';

  @override
  String get chatNoMessages => 'No messages yet.';

  @override
  String get chatReply => 'Reply';

  @override
  String get chatPinToggle => 'Pin';

  @override
  String chatReplyingTo(String text) {
    return 'Replying to: $text';
  }

  @override
  String get actionClose => 'Close';

  @override
  String get chatAttach => 'Attach';

  @override
  String get chatInputHint => 'Write a message…';

  @override
  String get chatSend => 'Send';

  @override
  String get chatRoomsManage => 'Manage rooms';

  @override
  String get chatGroupCreate => 'New group chat';

  @override
  String get chatRoomsEmpty => 'You are not in any chat rooms.';

  @override
  String get chatRoomName => 'Room name';

  @override
  String get chatInviteUsers => 'User IDs to invite (comma separated)';

  @override
  String get actionCreate => 'Create';

  @override
  String get chatLeaveRoom => 'Leave room (admins can delete group rooms)';

  @override
  String get chatSearchHint => 'Search messages…';

  @override
  String get chatRoom => 'Chat';

  @override
  String get chatMembers => 'Members';

  @override
  String chatRoomFallback(String id) {
    return 'Chat $id';
  }

  @override
  String get navHome => 'Home';

  @override
  String get appTagline => 'Live monitoring for cold storage';

  @override
  String get findIdCheck => 'Check my account';

  @override
  String get editorImageAttach => 'Attach image';

  @override
  String get loginMethodEmail => 'Email';

  @override
  String get notFound => 'Page not found.';

  @override
  String get errorServerUnreachable =>
      'Cannot reach the server. Check your network connection.';

  @override
  String get errorServerTimeout =>
      'The server did not respond. Check your network connection.';

  @override
  String get errorRequestFailed => 'The request could not be completed.';

  @override
  String get googleOnlyOnApp => 'Google sign-in is only available in the app.';

  @override
  String get appleOnlyOnApp => 'Apple sign-in is only available in the app.';

  @override
  String get googleNotConfigured =>
      'Google sign-in is not set up yet. This app\'s OAuth client (SHA-1 fingerprint) has to be registered in the Firebase project.';

  @override
  String googleSignInFailed(String reason) {
    return 'Google sign-in could not continue. ($reason)';
  }

  @override
  String appleSignInFailed(String reason) {
    return 'Apple sign-in could not continue. ($reason)';
  }

  @override
  String get googleDefaultName => 'Google user';

  @override
  String get appleDefaultName => 'Apple user';

  @override
  String get notificationFallbackTitle => 'Notification';

  @override
  String alarmRepeatSuffix(String body, int index, int total) {
    return '$body (reminder $index/$total)';
  }

  @override
  String get channelSoundVibe => 'Alarms (sound + vibration)';

  @override
  String get channelSoundVibeDesc => 'Alarms that both ring and vibrate';

  @override
  String get channelSoundOnly => 'Alarms (sound only)';

  @override
  String get channelSoundOnlyDesc => 'Alarms that ring without vibrating';

  @override
  String get channelVibeOnly => 'Alarms (vibration only)';

  @override
  String get channelVibeOnlyDesc => 'Alarms that vibrate without ringing';

  @override
  String get channelSilent => 'Alarms (silent)';

  @override
  String get channelSilentDesc => 'Alarms shown without sound or vibration';

  @override
  String panelPageTitle(String id) {
    return 'Live control panel — facility $id';
  }

  @override
  String get panelControlConfirm => 'Send this value?';

  @override
  String get panelControlSend => 'Send';

  @override
  String get panelControlWire => 'Value sent to the equipment';

  @override
  String get panelControlReadOnly =>
      'Read-only here. Use the Controls card at the top to change it.';

  @override
  String get panelControlTitle => 'Controls';

  @override
  String get panelNowTitle => 'Right now';

  @override
  String get panelNoFaults => 'No faults';

  @override
  String panelFaultCount(int count) {
    return '$count faults';
  }

  @override
  String get panelDetails => 'Details';

  @override
  String get panelNoLimit =>
      'No limits registered, so this value is not judged.';

  @override
  String get panelCardInfo => 'Facility info';

  @override
  String get panelCardTemp => 'Temperature';

  @override
  String get panelCardDefrost => 'Defrost';

  @override
  String get panelCardFaults => 'Faults';

  @override
  String get panelCardInverter => 'Inverter';

  @override
  String get panelCardEquipment => 'Equipment';

  @override
  String get panelCardControl => 'Control';

  @override
  String get panelInfoFacilityId => 'Facility ID';

  @override
  String get panelInfoRoomId => 'Room ID';

  @override
  String get panelInfoManagerId => 'Manager ID';

  @override
  String get panelInfoStatus => 'Status';

  @override
  String get panelStatusActive => 'Running (ACTIVE)';

  @override
  String chartShowAllPoints(int count) {
    return 'Show all ($count)';
  }

  @override
  String get chartShowLess => 'Show less';

  @override
  String pageOf(int current, int total) {
    return '$current / $total';
  }

  @override
  String get boardSearchClear => 'Clear search';

  @override
  String get panelCurrentTemp => 'Room temperature';

  @override
  String get panelSetpoint => 'Setpoint';

  @override
  String get unitCelsius => '°C';

  @override
  String get panelWaitingData => 'Waiting for data';

  @override
  String get panelUpdatedJustNow => 'Updated just now';

  @override
  String panelUpdatedSecondsAgo(int seconds) {
    return 'Updated ${seconds}s ago';
  }

  @override
  String panelUpdatedMinutesAgo(int minutes) {
    return 'Updated $minutes min ago';
  }

  @override
  String panelNoSignal(int minutes) {
    return 'No signal for $minutes min';
  }

  @override
  String get alarmsNoneActive => 'No alarms running right now';
}
