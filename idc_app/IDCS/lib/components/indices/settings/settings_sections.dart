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
import 'package:idcs/services/common/home_widget_bridge.dart';
import 'package:idcs/services/common/monitoring_view_settings.dart';
import 'package:idcs/theme/app_theme.dart';
import 'package:idcs/theme/motion.dart';
import 'package:idcs/theme/locale_controller.dart';
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

  /// Home-screen widget keeps updating while the app is closed (Android only).
  bool _widgetLive = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await AlarmSettings.load();
    final widgetLive = await HomeWidgetBridge.isLive();
    if (!mounted) return;
    setState(() {
      _alarm = loaded;
      _widgetLive = widgetLive;
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 세 줄짜리 라디오 목록을 한 줄짜리 선택기로 바꿨다. 테마와 언어는
        // 한 번 고르면 그대로 두는 것들인데, 둘이 합쳐 여섯 줄을 차지해서
        // 그 아래 항목에 닿으려면 계속 쓸어내려야 했다.
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.mode,
          builder: (context, mode, _) => SettingsCard(
            title: l10n.settingsTheme,
            children: [
              _Choices<ThemeMode>(
                options: ThemeMode.values,
                selected: mode,
                labelOf: (m) => ThemeController.labelOf(m, l10n),
                onSelected: ThemeController.set,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ValueListenableBuilder<Locale?>(
          valueListenable: LocaleController.locale,
          builder: (context, selected, _) => SettingsCard(
            title: l10n.settingsLanguage,
            children: [
              _Choices<Locale?>(
                // null = 기기 설정을 따른다.
                options: [null, ...LocaleController.supported],
                selected: selected == null
                    ? null
                    : LocaleController.supported.firstWhere(
                        (o) => o.languageCode == selected.languageCode,
                        orElse: () => selected,
                      ),
                labelOf: (o) => _languageLabel(o, l10n),
                onSelected: LocaleController.set,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 눈은 앱 전체에 걸리는 설정이라 제어판 카드가 아니라 여기 둔다.
        ValueListenableBuilder<MonitoringViewSettings>(
          valueListenable: MonitoringViewController.settings,
          builder: (context, view, _) => SettingsCard(
            title: l10n.settingsBackground,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(l10n.settingsSnow, style: const TextStyle(fontSize: 14)),
                value: view.snow,
                onChanged: (val) => MonitoringViewController.set(view.copyWith(snow: val)),
              ),
              const SizedBox(height: 4),

              // 투명도는 제어판뿐 아니라 앱의 모든 카드에 걸린다. 그래서
              // '제어판 화면' 카드가 아니라 여기, 배경과 같은 자리에 둔다.
              _Label(text: l10n.panelOpacity, trailing: '${((1 - view.panelOpacity) * 100).round()}%'),
              Slider(
                // 사람은 '얼마나 비치는가'로 생각하고 카드는 '얼마나 불투명한가'로
                // 그려지므로 거꾸로 돌려 받는다.
                value: 1 - view.panelOpacity,
                max: 1 - MonitoringViewSettings.minOpacity,
                onChanged: (v) =>
                    MonitoringViewController.set(view.copyWith(panelOpacity: 1 - v)),
              ),
            ],
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
          if (HomeWidgetBridge.supported) ...[
            const SizedBox(height: 16),
            SettingsCard(
              title: l10n.settingsHomeWidget,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.widgetLive),
                  subtitle: Text(l10n.widgetLiveNote),
                  value: _widgetLive,
                  onChanged: (val) {
                    setState(() => _widgetLive = val);
                    HomeWidgetBridge.setLive(val);
                  },
                ),
              ],
            ),
          ],
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
/// 몇 안 되는 보기를 한 줄에 늘어놓는 선택기.
///
/// 라디오 목록은 보기가 많거나 설명이 붙을 때 쓸 만하지만, 여기처럼 셋뿐이고
/// 이름이 한두 단어면 세로로 세 줄을 쓰는 것이 아깝다.
class _Choices<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final void Function(T) onSelected;

  const _Choices({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(labelOf(option)),
            selected: option == selected,
            showCheckmark: false,
            onSelected: (_) => onSelected(option),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: option == selected ? colors.onPrimary : colors.textPrimary,
            ),
            selectedColor: colors.primary,
            backgroundColor: colors.background,
            side: BorderSide(color: option == selected ? colors.primary : colors.outline),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
      ],
    );
  }
}

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
      // 이 카드가 제일 길다 — 배경 고르기, 투명도, 글자 크기, 미리보기까지
      // 들어 있다. 한 번 맞춰 두면 거의 안 건드리므로 접어 둔다.
      collapsible: true,
      summary: '${view.valueFontSize.round()}pt',
      title: l10n.settingsPanel,
      children: [
        Text(
          l10n.settingsPanelNote,
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 12),

        _PanelPreview(view: view),
        const SizedBox(height: 16),

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

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.panelTempDividers),
          subtitle: Text(l10n.panelTempDividersNote),
          value: view.tempDividers,
          onChanged: (val) => _update(view.copyWith(tempDividers: val)),
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
            Positioned.fill(child: ColoredBox(color: colors.background)),
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

class SettingsCard extends StatefulWidget {
  final String title;
  final List<Widget> children;

  /// 접을 수 있는 카드인지. 접히면 처음에는 닫혀 있다.
  ///
  /// 설정은 한 번 맞춰 두고 거의 안 들어오는 화면인데, 카드가 전부 펼쳐져
  /// 있으면 아래쪽 항목에 닿는 데만 몇 번을 쓸어내려야 한다. 길고 자주 안
  /// 쓰는 것만 접어 둔다.
  final bool collapsible;

  /// 접혀 있을 때 제목 옆에 붙는 한 줄. 열어 보지 않아도 지금 무엇이
  /// 설정돼 있는지 알 수 있어야 접어 두는 의미가 있다.
  final String? summary;

  const SettingsCard({
    super.key,
    required this.title,
    required this.children,
    this.collapsible = false,
    this.summary,
  });

  @override
  State<SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final expanded = !widget.collapsible || _open;

    final header = Row(
      children: [
        Text(
          widget.title,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary),
        ),
        if (widget.collapsible) ...[
          const Spacer(),
          if (widget.summary != null && !expanded)
            Flexible(
              child: Text(
                widget.summary!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 12, color: colors.textSecondary.withValues(alpha: 0.8)),
              ),
            ),
          const SizedBox(width: 6),
          Icon(
            expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            size: 20,
            color: colors.textSecondary,
          ),
        ],
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.collapsible)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _open = !_open),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: header),
              ),
            )
          else
            header,
          AnimatedSize(
            duration: Motion.of(context, Motion.normal),
            curve: Motion.enter,
            alignment: Alignment.topCenter,
            child: !expanded
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [const SizedBox(height: 8), ...widget.children],
                  ),
          ),
        ],
      ),
    );
  }
}
