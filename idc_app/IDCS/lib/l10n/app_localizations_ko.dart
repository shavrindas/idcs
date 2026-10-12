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

  @override
  String get actionSave => '저장';

  @override
  String get actionEdit => '수정';

  @override
  String get actionEditing => '수정 중';

  @override
  String get actionLink => '연동하기';

  @override
  String get actionLogout => '로그아웃';

  @override
  String get actionSearchClear => '검색어 지우기';

  @override
  String get fieldPhone => '전화번호';

  @override
  String get fieldCurrentPassword => '기존 비밀번호';

  @override
  String get loginMethod => '로그인 방식';

  @override
  String get noName => '이름 없음';

  @override
  String get profileTitle => '내 정보';

  @override
  String get profileNoChanges => '변경된 내용이 없습니다.';

  @override
  String get profileSaved => '성공적으로 변경되었습니다.';

  @override
  String get profileSettingsSubtitle => '화면 테마, 제어판 화면, 알람 소리·진동';

  @override
  String get profileTotalBoard => '통합 소요 기록';

  @override
  String get passwordSection => '비밀번호';

  @override
  String get passwordChange => '비밀번호 변경';

  @override
  String get passwordAllRequired => '비밀번호를 모두 입력해주세요.';

  @override
  String get passwordSameAsOld => '새 비밀번호가 기존 비밀번호와 동일합니다.';

  @override
  String get withdrawTitle => '계정 탈퇴';

  @override
  String get withdrawNote => '탈퇴하면 계정 정보와 시설 소속 정보가 모두 삭제되며 되돌릴 수 없습니다.';

  @override
  String get withdrawConfirmTitle => '정말 탈퇴하시겠습니까?';

  @override
  String get withdrawConfirmBody => '계정 정보와 시설 소속 정보가 모두 삭제되며 되돌릴 수 없습니다.';

  @override
  String get withdrawConfirmAction => '탈퇴하기';

  @override
  String get alarmsAllTitle => '전체 알람';

  @override
  String get alarmSearchByFacility => '시설 이름으로 검색...';

  @override
  String get alarmSearchByRoom => '룸 이름으로 검색...';

  @override
  String get alarmSearchByName => '알람 이름으로 검색...';

  @override
  String get alarmFieldName => '알람 명';

  @override
  String get alarmFieldRoom => '룸 이름';

  @override
  String get alarmFieldFacility => '시설 이름';

  @override
  String get alarmStatusAll => '전체';

  @override
  String get alarmStatusActive => '진행중';

  @override
  String get alarmStatusEnded => '종료';

  @override
  String get alarmGroupToggle => '묶어서 보기';

  @override
  String get alarmShort => '알람';

  @override
  String get statusNormal => '정상';

  @override
  String get statusActiveAlarms => '진행 중 알람';

  @override
  String countCases(String label, int count) {
    return '$label $count건';
  }

  @override
  String get facilitiesTitle => '내 시설';

  @override
  String get facilitiesEmpty => '등록된 시설이 없습니다.';

  @override
  String get facilitiesNoneVisible => '조회할 수 있는 시설이 없습니다.';

  @override
  String get roomsEmpty => '등록된 호실이 없습니다.';

  @override
  String roomCount(int count) {
    return '호실 $count개';
  }

  @override
  String permissionLoadFailed(String message) {
    return '권한 조회 실패: $message';
  }

  @override
  String errorPrefix(String message) {
    return '오류: $message';
  }

  @override
  String get chartFilterTitle => '조회 조건';

  @override
  String get chartRoom => '호실';

  @override
  String get chartRoomUnnamed => '이름 없는 호실';

  @override
  String get chartResolution => '해상도';

  @override
  String get chartRes10s => '10초 단위';

  @override
  String get chartRes1m => '1분 단위';

  @override
  String get chartRes5m => '5분 단위';

  @override
  String get chartRes1h => '1시간 단위';

  @override
  String get chartRange => '조회 기간';

  @override
  String get chartRange1h => '최근 1시간';

  @override
  String get chartRange12h => '최근 12시간';

  @override
  String get chartRange1d => '최근 1일';

  @override
  String get chartRange7d => '최근 7일';

  @override
  String get chartRange15d => '최근 15일';

  @override
  String get chartApply => '적용';

  @override
  String get chartGroups => '데이터 그룹';

  @override
  String get chartNoGroups => '등록된 그룹이 없습니다.';

  @override
  String get chartPickManually => '직접 선택';

  @override
  String get chartPickItems => '표시할 항목을 고르세요';

  @override
  String get chartGroupItems => '이 그룹에 묶인 항목';

  @override
  String chartTooManySeries(int shown, int limit) {
    return '$shown개를 한 번에 그리면 알아보기 어렵습니다. $limit개 이하를 권합니다.';
  }

  @override
  String chartSeriesN(int index) {
    return '시리즈 $index';
  }

  @override
  String get chartSummary => '구간 요약';

  @override
  String get chartMin => '최소';

  @override
  String get chartAvg => '평균';

  @override
  String get chartMax => '최대';

  @override
  String get chartNoData => '조회된 데이터가 없습니다.';

  @override
  String get chartNoValidData => '유효한 그래프 데이터가 없습니다.';

  @override
  String chartLowerLimit(String value) {
    return '하한 $value';
  }

  @override
  String chartUpperLimit(String value) {
    return '상한 $value';
  }

  @override
  String get chartTools => '탐색 도구';

  @override
  String get chartPanDisabled => '이동 (비활성)';

  @override
  String get chartHideBaseline => '기준선 숨기기';

  @override
  String get chartShowBaseline => '기준선 표시';

  @override
  String get chartNoteDisabled => '메모 (비활성)';

  @override
  String get chartResetView => '시점 초기화';

  @override
  String get backToFacilities => '내 시설 목록으로';

  @override
  String facilityFallbackName(String id) {
    return '시설 $id';
  }

  @override
  String get navMonitoring => '모니터링';

  @override
  String get navChart => '차트';

  @override
  String get navBoard => '소요기록';

  @override
  String get navMessenger => '메신저';

  @override
  String get navAlarm => '알람';

  @override
  String get alarmSearchByAlarmOrRoom => '알람 명으로 검색...';

  @override
  String get alarmFieldRoomId => '룸 ID';

  @override
  String get chartPageTitle => '데이터 차트';

  @override
  String roomLoadFailed(String message) {
    return '호실 조회 실패: $message';
  }

  @override
  String roomQueryFailed(String message) {
    return '호실 조회 오류: $message';
  }

  @override
  String groupLoadFailed(String message) {
    return '그룹 로드 오류: $message';
  }

  @override
  String chartFailed(String message) {
    return '차트 오류: $message';
  }

  @override
  String get roomPickerTitle => '호실 선택';

  @override
  String get panelControlBadge => '제어';

  @override
  String get panelInputHint => '입력';

  @override
  String get panelConfirm => '확인';

  @override
  String get searchNoResults => '검색 결과가 없습니다.';

  @override
  String get alarmsNone => '조회할 수 있는 알람이 없습니다.';

  @override
  String get alarmNameMissing => '알람 이름 없음';

  @override
  String get roomNameMissing => '호실 이름 없음';

  @override
  String get facilityNameMissing => '시설 이름 없음';

  @override
  String get facilityRegister => '시설 등록';

  @override
  String get facilityAccessCode => '시설 접근 코드';

  @override
  String get facilityRegistered => '등록된 시설';

  @override
  String get facilityUnlink => '해제';

  @override
  String facilityRegisterFailed(String message) {
    return '등록 실패: $message';
  }

  @override
  String get facilityRegisterTitle => '시설 등록 페이지';

  @override
  String get facilityRegisterAdminNote => '관리자 및 개발자는 시설 등록이 필요하지 않습니다.';

  @override
  String get facilityUnnamed => '이름 없는 시설';

  @override
  String get boardNewPost => '새 글 작성';

  @override
  String get boardSearchAll => '전체';

  @override
  String get boardTitle => '제목';

  @override
  String get boardAuthor => '작성자';

  @override
  String get boardBody => '내용';

  @override
  String get boardSearchHint => '검색어를 입력하세요';

  @override
  String get actionSearch => '검색';

  @override
  String get boardEmpty => '등록된 포스트가 없습니다.';

  @override
  String boardPostMeta(String facility, String author) {
    return '[$facility] 작성자: $author';
  }

  @override
  String get pageFirst => '첫 페이지';

  @override
  String get pagePrev => '이전 페이지';

  @override
  String get pageNext => '다음 페이지';

  @override
  String get pageLast => '마지막 페이지';

  @override
  String get postNoTitle => '제목 없음';

  @override
  String postMeta(String author, String date) {
    return '작성자: $author · 작성일: $date';
  }

  @override
  String get actionDelete => '삭제';

  @override
  String commentsCount(int count) {
    return '댓글 $count';
  }

  @override
  String get commentDelete => '댓글 삭제';

  @override
  String get commentsEmpty => '등록된 댓글이 없습니다.';

  @override
  String get commentHint => '댓글을 입력하세요...';

  @override
  String get commentSubmit => '등록';

  @override
  String postLoadFailed(String message) {
    return '게시글 로드 실패: $message';
  }

  @override
  String get postDeleted => '삭제되었습니다.';

  @override
  String postDeleteFailed(String message) {
    return '삭제 실패: $message';
  }

  @override
  String commentFailed(String message) {
    return '댓글 작성 실패: $message';
  }

  @override
  String commentDeleteFailed(String message) {
    return '댓글 삭제 실패: $message';
  }

  @override
  String get dataUnavailable => '데이터를 불러올 수 없습니다.';

  @override
  String get postDetailTitle => '게시글 상세 조회';

  @override
  String imageAttachFailed(String message) {
    return '이미지 첨부 실패: $message';
  }

  @override
  String get postTitleRequired => '제목을 입력해주세요.';

  @override
  String get postCreated => '게시글이 작성되었습니다.';

  @override
  String postCreateFailed(String message) {
    return '게시글 작성 실패: $message';
  }

  @override
  String postCreateTitle(String id) {
    return '새 게시글 작성 (시설 $id)';
  }

  @override
  String get postCreateSubmit => '게시글 등록하기';

  @override
  String postSourceLoadFailed(String message) {
    return '원문 로드 실패: $message';
  }

  @override
  String get postUpdated => '수정 완료되었습니다.';

  @override
  String postUpdateFailed(String message) {
    return '수정 실패: $message';
  }

  @override
  String get postEditTitle => '게시글 수정';

  @override
  String get postEditSubmit => '수정 완료하기';

  @override
  String get totalBoardTitle => '통합 소요 기록 (관리자)';

  @override
  String get totalBoardSearch => '통합 검색 및 필터';

  @override
  String get boardPageTitle => '소요 기록';

  @override
  String get boardSearchTitle => '게시글 검색';

  @override
  String get chatMenu => '메뉴';

  @override
  String get chatNoMessages => '메시지가 없습니다.';

  @override
  String get chatReply => '답장';

  @override
  String get chatPinToggle => '고정 토글';

  @override
  String chatReplyingTo(String text) {
    return '답장: $text';
  }

  @override
  String get actionClose => '닫기';

  @override
  String get chatAttach => '첨부';

  @override
  String get chatInputHint => '메시지를 입력하세요...';

  @override
  String get chatSend => '보내기';

  @override
  String get chatRoomsManage => '채팅방 관리';

  @override
  String get chatGroupCreate => '단체 채팅방 생성';

  @override
  String get chatRoomsEmpty => '참여 중인 채팅방이 없습니다.';

  @override
  String get chatRoomName => '방 이름';

  @override
  String get chatInviteUsers => '초대할 유저 ID (콤마로 구분)';

  @override
  String get actionCreate => '생성';

  @override
  String get chatLeaveRoom => '채팅방 나가기 (관리자는 단체방 삭제 가능)';

  @override
  String get chatSearchHint => '메시지 검색...';

  @override
  String get chatRoom => '채팅방';

  @override
  String get chatMembers => '참여중인 유저 목록';

  @override
  String chatRoomFallback(String id) {
    return '채팅방 $id';
  }

  @override
  String get navHome => '홈';

  @override
  String get appTagline => '냉동창고 실시간 관제 · 모니터링 시스템';

  @override
  String get findIdCheck => '가입 여부 확인하기';

  @override
  String get editorImageAttach => '이미지 첨부';

  @override
  String get loginMethodEmail => '이메일';

  @override
  String get notFound => '페이지를 찾을 수 없습니다.';

  @override
  String get errorServerUnreachable => '서버에 연결할 수 없습니다. 네트워크 상태를 확인해주세요.';

  @override
  String get errorServerTimeout => '서버 응답이 없습니다. 네트워크 상태를 확인해주세요.';

  @override
  String get errorRequestFailed => '요청을 처리하지 못했습니다.';

  @override
  String get googleOnlyOnApp => '구글 로그인은 앱에서만 사용할 수 있습니다.';

  @override
  String get appleOnlyOnApp => '애플 로그인은 앱에서만 사용할 수 있습니다.';

  @override
  String get googleNotConfigured =>
      '구글 로그인이 아직 설정되지 않았습니다. Firebase 프로젝트에 이 앱의 OAuth 클라이언트(SHA-1 지문)를 등록해야 합니다.';

  @override
  String googleSignInFailed(String reason) {
    return '구글 로그인을 진행할 수 없습니다. ($reason)';
  }

  @override
  String appleSignInFailed(String reason) {
    return '애플 로그인을 진행할 수 없습니다. ($reason)';
  }

  @override
  String get googleDefaultName => '구글유저';

  @override
  String get appleDefaultName => '애플유저';

  @override
  String get notificationFallbackTitle => '알림';

  @override
  String alarmRepeatSuffix(String body, int index, int total) {
    return '$body (다시 알림 $index/$total)';
  }

  @override
  String get channelSoundVibe => '알람 (소리+진동)';

  @override
  String get channelSoundVibeDesc => '소리와 진동을 모두 사용하는 알람';

  @override
  String get channelSoundOnly => '알람 (소리만)';

  @override
  String get channelSoundOnlyDesc => '소리만 사용하는 알람';

  @override
  String get channelVibeOnly => '알람 (진동만)';

  @override
  String get channelVibeOnlyDesc => '진동만 사용하는 알람';

  @override
  String get channelSilent => '알람 (무음)';

  @override
  String get channelSilentDesc => '소리와 진동 없이 표시만 하는 알람';

  @override
  String panelPageTitle(String id) {
    return '시설 ID: $id 실시간 제어판';
  }

  @override
  String get panelCardInfo => '시설 기본 정보';

  @override
  String get panelCardTemp => '실제 온도';

  @override
  String get panelCardDefrost => '제상 정보';

  @override
  String get panelCardFaults => '이상 정보';

  @override
  String get panelCardInverter => '인버터 정보';

  @override
  String get panelCardEquipment => '장비 정보';

  @override
  String get panelCardControl => '제어 정보';

  @override
  String get panelInfoFacilityId => '시설 ID';

  @override
  String get panelInfoRoomId => '호실 ID';

  @override
  String get panelInfoManagerId => '담당 관리자 ID';

  @override
  String get panelInfoStatus => '운영 상태';

  @override
  String get panelStatusActive => '정상 작동 중 (ACTIVE)';
}
