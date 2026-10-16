// ===============================================================
// 경로: lib/components/facility/monitoring/room_watch_view.dart
// 명세: 화면을 눕히면 나오는 한 호실 전용 관측 화면 (가로, 읽기 전용)
// ===============================================================
import 'package:flutter/material.dart';
import 'package:idcs/components/facility/monitoring/device_labels.dart';
import 'package:idcs/components/facility/monitoring/room_status.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
import 'package:idcs/theme/app_theme.dart';

/// 호실 하나를 계속 들여다보기 위한 화면.
///
/// 목록 화면은 "어디가 문제인가"를 찾는 자리라 한 칸에 일곱 가지만 담는다.
/// 그런데 실제로는 그렇게 찾아낸 호실 하나를 한동안 지켜봐야 할 때가 있다 —
/// 제상이 끝나고 온도가 제대로 내려오는지, 압력이 어디까지 올라가는지 같은 것은
/// 값 하나를 보는 게 아니라 변하는 것을 보는 일이다. 그때 세로 화면의 작은
/// 카드로는 부족하고, 제어판은 스크롤해야 전부 보인다.
///
/// 그래서 눕히면 그 한 가지만 한다. 폰을 세워 놓고 멀리서도 읽히도록 숫자를
/// 크게 키우고, 좌우로 밀어 다른 호실로 넘어간다.
///
/// 읽기 전용이다. 세워 둔 폰은 스치기만 해도 눌린다 — 설정값을 바꾸는 일은
/// 제어판에서 해야 한다.
class RoomWatchPager extends StatefulWidget {
  final List<dynamic> rooms;

  /// 호실 id -> (필드 이름 -> 값). 시설 소켓이 모든 호실을 한꺼번에 보낸다.
  final Map<int, Map<String, String>> liveValues;

  /// 알람 API 로 받아 둔 호실별 진행 중 알람 수.
  final Map<int, int> alarmCounts;

  final bool ledDigits;

  const RoomWatchPager({
    super.key,
    required this.rooms,
    required this.liveValues,
    required this.alarmCounts,
    required this.ledDigits,
  });

  @override
  State<RoomWatchPager> createState() => _RoomWatchPagerState();
}

class _RoomWatchPagerState extends State<RoomWatchPager> {
  late final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.rooms.length) return;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rooms.isEmpty) {
      return Center(
        child: Text(
          context.l10n.roomsEmpty,
          style: TextStyle(color: context.colors.textSecondary),
        ),
      );
    }

    return PageView.builder(
      controller: _controller,
      onPageChanged: (i) => setState(() => _index = i),
      itemCount: widget.rooms.length,
      itemBuilder: (context, i) {
        final room = widget.rooms[i];
        final roomId = room['id'];
        final values = widget.liveValues[roomId] ?? const <String, String>{};

        return _RoomWatchPage(
          name: room['name']?.toString() ?? '',
          values: values,
          status: RoomStatus.from(
            values,
            alarmCount: widget.alarmCounts[roomId] ?? 0,
          ),
          ledDigits: widget.ledDigits,
          index: i,
          total: widget.rooms.length,
          onStep: _step,
        );
      },
    );
  }
}

/// 가로 화면에서 보여 줄 항목.
///
/// 제어판에는 쉰 가지가 넘게 있지만, 지켜보는 동안 실제로 움직이는 것은 몇 안 된다.
/// 나머지는 눕힌 화면을 빽빽하게만 만들어서, 멀리서 읽는다는 이 화면의 쓸모를
/// 없앤다. 상태 플래그(이상·CINT·HIGH)는 꺼져 있어도 남겨 둔다 — 켜지는 순간을
/// 보려고 지켜보는 것이라 자리가 비어 있으면 안 된다.
/// 켜짐/꺼짐으로 읽을 항목인지, 수치로 읽을 항목인지.
///
/// 값만 보고 판단할 수는 없다. 설비는 참/거짓을 "0.0" 처럼 보내기도 해서
/// 수치와 구별이 안 되고, 반대로 Hz 48.2 를 '0이 아니니 켜짐'으로 읽으면
/// 주파수 칸에 ON 이 뜬다. 어느 쪽인지는 항목마다 정해져 있는 것이므로
/// 여기에 적어 둔다.
enum _Reading { flag, number }

const _watchFields = <(String, _Reading, bool)>[
  ('deforest_def', _Reading.flag, false),
  ('temp_comp', _Reading.flag, false),
  ('control_runsw', _Reading.flag, false),
  ('inverter_hz', _Reading.number, false),
  ('equipment_press1', _Reading.number, false),
  ('equipment_press2', _Reading.number, false),
  ('emergency_emg', _Reading.flag, true),
  ('emergency_cint', _Reading.flag, true),
  ('emergency_high', _Reading.flag, true),
];

class _RoomWatchPage extends StatelessWidget {
  final String name;
  final Map<String, String> values;
  final RoomStatus status;
  final bool ledDigits;
  final int index;
  final int total;
  final void Function(int delta) onStep;

  const _RoomWatchPage({
    required this.name,
    required this.values,
    required this.status,
    required this.ledDigits,
    required this.index,
    required this.total,
    required this.onStep,
  });

  String _statusWord(BuildContext context) => switch (status.condition) {
        RoomCondition.fault => context.l10n.roomStatusFault,
        RoomCondition.drifting => context.l10n.roomStateDrift,
        RoomCondition.offline => context.l10n.roomStateNoData,
        RoomCondition.normal => context.l10n.statusNormal,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = status.accent(colors);
    final attention = status.needsAttention;

    return ColoredBox(
      // 걸린 호실은 화면 전체가 물든다. 폰을 세워 두고 멀리서 보는 화면이라
      // 작은 배지로는 눈에 들어오지 않는다.
      color: attention
          ? Color.alphaBlend(accent.withValues(alpha: 0.07), colors.background)
          : colors.background,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 45, child: _hero(context, accent)),
                    const SizedBox(width: 16),
                    Expanded(flex: 55, child: _readings(context)),
                  ],
                ),
              ),
            ),
            // 카드와 같은 자리, 같은 뜻의 띠.
            Container(height: 5, color: status.railColor(colors)),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, Color accent) {
    final colors = context.colors;
    final l10n = context.l10n;
    final temp = status.temp;
    final deviation = status.deviation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _statusWord(context),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accent),
              ),
            ),
          ],
        ),
        const Spacer(),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                temp == null ? '—' : temp.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 104,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: status.needsAttention ? accent : colors.textPrimary,
                  fontFamily: temp != null && ledDigits
                      ? MonitoringViewSettings.ledFontFamily
                      : null,
                  letterSpacing: temp != null && ledDigits ? 0 : null,
                ),
              ),
              if (temp != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    l10n.unitCelsius,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (status.setpoint != null)
              Text(
                '${l10n.roomSetpointShort} ${status.setpoint!.toStringAsFixed(1)}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textSecondary),
              ),
            if (deviation != null) ...[
              const SizedBox(width: 10),
              Text(
                'Δ ${deviation >= 0 ? '+' : ''}${deviation.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: status.condition == RoomCondition.drifting
                      ? colors.warning
                      : colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        const Spacer(),
        // 밀어서 넘기는 화면이지만, 세워 둔 폰을 한 손으로 넘길 때는 버튼이 낫다.
        Row(
          children: [
            _StepButton(
              icon: Icons.chevron_left_rounded,
              enabled: index > 0,
              onPressed: () => onStep(-1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '${index + 1} / $total',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary),
              ),
            ),
            _StepButton(
              icon: Icons.chevron_right_rounded,
              enabled: index < total - 1,
              onPressed: () => onStep(1),
            ),
          ],
        ),
      ],
    );
  }

  /// 3 x 3. GridView 대신 Expanded 로 짠다 — 비율을 고정하면 가로 화면
  /// 높이에 따라 아래가 남거나 잘린다.
  Widget _readings(BuildContext context) {
    Widget tile(int i) {
      final (key, kind, danger) = _watchFields[i];
      return Expanded(
        child: _ReadingTile(
          label: DeviceLabels.of(context, key),
          raw: values[key],
          kind: kind,
          danger: danger,
          ledDigits: ledDigits,
        ),
      );
    }

    return Column(
      children: [
        for (var row = 0; row < 3; row++) ...[
          if (row > 0) const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                tile(row * 3),
                const SizedBox(width: 8),
                tile(row * 3 + 1),
                const SizedBox(width: 8),
                tile(row * 3 + 2),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _StepButton({required this.icon, required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: enabled ? colors.surface : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(
            icon,
            size: 22,
            color: enabled ? colors.textPrimary : colors.textSecondary.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

/// 값 한 칸. 참/거짓이면 불이 들어오고, 수치면 LED 숫자로 나온다.
class _ReadingTile extends StatelessWidget {
  final String label;
  final String? raw;
  final _Reading kind;
  final bool danger;
  final bool ledDigits;

  const _ReadingTile({
    required this.label,
    required this.raw,
    required this.kind,
    required this.danger,
    required this.ledDigits,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final on = kind == _Reading.flag ? RoomStatus.asSwitch(raw) : null;
    final number = double.tryParse(raw?.trim() ?? '');

    final accent = danger ? colors.error : colors.primary;
    final lit = on == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      decoration: BoxDecoration(
        color: lit ? accent.withValues(alpha: 0.12) : colors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textSecondary),
          ),
          const SizedBox(height: 3),
          if (on != null)
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: lit ? accent : Colors.transparent,
                    border: lit
                        ? null
                        : Border.all(color: colors.textSecondary.withValues(alpha: 0.5)),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  lit ? context.l10n.roomStatusOn : context.l10n.roomStatusOff,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: lit ? accent : colors.textSecondary,
                  ),
                ),
              ],
            )
          else
            Text(
              number == null ? '—' : raw!.trim(),
              maxLines: 1,
              style: TextStyle(
                fontSize: 18,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                fontFamily: number != null && ledDigits
                    ? MonitoringViewSettings.ledFontFamily
                    : null,
                letterSpacing: number != null && ledDigits ? 1 : null,
              ),
            ),
        ],
      ),
    );
  }
}
