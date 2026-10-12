// ===============================================================
// 경로: lib/components/indices/settings/settings_sections.dart
// 명세: 앱 설정 묶음 (화면 테마·언어·제어판 화면·알림)
//
//       예전에는 별도 화면(/settings)이었는데, 테마나 언어를 바꾸려고 내 정보
//       안으로 한 번 더 들어가야 했다. 지금은 내 정보가 이 묶음을 그대로 펼쳐서
//       보여주므로 화면이 한 겹 줄었다.
// ===============================================================
import 'package:flutter/material.dart';
import 'package:idcs/l10n/app_localizations.dart';
import 'package:idcs/l10n/l10n_context.dart';
import 'package:idcs/services/common/alarm/alarm_settings.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/theme/locale_controller.dart';
import 'package:idcs/theme/panel_background.dart';
import 'package:idcs/theme/theme_controller.dart';

/// 화면 테마 · 언어 · 제어판 화면 · 알림 카드를 차례로 내놓는다.
class AppSettingsSections extends StatefulWidget {
  const AppSettingsSections({super.key});

  @override
  State<AppSettingsSections> createState() => _AppSettingsSectionsState();
}

class _AppSettingsSectionsState extends State<AppSettingsSections> {
  AlarmSettings _alarm = const AlarmSettings();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await AlarmSettings.load();
    if (!mounted) return;
    setState(() {
      _alarm = loaded;
      _loaded = true;
    });
  }

  Future<void> _updateAlarm(AlarmSettings next) async {
    setState(() => _alarm = next);
    await next.save();
  }

  /// Each language is named in its own language, so someone who cannot read the
  /// current one can still find theirs. Only the "follow the device" row is
  /// translated.
  String _languageLabel(Locale? option, AppLocalizations l10n) {
    switch (option?.languageCode) {
      case 'ko':
        return l10n.languageKorean;
      case 'en':
        return l10n.languageEnglish;
      default:
        return l10n.languageSystem;
    }
  }

  Widget _radioRow({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      onTap: onTap,
      leading: Icon(
        selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
        color: selected ? context.colors.primary : context.colors.textSecondary,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: context.colors.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.mode,
          builder: (context, mode, _) => SettingsCard(
            title: l10n.settingsTheme,
            children: ThemeMode.values
                .map((m) => _radioRow(
                      selected: mode == m,
                      label: ThemeController.labelOf(m, l10n),
                      onTap: () => ThemeController.set(m),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),

        ValueListenableBuilder<Locale?>(
          valueListenable: LocaleController.locale,
          builder: (context, selected, _) => SettingsCard(
            title: l10n.settingsLanguage,
            // null = follow the device, then one row per supported language.
            children: [null, ...LocaleController.supported]
                .map((option) => _radioRow(
                      selected: selected?.languageCode == option?.languageCode,
                      label: _languageLabel(option, l10n),
                      onTap: () => LocaleController.set(option),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),

        ValueListenableBuilder<MonitoringViewSettings>(
          valueListenable: MonitoringViewController.settings,
          builder: (context, view, _) => _PanelAppearanceCard(view: view),
        ),
        const SizedBox(height: 16),

        if (_loaded) ...[
          SettingsCard(
            title: l10n.settingsAlarmStyle,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.alarmSound),
                subtitle: Text(l10n.alarmSoundNote),
                value: _alarm.sound,
                onChanged: (val) => _updateAlarm(_alarm.copyWith(sound: val)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.alarmVibration),
                subtitle: Text(l10n.alarmVibrationNote),
                value: _alarm.vibration,
                onChanged: (val) => _updateAlarm(_alarm.copyWith(vibration: val)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.alarmLockScreen),
                subtitle: Text(l10n.alarmLockScreenNote),
                value: _alarm.showOnLockScreen,
                onChanged: (val) => _updateAlarm(_alarm.copyWith(showOnLockScreen: val)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsCard(
            title: l10n.alarmRepeat,
            children: [
              Text(
                l10n.alarmRepeatNote(AlarmSettings.maxRepeatCount),
                style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: AlarmSettings.repeatOptions.map((minutes) {
                  final selected = _alarm.repeatMinutes == minutes;
                  return ChoiceChip(
                    showCheckmark: false,
                    label: Text(minutes == 0 ? l10n.alarmRepeatNone : l10n.alarmRepeatMinutes(minutes)),
                    selected: selected,
                    onSelected: (_) => _updateAlarm(_alarm.copyWith(repeatMinutes: minutes)),
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
        ],
      ],
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
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return SettingsCard(
      title: l10n.settingsPanel,
      children: [
        Text(
          l10n.settingsPanelNote,
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 12),

        _PanelPreview(view: view),
        const SizedBox(height: 16),

        _Label(text: l10n.panelBackground),
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

        _Label(text: l10n.panelOpacity, trailing: '${((1 - view.panelOpacity) * 100).round()}%'),
        Slider(
          // Runs backwards: the user thinks in "how see-through", the panel is
          // drawn with "how opaque". The floor keeps the readings legible.
          value: 1 - view.panelOpacity,
          max: 1 - MonitoringViewSettings.minOpacity,
          onChanged: (v) => _update(view.copyWith(panelOpacity: 1 - v)),
        ),

        _Label(
          text: l10n.panelValueSize,
          trailing: '${view.valueFontSize.round()}pt',
        ),
        Slider(
          value: view.valueFontScale,
          min: MonitoringViewSettings.minFontScale,
          max: MonitoringViewSettings.maxFontScale,
          onChanged: (v) => _update(view.copyWith(valueFontScale: v)),
        ),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.panelLedDigits),
          subtitle: Text(l10n.panelLedDigitsNote),
          value: view.ledDigits,
          onChanged: (val) => _update(view.copyWith(ledDigits: val)),
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
    final l10n = AppLocalizations.of(context);
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
            option.labelOf(l10n),
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

  /// A real reading: negative and fractional, so the LED face is judged on the
  /// kind of number the panel actually shows.
  static const String _sampleValue = '-18.5';

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
                      AppLocalizations.of(context).panelSampleLabel,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _sampleValue,
                      style: TextStyle(
                        fontSize: view.valueFontSize,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        fontFamily: view.usesLedFor(_sampleValue)
                            ? MonitoringViewSettings.ledFontFamily
                            : null,
                        letterSpacing: view.usesLedFor(_sampleValue) ? 1 : null,
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

class SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.colors.cardShadow,
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
