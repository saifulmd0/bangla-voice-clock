import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../core/settings/app_settings.dart';
import '../core/speech/bangla_phrase_builder.dart';
import '../core/speech/speech_token.dart';
import 'strings.dart';

/// The settings window, opened from the menu bar.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final s = controller.settings;
      final t = controller.strings;
      void set(AppSettings next) => controller.update(next);
      return Scaffold(
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          children: [
            _ClockHeader(controller: controller),
            const SizedBox(height: 16),
            _Section(
              title: t.announcements,
              children: [
                SwitchListTile(
                  title: Text(t.announceOn),
                  value: !s.muted,
                  onChanged: (on) => set(s.copyWith(muted: !on)),
                ),
                ListTile(
                  title: Text(t.every),
                  trailing: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: [
                      for (final m in AppSettings.intervals)
                        ButtonSegment(value: m, label: Text(t.interval(m))),
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
                      _styleTile(AnnouncementStyle.traditional, t.traditional),
                      _styleTile(AnnouncementStyle.exact, t.exact),
                    ],
                  ),
                ),
              ],
            ),
            _Section(
              title: t.voice,
              children: [
                RadioGroup<String>(
                  groupValue: controller.voice.id,
                  onChanged: (id) => set(s.copyWith(voiceId: id)),
                  child: Column(
                    children: [
                      for (final MapEntry(key: id, value: pack)
                          in controller.voices.entries)
                        RadioListTile(
                          value: id,
                          title: Text(
                            t.voiceLabel(
                              pack.manifest.name,
                              pack.manifest.author,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Tooltip(
                    message: t.volume,
                    child: const Icon(Icons.volume_up_outlined),
                  ),
                  title: Slider(
                    value: s.volume,
                    semanticFormatterCallback: (v) =>
                        '${t.volume} ${(v * 100).round()}%',
                    onChanged: (v) => set(s.copyWith(volume: v)),
                  ),
                ),
                SwitchListTile(
                  title: Text(t.chime),
                  value: s.chime,
                  onChanged: (v) => set(s.copyWith(chime: v)),
                ),
              ],
            ),
            _Section(
              title: t.quietHours,
              children: [
                SwitchListTile(
                  title: Text(t.quietHoursOn),
                  value: s.quietHoursEnabled,
                  onChanged: (v) => set(s.copyWith(quietHoursEnabled: v)),
                ),
                if (s.quietHoursEnabled)
                  ListTile(
                    title: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      children: [
                        _HourPicker(
                          strings: t,
                          hour: s.quietStartHour,
                          onChanged: (h) => set(s.copyWith(quietStartHour: h)),
                        ),
                        Text(t.from),
                        _HourPicker(
                          strings: t,
                          hour: s.quietEndHour,
                          onChanged: (h) => set(s.copyWith(quietEndHour: h)),
                        ),
                        if (t.until.isNotEmpty) Text(t.until),
                      ],
                    ),
                  ),
              ],
            ),
            _Section(
              title: t.other,
              children: [
                ListTile(
                  title: Text(t.languageLabel),
                  trailing: SegmentedButton<AppLanguage>(
                    showSelectedIcon: false,
                    segments: [
                      for (final l in AppLanguage.values)
                        ButtonSegment(value: l, label: Text(l.label)),
                    ],
                    selected: {s.language},
                    onSelectionChanged: (v) =>
                        set(s.copyWith(language: v.single)),
                  ),
                ),
                ListTile(
                  title: Text(t.menuBarShows),
                  trailing: SegmentedButton<MenuBarShows>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: MenuBarShows.time,
                        label: Text(t.menuBarTime),
                      ),
                      ButtonSegment(
                        value: MenuBarShows.logo,
                        label: Text(t.menuBarLogo),
                      ),
                    ],
                    selected: {s.menuBarShows},
                    onSelectionChanged: (v) =>
                        set(s.copyWith(menuBarShows: v.single)),
                  ),
                ),
                SwitchListTile(
                  title: Text(t.notify),
                  value: s.notify,
                  onChanged: (v) => set(s.copyWith(notify: v)),
                ),
                if (controller.launchAtLogin case final enabled?)
                  SwitchListTile(
                    title: Text(t.launchAtLogin),
                    value: enabled,
                    onChanged: controller.setLaunchAtLogin,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _Footer(controller: controller),
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
    final t = controller.strings;
    return Column(
      children: [
        Text(t.clock(controller.now), style: theme.textTheme.displaySmall),
        const SizedBox(height: 4),
        Text(
          t.nextAnnouncement(controller.nextAnnouncement),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: controller.speakNow,
          icon: const Icon(Icons.record_voice_over_outlined),
          label: Text(t.speakNow),
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
  const _HourPicker({
    required this.strings,
    required this.hour,
    required this.onChanged,
  });

  final Strings strings;
  final int hour;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButton<int>(
    value: hour,
    onChanged: (h) => onChanged(h!),
    items: [
      for (var h = 0; h < 24; h++)
        DropdownMenuItem(value: h, child: Text(strings.hour(h))),
    ],
  );
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final t = controller.strings;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        TextButton(
          onPressed: () => controller.openLink(developerUrl),
          child: Text(t.developedBy),
        ),
        const Text('·'),
        TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => CreditsDialog(controller: controller),
          ),
          child: Text(t.credits),
        ),
      ],
    );
  }
}

/// Everyone the app owes, opened from the footer.
class CreditsDialog extends StatelessWidget {
  const CreditsDialog({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final t = controller.strings;
    return AlertDialog(
      title: Text(t.credits),
      content: SizedBox(
        width: 380,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final credit in creditsFor(t))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(credit.title),
                subtitle: Text(credit.detail),
                trailing: credit.url == null
                    ? null
                    : const Icon(Icons.open_in_new, size: 18),
                onTap: credit.url == null
                    ? null
                    : () => controller.openLink(credit.url!),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.close),
        ),
      ],
    );
  }
}
