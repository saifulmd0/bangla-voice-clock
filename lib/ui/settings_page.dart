import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../core/settings/app_settings.dart';
import '../core/speech/bangla_phrase_builder.dart';
import '../core/speech/speech_token.dart';
import '../core/speech/timer_phrases.dart';
import 'brand.dart';
import 'strings.dart';

part 'timer_view.dart';

/// The app's window, opened from the menu bar: the clock's settings, and
/// the timer.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum _Tab { clock, timer }

class _SettingsPageState extends State<SettingsPage> {
  var _tab = _Tab.clock;

  AppController get controller => widget.controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final t = controller.strings;
      return Scaffold(
        body: Column(
          children: [
            ColoredBox(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Sky.bandNight
                  : Sky.band,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(80, 14, 80, 0),
                child: _Segmented<_Tab>(
                  segments: [
                    _Segment(value: _Tab.clock, label: Text(t.clockTab)),
                    _Segment(value: _Tab.timer, label: Text(t.timerTab)),
                  ],
                  selected: _tab,
                  onChanged: (tab) => setState(() => _tab = tab),
                ),
              ),
            ),
            Expanded(
              child: switch (_tab) {
                _Tab.clock => _clockTab(context),
                _Tab.timer => _TimerView(controller: controller),
              },
            ),
          ],
        ),
      );
    },
  );

  Widget _clockTab(BuildContext context) {
    final s = controller.settings;
    final t = controller.strings;
    void set(AppSettings next) => controller.update(next);
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _DialHeader(controller: controller),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: FilledButton.icon(
                  onPressed: controller.speakNow,
                  icon: const Icon(Icons.record_voice_over_outlined),
                  label: Text(t.speakNow),
                ),
              ),
              _Section(
                title: t.look,
                children: [
                  _ChoiceRow(
                    title: t.appearance,
                    child: _Segmented<Appearance>(
                      segments: [
                        _Segment(
                          value: Appearance.light,
                          label: Text(t.appearanceLight),
                        ),
                        _Segment(
                          value: Appearance.dark,
                          label: Text(t.appearanceDark),
                        ),
                        _Segment(
                          value: Appearance.system,
                          label: Text(t.appearanceSystem),
                        ),
                      ],
                      selected: s.appearance,
                      onChanged: (v) => set(s.copyWith(appearance: v)),
                    ),
                  ),
                  // A Windows tray icon can't show text, so the time goes in
                  // its tooltip and there is nothing to choose.
                  if (!Platform.isWindows)
                    _ChoiceRow(
                      title: t.menuBarShows,
                      child: _Segmented<MenuBarShows>(
                        segments: [
                          _Segment(
                            value: MenuBarShows.time,
                            label: Text(t.menuBarTime),
                          ),
                          _Segment(
                            value: MenuBarShows.logo,
                            label: Text(t.menuBarLogo),
                            icon: SizedBox.square(
                              dimension: 18,
                              child: CustomPaint(
                                painter: DotDialPainter.template(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                            ),
                          ),
                          _Segment(
                            value: MenuBarShows.both,
                            label: Text(t.menuBarBoth),
                          ),
                        ],
                        selected: s.menuBarShows,
                        onChanged: (v) => set(s.copyWith(menuBarShows: v)),
                      ),
                    ),
                ],
              ),
              _Section(
                title: t.announcements,
                children: [
                  SwitchListTile.adaptive(
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    inactiveTrackColor: Theme.of(context).colorScheme.outline,
                    title: Text(t.announceOn),
                    value: !s.muted,
                    onChanged: (on) => set(s.copyWith(muted: !on)),
                  ),
                  _ChoiceRow(
                    title: t.every,
                    child: _Segmented<int>(
                      segments: [
                        for (final m in AppSettings.intervals)
                          _Segment(value: m, label: Text(t.interval(m))),
                      ],
                      selected: s.intervalMinutes,
                      onChanged: (v) => set(s.copyWith(intervalMinutes: v)),
                    ),
                  ),
                  RadioGroup<AnnouncementStyle>(
                    // A quarter-hour voice always speaks traditionally.
                    groupValue: controller.voiceSaysEveryMinute
                        ? s.style
                        : AnnouncementStyle.traditional,
                    onChanged: (v) => set(s.copyWith(style: v)),
                    child: Column(
                      children: [
                        _styleTile(
                          AnnouncementStyle.traditional,
                          t.traditional,
                        ),
                        _styleTile(
                          AnnouncementStyle.exact,
                          t.exact,
                          enabled: controller.voiceSaysEveryMinute,
                        ),
                      ],
                    ),
                  ),
                  if (!controller.voiceSaysEveryMinute)
                    _Note(t.quarterOnlyVoice(controller.voice.manifest.name))
                  else if (s.style == AnnouncementStyle.exact)
                    SwitchListTile.adaptive(
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      inactiveTrackColor: Theme.of(context).colorScheme.outline,
                      title: Text(t.sayBeje),
                      subtitle: Text(t.sayBejeHint),
                      value: s.sayBeje,
                      onChanged: (v) => set(s.copyWith(sayBeje: v)),
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
                          _RadioTile(
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
                    title: Slider.adaptive(
                      value: s.volume,
                      semanticFormatterCallback: (v) =>
                          '${t.volume} ${(v * 100).round()}%',
                      onChanged: (v) => set(s.copyWith(volume: v)),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    inactiveTrackColor: Theme.of(context).colorScheme.outline,
                    title: Text(t.chime),
                    value: s.chime,
                    onChanged: (v) => set(s.copyWith(chime: v)),
                  ),
                ],
              ),
              _Section(
                title: t.quietHours,
                children: [
                  SwitchListTile.adaptive(
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    inactiveTrackColor: Theme.of(context).colorScheme.outline,
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
                          if (t.quietFrom.isNotEmpty) Text(t.quietFrom),
                          _HourPicker(
                            strings: t,
                            hour: s.quietStartHour,
                            onChanged: (h) =>
                                set(s.copyWith(quietStartHour: h)),
                          ),
                          Text(t.quietTo),
                          _HourPicker(
                            strings: t,
                            hour: s.quietEndHour,
                            onChanged: (h) => set(s.copyWith(quietEndHour: h)),
                          ),
                          if (t.quietUntil.isNotEmpty) Text(t.quietUntil),
                        ],
                      ),
                    ),
                ],
              ),
              _Section(
                title: t.other,
                children: [
                  _ChoiceRow(
                    title: t.languageLabel,
                    child: _Segmented<AppLanguage>(
                      segments: [
                        for (final l in AppLanguage.values)
                          _Segment(value: l, label: Text(l.label)),
                      ],
                      selected: s.language,
                      onChanged: (v) => set(s.copyWith(language: v)),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    inactiveTrackColor: Theme.of(context).colorScheme.outline,
                    title: Text(t.notify),
                    value: s.notify,
                    onChanged: (v) => set(s.copyWith(notify: v)),
                  ),
                  if (controller.launchAtLogin case final enabled?)
                    SwitchListTile.adaptive(
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      inactiveTrackColor: Theme.of(context).colorScheme.outline,
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
        ),
      ],
    );
  }

  Widget _styleTile(
    AnnouncementStyle style,
    String label, {
    bool enabled = true,
  }) {
    // What the chosen voice really says: 10:15 for the traditional style,
    // 10:07 for minutes (or, for a quarter-hour voice, its own 10:15).
    final minute = style == AnnouncementStyle.exact && enabled ? 7 : 15;
    final tokens = controller.announcementAt(
      DateTime(2000, 1, 1, 10, minute),
      style: style,
    );
    return _RadioTile(
      value: style,
      enabled: enabled,
      title: Text(label),
      subtitle: Text(controller.voice.spokenText(tokens.skip(1).toList())),
    );
  }
}

/// The sky band holding today's dial, with the time and the
/// next announcement at its centre.
class _DialHeader extends StatelessWidget {
  const _DialHeader({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = controller.strings;
    final s = controller.settings;
    final dark = theme.brightness == Brightness.dark;
    return ColoredBox(
      color: dark ? Sky.bandNight : Sky.band,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Semantics(
            label: t.dialSummary(s),
            child: SizedBox.square(
              dimension: 280,
              child: CustomPaint(
                painter: DayDialPainter(
                  now: controller.now,
                  schedule: s.schedule,
                  muted: s.muted,
                  speaking: controller.speaking,
                  zoneLabels: t.zone,
                  color: theme.colorScheme.primary,
                  background: dark ? Sky.bandNight : Sky.band,
                  labelStyle: theme.textTheme.labelMedium!.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 64),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          child: Text(
                            t.clock(controller.now),
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.nextAnnouncement(controller.nextAnnouncement),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A short explanation inside a settings group, with an info icon.
class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: scheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

/// A macOS-style radio row inside a [RadioGroup]: sky blue when chosen,
/// and a clear outline ring when not.
class _RadioTile<T> extends StatelessWidget {
  const _RadioTile({
    required this.value,
    required this.title,
    this.subtitle,
    this.enabled = true,
  });

  final T value;
  final bool enabled;
  final Widget title;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chosen = RadioGroup.maybeOf<T>(context)?.groupValue == value;
    return ListTile(
      leading: Stack(
        alignment: Alignment.center,
        children: [
          CupertinoRadio<T>(
            value: value,
            enabled: enabled,
            activeColor: scheme.primary,
            inactiveColor: scheme.surfaceContainerLowest,
          ),
          // Cupertino's own unchosen ring is too faint on these cards, and
          // in dark mode it fills at low opacity, so draw a clear ring.
          if (!chosen)
            IgnorePointer(
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.outline, width: 1.5),
                ),
              ),
            ),
        ],
      ),
      enabled: enabled,
      title: title,
      subtitle: subtitle,
      onTap: () => RadioGroup.maybeOf<T>(context)?.onChanged(value),
    );
  }
}

/// One option of a [_Segmented] control.
class _Segment<T> {
  const _Segment({required this.value, required this.label, this.icon});

  final T value;
  final Widget label;
  final Widget? icon;
}

/// A macOS-style segmented control: a rounded track with the chosen
/// segment raised on it by a soft shadow, filling the row's width.
class _Segmented<T extends Object> extends StatelessWidget {
  const _Segmented({
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<_Segment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = scheme.brightness == Brightness.light;
    final index = segments.indexWhere((s) => s.value == selected);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(9),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth / segments.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                left: width * index,
                top: 0,
                bottom: 0,
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: light
                        ? scheme.surfaceContainerLowest
                        : const Color(0xFF3B5078),
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: light ? 0.12 : 0.3,
                        ),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final segment in segments)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: segment.value == selected,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(7),
                          onTap: () => onChanged(segment.value),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: DefaultTextStyle.merge(
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: scheme.onSurface,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (segment.icon case final icon?) ...[
                                    icon,
                                    const SizedBox(width: 6),
                                  ],
                                  // Long labels shrink rather than overflow.
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: segment.label,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A setting chosen from a few options: its label, then the options at
/// full width underneath.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).listTileTheme.titleTextStyle),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
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

  // A bordered pop-up button showing the value and a chevron, like a
  // macOS pop-up menu, rather than Material's underlined dropdown.
  @override
  Widget build(BuildContext context) => MenuAnchor(
    menuChildren: [
      for (var h = 0; h < 24; h++)
        MenuItemButton(
          onPressed: () => onChanged(h),
          leadingIcon: h == hour
              ? const Icon(Icons.check, size: 18)
              : const SizedBox(width: 18),
          child: Text(strings.hour(h)),
        ),
    ],
    builder: (context, menu, _) => OutlinedButton(
      onPressed: () => menu.isOpen ? menu.close() : menu.open(),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(strings.hour(hour)),
          const SizedBox(width: 4),
          const Icon(Icons.unfold_more, size: 18),
        ],
      ),
    ),
  );
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final t = controller.strings;
    // The deeper section blue, so 15pt link text clears 4.5:1.
    final link = TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.secondary,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        TextButton(
          style: link,
          onPressed: () => controller.openLink(developerUrl),
          child: Text(t.developedBy),
        ),
        const Text('·'),
        TextButton(
          style: link,
          onPressed: () => showCredits(context, controller),
          child: Text(t.credits),
        ),
      ],
    );
  }
}

/// The credits page, opened over the settings with a way back.
Route<void> creditsRoute(AppController controller) => MaterialPageRoute<void>(
  builder: (_) => CreditsPage(controller: controller),
);

Future<void> showCredits(BuildContext context, AppController controller) =>
    Navigator.of(context).push(creditsRoute(controller));

/// Everyone the app owes, opened from the footer or the menu bar.
class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final t = controller.strings;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.credits),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Center(
            child: SizedBox.square(
              dimension: 96,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Sky.tile,
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: CustomPaint(painter: DotDialPainter()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.appName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final credit in creditsFor(t))
                  ListTile(
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
        ],
      ),
    );
  }
}
