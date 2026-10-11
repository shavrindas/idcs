// ===============================================================
// 경로 : lib/main.dart
// 명세 : 권한 주입 간소화 및 라우팅
// ===============================================================
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:idcs/services/common/fcm_service.dart';
import 'package:idcs/services/common/facility_shortcut.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
import 'package:idcs/firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:idcs/l10n/app_localizations.dart';
import 'package:idcs/theme/locale_controller.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:idcs/pages/common/find_pw_page.dart';
import 'package:idcs/pages/common/login_page.dart';
import 'package:idcs/pages/common/signup_page.dart';
import 'package:idcs/pages/common/find_id_page.dart';
import 'package:idcs/pages/facility/monitoring/monitoring_room.dart';
import 'package:idcs/pages/facility/facility_shell_page.dart';
import 'package:idcs/pages/indices/user_shell_page.dart';
import 'package:idcs/pages/facility/monitoring/monitoring_page.dart';
import 'package:idcs/pages/indices/account_edit_page.dart';
import 'package:idcs/pages/facility/facility_alarm_page.dart';
import 'package:idcs/pages/indices/main_alarm_page.dart';
import 'package:idcs/pages/indices/settings_page.dart';
import 'package:idcs/pages/indices/main_index_page.dart';
import 'package:idcs/pages/indices/facility_register_page.dart';
import 'package:idcs/pages/indices/total_board_page.dart';
import 'package:idcs/pages/facility/board/facility_board_page.dart';
import 'package:idcs/pages/facility/board/post_detail_page.dart';
import 'package:idcs/pages/facility/board/post_create_page.dart';
import 'package:idcs/pages/facility/board/post_edit_page.dart';
import 'package:idcs/pages/facility/chat/facility_chat_list_page.dart';
import 'package:idcs/pages/facility/chat/chat_room_page.dart';
import 'package:idcs/pages/facility/chart/facility_chart_page.dart';
import 'pages/common/opening_page.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/theme/theme_controller.dart';

part 'config.dart';
part 'auth_service.dart';
part 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 💡 앱 초기화 로직을 config.dart로 추상화하여 main.dart 수정을 원천 차단
  await AppConfig.initializeAll();

  // 알림 채널/권한/수신 리스너 등록. 그동안 호출되는 곳이 없어 푸시가 와도
  // 로컬 알림이 뜨지 않았다. flutter_local_notifications는 웹을 지원하지 않으므로 건너뛴다.
  if (!kIsWeb) {
    await FcmService.initialize();
  }

  // 저장된 테마 선택값 복원 (config.dart는 .gitignore 대상이라 여기서 호출한다)
  await ThemeController.load();

  // 제어판 겉모습 설정 복원. 첫 화면이 그려지기 전에 읽어야 깜빡임이 없다.
  await MonitoringViewController.load();

  // 표시 언어 복원. 역시 첫 프레임 전에 읽어야 한국어로 떴다가 바뀌지 않는다.
  await LocaleController.load();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, themeMode, _) => ValueListenableBuilder<Locale?>(
        valueListenable: LocaleController.locale,
        // locale이 null이면 MaterialApp이 기기 설정을 따라간다.
        builder: (context, locale, _) => MaterialApp.router(
          title: 'IDCool Systems Routing',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          locale: locale,
          routerConfig: appRouter, // routes.dart의 라우터가 마치 한 파일처럼 인식됨
          localizationsDelegates: const [
            // AppLocalizations.delegate is a const instance, so the list stays const.
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
  }
}
