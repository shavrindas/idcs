// ===============================================================
// 경로 : lib/pages/common/opening_page.dart
// 명세 : 오프닝 페이지 (디자인 요소를 제외한 기본 컴포넌트 분할 상태)
// ===============================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';

import 'package:idcs/components/common/opening/open_nav.dart';
import 'package:idcs/components/common/opening/open_inj_static.dart';
import 'package:idcs/components/common/opening/open_inj_text.dart';

class OpeningPage extends StatelessWidget {
  const OpeningPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오프닝 페이지'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Box #1: 로그인 페이지 이동
            NavigationBox(
              title: '로그인 페이지로 이동',
              //onPressed: () => Navigator.pushNamed(context, '/login'),
              onPressed: () => context.push('/login'),
            ),
            const SizedBox(height: 16),

            // Box #2: 계정 생성 페이지 이동
            NavigationBox(
              title: '계정 생성 페이지로 이동',
              // onPressed: () => Navigator.pushNamed(context, '/signup'),
              onPressed: () => context.push('/signup'),
            ),
            const SizedBox(height: 16),

            // Box #3: 권한 주입 (admin - ID 1)
            AuthInjectionBox(
              title: '권한 주입 계정(admin)',
              userIdToInject: 1,
            ),
            const SizedBox(height: 16),

            // Box #4: 권한 주입 (user - ID 4)
            AuthInjectionBox(
              title: '권한 주입 계정(user_4)',
              userIdToInject: 4,
            ),
            const SizedBox(height: 16),

            // Box #5: 권한 주입 (직접 입력)
            const CustomAuthInjectionBox(),
          ],
        ),
      ),
    );
  }
}


