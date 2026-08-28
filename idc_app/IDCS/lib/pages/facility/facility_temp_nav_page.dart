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
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text('시설 메뉴', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                '시설 ID $facilityId — 이용할 기능을 선택해주세요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),

              NavigationBox(
                title: '실시간 모니터링',
                icon: Icons.sensors_outlined,
                onPressed: () => context.push('/facility_room/$userId/$facilityId'),
              ),
              const SizedBox(height: 8),
              NavigationBox(
                title: '그래프 차트',
                icon: Icons.show_chart_rounded,
                onPressed: () => context.push('/facility_chart/$userId/$facilityId'),
              ),
              const SizedBox(height: 8),
              NavigationBox(
                title: '소요 기록',
                icon: Icons.assignment_outlined,
                onPressed: () => context.push('/facility_board/$userId/$facilityId'),
              ),
              const SizedBox(height: 8),
              NavigationBox(
                title: '메신저',
                icon: Icons.chat_bubble_outline_rounded,
                onPressed: () => context.push('/chat_list/$userId/$facilityId'),
              ),
              const SizedBox(height: 8),
              NavigationBox(
                title: '알람',
                icon: Icons.notifications_none_rounded,
                onPressed: () => context.push('/facility_alarm/$userId/$facilityId'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
