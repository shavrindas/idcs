// ===============================================================
// 경로: lib/pages/indices/settings_page.dart
// 명세: 앱 설정 한 곳 — 화면 테마와 알람 동작
// ===============================================================
import 'package:flutter/material.dart';
import 'package:idcs/services/common/alarm/alarm_settings.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/theme/panel_background.dart';
import 'package:idcs/theme/theme_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AlarmSettings _settings = const AlarmSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await AlarmSettings.load();
    if (!mounted) return;
    setState(() {
      _settings = loaded;
      _isLoading = false;
    });
  }

  Future<void> _update(AlarmSettings next) async {
    setState(() => _settings = next);
    await next.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: ThemeController.mode,
                  builder: (context, mode, _) => _SettingsCard(
                    title: '화면 테마',
                    children: ThemeMode.values.map((m) {
                      final selected = mode == m;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onTap: () => ThemeController.set(m),
                        leading: Icon(
                          selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                          color: selected ? context.colors.primary : context.colors.textSecondary,
                          size: 20,
                        ),
                        title: Text(
                          ThemeController.labelOf(m),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<MonitoringViewSettings>(
                  valueListenable: MonitoringViewController.settings,
                  builder: (context, view, _) => _PanelAppearanceCard(view: view),
                ),
                const SizedBox(height: 16),
                _SettingsCard(
                  title: '알림 방식',
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('소리'),
                      subtitle: const Text('알람이 올 때 소리로 알립니다.'),
                      value: _settings.sound,
                      onChanged: (val) => _update(_settings.copyWith(sound: val)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('진동'),
                      subtitle: const Text('알람이 올 때 진동으로 알립니다.'),
                      value: _settings.vibration,
                      onChanged: (val) => _update(_settings.copyWith(vibration: val)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('잠금화면에 내용 표시'),
                      subtitle: const Text('꺼두면 잠금화면에서는 알람이 왔다는 사실만 보입니다.'),
                      value: _settings.showOnLockScreen,
                      onChanged: (val) => _update(_settings.copyWith(showOnLockScreen: val)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsCard(
                  title: '다시 알림',
                  children: [
                    Text(
                      '알람을 확인하지 못했을 때 설정한 간격으로 최대 '
                      '${AlarmSettings.maxRepeatCount}번까지 다시 알려줍니다.',
                      style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: AlarmSettings.repeatOptions.map((minutes) {
                        final selected = _settings.repeatMinutes == minutes;
                        return ChoiceChip(
                          showCheckmark: false,
                          label: Text(minutes == 0 ? '없음' : '$minutes분'),
                          selected: selected,
                          onSelected: (_) => _update(_settings.copyWith(repeatMinutes: minutes)),
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? context.colors.onPrimary : context.colors.textPrimary,
                          ),
                          selectedColor: context.colors.primary,
                          backgroundColor: context.colors.background,
                          side: BorderSide(color: selected ? context.colors.primary : context.colors.outline),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '이 설정은 이 기기에만 적용됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                ),
              ],
            ),
    );
  }
}

/// 실시간 제어판 겉모습 설정.
///
/// The three controls are shown under one live sample rather than as separate
/// sliders: opacity only means something against a backdrop, and a number size
/// is hard to judge as a percentage. The sample is the panel in miniature.
class _PanelAppearanceCard extends StatelessWidget {
  final MonitoringViewSettings view;

  const _PanelAppearanceCard({required this.view});

  Future<void> _update(MonitoringViewSettings next) =>
      MonitoringViewController.set(next);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return _SettingsCard(
      title: '제어판 화면',
      children: [
        Text(
          '호실에 들어갔을 때 보이는 실시간 제어판에만 적용됩니다.',
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 12),

        _PanelPreview(view: view),
        const SizedBox(height: 16),

        _Label(text: '배경'),
        const SizedBox(height: 8),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: PanelBackground.all.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final option = PanelBackground.all[i];
              return _BackgroundChoice(
                option: option,
                selected: option.id == view.backgroundId,
                onTap: () => _update(view.copyWith(backgroundId: option.id)),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        _Label(text: '투명도', trailing: '${((1 - view.panelOpacity) * 100).round()}%'),
        Slider(
          // Runs backwards: the user thinks in "how see-through", the panel is
          // drawn with "how opaque". The floor keeps the readings legible.
          value: 1 - view.panelOpacity,
          max: 1 - MonitoringViewSettings.minOpacity,
          onChanged: (v) => _update(view.copyWith(panelOpacity: 1 - v)),
        ),

        _Label(
          text: '숫자 크기',
          trailing: '${view.valueFontSize.round()}pt',
        ),
        Slider(
          value: view.valueFontScale,
          min: MonitoringViewSettings.minFontScale,
          max: MonitoringViewSettings.maxFontScale,
          onChanged: (v) => _update(view.copyWith(valueFontScale: v)),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final String? trailing;

  const _Label({required this.text, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.colors.textPrimary,
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
          ),
      ],
    );
  }
}

/// One background option as a small tile painted with the real pattern.
class _BackgroundChoice extends StatelessWidget {
  final PanelBackground option;
  final bool selected;
  final VoidCallback onTap;

  const _BackgroundChoice({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 48,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? colors.primary : colors.outline,
                width: selected ? 2 : 1,
              ),
            ),
            child: PanelBackdrop(backgroundId: option.id),
          ),
          const SizedBox(height: 6),
          Text(
            option.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? colors.primary : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The control panel in miniature, so the three settings can be judged together.
class _PanelPreview extends StatelessWidget {
  final MonitoringViewSettings view;

  const _PanelPreview({required this.view});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 108,
        child: Stack(
          children: [
            Positioned.fill(child: PanelBackdrop(backgroundId: view.backgroundId)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                // Full width, like a real panel card, so the sample reads as the
                // 제어판 in miniature rather than a floating chip.
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: view.panelOpacity),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '고내온도',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '-18.5',
                      style: TextStyle(
                        fontSize: view.valueFontSize,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
