// ===============================================================
// 경로: lib/pages/indices/alarm_settings_page.dart
// 명세: 알람이 어떻게 울릴지(소리/진동/잠금화면/다시 알림) 설정하는 화면
// ===============================================================
import 'package:flutter/material.dart';
import 'package:idcs/services/common/alarm/alarm_settings.dart';
import 'package:idcs/theme/app_theme.dart';

class AlarmSettingsPage extends StatefulWidget {
  const AlarmSettingsPage({super.key});

  @override
  State<AlarmSettingsPage> createState() => _AlarmSettingsPageState();
}

class _AlarmSettingsPageState extends State<AlarmSettingsPage> {
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
      appBar: AppBar(title: const Text('알람 설정')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                    const Text(
                      '알람을 확인하지 못했을 때 설정한 간격으로 최대 '
                      '${AlarmSettings.maxRepeatCount}번까지 다시 알려줍니다.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: AlarmSettings.repeatOptions.map((minutes) {
                        final selected = _settings.repeatMinutes == minutes;
                        return ChoiceChip(
                          label: Text(minutes == 0 ? '없음' : '$minutes분'),
                          selected: selected,
                          onSelected: (_) => _update(_settings.copyWith(repeatMinutes: minutes)),
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : AppColors.textPrimary,
                          ),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.background,
                          side: BorderSide(color: selected ? AppColors.primary : AppColors.outline),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '이 설정은 이 기기에만 적용됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
