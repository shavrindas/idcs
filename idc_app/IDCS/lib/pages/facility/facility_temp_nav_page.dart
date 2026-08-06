import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:idcs/components/common/opening/open_nav.dart';

class FacilityTempNavPage extends StatelessWidget {
  final String userId;
  final String facilityId;

  const FacilityTempNavPage({super.key, required this.userId, required this.facilityId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('시설 ID: $facilityId 라우팅')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('시설 내부 기능 테스트용 라우팅', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
            const SizedBox(height: 16),
            NavigationBox(title: '시설 인덱스 관리 페이지', onPressed: () { /* TODO: route */ }),
            const SizedBox(height: 8),
            NavigationBox(title: '시설 알람 리스트 페이지',
                onPressed: () {
                  context.push('/facility_alarm/$userId/$facilityId');
            }),
            const SizedBox(height: 8),



            NavigationBox(
              title: '시설 소요기록 인덱스 페이지',
              onPressed: () {
                context.push('/facility_board/$userId/$facilityId');
              },
            ),

            NavigationBox(
              title: '시설 그래프 차트 페이지',
              onPressed: () {
                context.push('/facility_chart/$userId/$facilityId');
              },
            ),

            const SizedBox(height: 8),
            NavigationBox(title: '시설 실시간 모니터링 페이지', onPressed: () { /* TODO: route */
              context.push('/facility_room/$userId/$facilityId');
            }),

            const SizedBox(height: 8),
            NavigationBox(title: '시설 메신저 페이지', onPressed: () {
              context.push('/chat_list/$userId/$facilityId');
            }),

            const SizedBox(height: 8),
            NavigationBox(title: '시설 통합 검색 페이지', onPressed: () { /* TODO: route */ }),
          ],
        ),
      ),
    );
  }
}