import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../core/clock/bangla_clock.dart';
import '../core/settings/app_settings.dart';
import '../core/speech/bangla_phrase_builder.dart';
import '../core/speech/speech_token.dart';

/// The settings window, opened from the menu bar.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final s = controller.settings;
      void set(AppSettings next) => controller.update(next);
      return Scaffold(
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            _ClockHeader(controller: controller),
            const SizedBox(height: 16),
            _Section(
              title: 'ঘোষণা',
              children: [
                SwitchListTile(
                  title: const Text('সময় ঘোষণা চালু'),
                  value: !s.muted,
                  onChanged: (on) => set(s.copyWith(muted: !on)),
                ),
                ListTile(
                  title: const Text('কতক্ষণ পরপর'),
                  trailing: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: [
                      for (final m in AppSettings.intervals)
                        ButtonSegment(value: m, label: Text(intervalLabel(m))),
                    ],
                    selected: {s.intervalMinutes},
                    onSelectionChanged: (v) =>
                        set(s.copyWith(intervalMinutes: v.single)),
                  ),
                ),
                RadioGroup<AnnouncementStyle>(
                  groupValue: s.style,
                  onChanged: (v) => set(s.copyWith(style: v)),
                  child: Column(
                    children: [
                      _styleTile(AnnouncementStyle.traditional, 'প্রচলিত'),
                      _styleTile(AnnouncementStyle.exact, 'মিনিট ধরে'),
                    ],
                  ),
                ),
              ],
            ),
            _Section(
              title: 'কণ্ঠ',
              children: [
                for (final MapEntry(key: id, value: pack)
                    in controller.voices.entries)
                  ListTile(
                    leading: Icon(
                      id == controller.voice.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(pack.manifest.name),
                    onTap: () => set(s.copyWith(voiceId: id)),
                  ),
                ListTile(
                  leading: const Icon(Icons.volume_up_outlined),
                  title: Slider(
                    value: s.volume,
                    onChanged: (v) => set(s.copyWith(volume: v)),
                  ),
                ),
                SwitchListTile(
                  title: const Text('ঘোষণার আগে ঘণ্টাধ্বনি'),
                  value: s.chime,
                  onChanged: (v) => set(s.copyWith(chime: v)),
                ),
              ],
            ),
            _Section(
              title: 'নীরব সময়',
              children: [
                SwitchListTile(
                  title: const Text('এই সময়ে ঘোষণা হবে না'),
                  value: s.quietHoursEnabled,
                  onChanged: (v) => set(s.copyWith(quietHoursEnabled: v)),
                ),
                if (s.quietHoursEnabled)
                  ListTile(
                    title: Row(
                      children: [
                        _HourPicker(
                          hour: s.quietStartHour,
                          onChanged: (h) => set(s.copyWith(quietStartHour: h)),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('থেকে'),
                        ),
                        _HourPicker(
                          hour: s.quietEndHour,
                          onChanged: (h) => set(s.copyWith(quietEndHour: h)),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text('পর্যন্ত'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            _Section(
              title: 'অন্যান্য',
              children: [
                SwitchListTile(
                  title: const Text('মেনু বারে ঘড়ি দেখান'),
                  value: s.showClockInMenuBar,
                  onChanged: (v) => set(s.copyWith(showClockInMenuBar: v)),
                ),
                SwitchListTile(
                  title: const Text('ঘোষণার সাথে নোটিফিকেশন'),
                  value: s.notify,
                  onChanged: (v) => set(s.copyWith(notify: v)),
                ),
                if (controller.launchAtLogin case final enabled?)
                  SwitchListTile(
                    title: const Text('ম্যাক চালু হলে নিজে থেকে চালু হবে'),
                    value: enabled,
                    onChanged: controller.setLaunchAtLogin,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _Credits(controller: controller),
          ],
        ),
      );
    },
  );

  Widget _styleTile(AnnouncementStyle style, String label) {
    // 10:15 shows the difference between the styles best.
    final example = BanglaPhraseBuilder(includeStarter: false)
        .build(10, 15, style: style)
        .text;
    return RadioListTile(
      value: style,
      title: Text(label),
      subtitle: Text(example),
    );
  }
}

class _ClockHeader extends StatelessWidget {
  const _ClockHeader({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = controller.nextAnnouncement;
    return Column(
      children: [
        Text(
          banglaClockWithZone(controller.now),
          style: theme.textTheme.displaySmall,
        ),
        const SizedBox(height: 4),
        Text(
          next == null
              ? 'ঘোষণা বন্ধ আছে'
              : 'পরের ঘোষণা ${banglaClockWithZone(next)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: controller.speakNow,
          icon: const Icon(Icons.record_voice_over_outlined),
          label: const Text('এখনই সময় শুনুন'),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        Card.outlined(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    ),
  );
}

class _HourPicker extends StatelessWidget {
  const _HourPicker({required this.hour, required this.onChanged});

  final int hour;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButton<int>(
    value: hour,
    onChanged: (h) => onChanged(h!),
    items: [
      for (var h = 0; h < 24; h++)
        DropdownMenuItem(
          value: h,
          child: Text(banglaClockWithZone(DateTime(2000, 1, 1, h))),
        ),
    ],
  );
}

class _Credits extends StatelessWidget {
  const _Credits({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Column(
      children: [
        if (controller.voice.manifest.credits case final credits
            when credits.isNotEmpty)
          Text(credits, style: style, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          'Inspired by Bangla Voice Clock (1998–2002) by Q A M Khaled Ferdaus.',
          style: style,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
