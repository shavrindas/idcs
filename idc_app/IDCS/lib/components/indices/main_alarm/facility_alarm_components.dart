import 'package:flutter/material.dart';
import 'package:idcs/components/shared/alarm_row.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/theme/app_theme.dart';

/// Box #2: 시설 알람 박스 (순수 목록 표시 역할)
class FacilityAlarmBox extends StatelessWidget {
  final List<GroupedAlarm> alarms;
  final bool isSearching;

  /// '진행중'만 보고 있는지. 비어 있을 때 '볼 알람이 없다'가 아니라
  /// '지금 울리는 게 없다'고 안심시켜 주기 위해 필요하다.
  final bool showingActiveOnly;

  /// '진행중'이 비었을 때 아래에 붙일 최근 종료 건.
  ///
  /// 지금 울리는 게 없다는 말만 띄워 놓으면 화면의 대부분이 빈 채로 남는데,
  /// 그 상태에서 사람이 이어서 궁금해하는 것은 하나다 — "그럼 방금까지는
  /// 뭐가 있었나". 빈자리를 그 답으로 채운다.
  final List<GroupedAlarm> recentlyEnded;

  const FacilityAlarmBox({
    super.key,
    required this.alarms,
    this.isSearching = false,
    this.showingActiveOnly = false,
    this.recentlyEnded = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (alarms.isEmpty) {
      final quiet = !isSearching && showingActiveOnly;
      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EmptyListState(
              icon: Icons.notifications_off_outlined,
              // 검색이 빈손인 것과 '지금 울리는 게 없다'는 다른 소식이다.
              good: quiet,
              message: isSearching
                  ? context.l10n.searchNoResults
                  : showingActiveOnly
                      ? context.l10n.alarmsNoneActive
                      : context.l10n.alarmsNone,
            ),
            if (quiet && recentlyEnded.isNotEmpty) ...[
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 9),
                child: Text(
                  context.l10n.alarmRecentlyEnded,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              for (final group in recentlyEnded) ...[
                GroupedAlarmTile(
                  group: group,
                  title: alarmDisplayName(context, group.alarm['alarm_name']),
                  subtitle: group.alarm['room_name'] ?? context.l10n.roomNameMissing,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      );
    }

    // 알람은 계속 쌓이므로 화면에 보이는 만큼만 만드는 Sliver 목록을 쓴다.
    return SliverList.separated(
      itemCount: alarms.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final group = alarms[index];

        return GroupedAlarmTile(
          group: group,
          title: alarmDisplayName(context, group.alarm['alarm_name']),
          subtitle: group.alarm['room_name'] ?? context.l10n.roomNameMissing,
        );
      },
    );
  }
}
