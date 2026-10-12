// ===============================================================
// 경로: lib/pages/indices/settings_page.dart
// 명세: 앱 설정 한 곳 — 화면 테마와 알람 동작
// ===============================================================
import 'package:flutter/material.dart';
import 'package:idcs/l10n/app_localizations.dart';
import 'package:idcs/services/common/alarm/alarm_settings.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/theme/panel_background.dart';
import 'package:idcs/theme/locale_controller.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: ThemeController.mode,
                  builder: (context, mode, _) => _SettingsCard(
                    title: l10n.settingsTheme,
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
                          ThemeController.labelOf(m, l10n),
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
                ValueListenableBuilder<Locale?>(
                  valueListenable: LocaleController.locale,
                  builder: (context, selected, _) => _SettingsCard(
                    title: l10n.settingsLanguage,
                    // null = follow the device, then one row per supported language.
                    children: [null, ...LocaleController.supported].map((option) {
                      final isSelected = selected?.languageCode == option?.languageCode;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onTap: () => LocaleController.set(option),
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? context.colors.primary : context.colors.textSecondary,
                          size: 20,
                        ),
                        title: Text(
                          _languageLabel(option, l10n),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
                  title: l10n.settingsAlarmStyle,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.alarmSound),
                      subtitle: Text(l10n.alarmSoundNote),
                      value: _settings.sound,
                      onChanged: (val) => _update(_settings.copyWith(sound: val)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.alarmVibration),
                      subtitle: Text(l10n.alarmVibrationNote),
                      value: _settings.vibration,
                      onChanged: (val) => _update(_settings.copyWith(vibration: val)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.alarmLockScreen),
                      subtitle: Text(l10n.alarmLockScreenNote),
                      value: _settings.showOnLockScreen,
                      onChanged: (val) => _update(_settings.copyWith(showOnLockScreen: val)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsCard(
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
                        final selected = _settings.repeatMinutes == minutes;
                        return ChoiceChip(
                          showCheckmark: false,
                          label: Text(minutes == 0 ? l10n.alarmRepeatNone : l10n.alarmRepeatMinutes(minutes)),
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
                  l10n.settingsDeviceOnly,
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
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return _SettingsCard(
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
