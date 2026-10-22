import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../app/host_os.dart';
import '../app/platform.dart';
import '../app/version.dart';
import '../core/settings/app_settings.dart';
import '../core/speech/bangla_phrase_builder.dart';
import '../core/speech/speech_token.dart';
import '../core/speech/timer_phrases.dart';
import 'brand.dart';
import 'strings.dart';
import 'update_dialog.dart';

part 'timer_view.dart';

/// The app's window, opened from the menu bar: the clock's settings, and
/// the timer.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

/// The window's sections, picked in the sidebar (or, in a narrow window,
/// the tabs along the top).
enum _Pane { announce, voice, quiet, timer, general }

class _SettingsPageState extends State<SettingsPage> {
  var _pane = _Pane.announce;

  AppController get controller => widget.controller;

  /// Narrower than this, the sidebar gives way to tabs along the top.
  static const _sidebarFrom = 640.0;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          void pick(_Pane pane) => setState(() => _pane = pane);
          if (box.maxWidth >= _sidebarFrom) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Sidebar(controller: controller, pane: _pane, onPick: pick),
                Expanded(child: _paneView(context, wide: true)),
              ],
            );
          }
          return Column(
            children: [
              _ClockStrip(controller: controller),
              _PaneTabs(controller: controller, pane: _pane, onPick: pick),
              Expanded(child: _paneView(context, wide: false)),
            ],
          );
        },
      ),
    ),
  );

  /// The chosen section, under its title beside the sidebar. In a narrow
  /// window, where there's no sidebar, the credits follow it.
  Widget _paneView(BuildContext context, {required bool wide}) {
    final t = controller.strings;
    final parts = switch (_pane) {
      _Pane.announce => _announce(context),
      _Pane.voice => _voice(context),
      _Pane.quiet => _quiet(context),
      _Pane.timer => [_TimerView(controller: controller)],
      _Pane.general => _general(context),
    };
    return ListView(
      key: PageStorageKey(_pane),
      padding: EdgeInsets.fromLTRB(24, wide ? 20 : 16, 24, 20),
      children: [
        if (wide)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Semantics(
              header: true,
              child: Text(
                _pane.title(t),
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        for (final (i, part) in parts.indexed) ...[
          if (i > 0) const SizedBox(height: 12),
          part,
        ],
        if (!wide) ...[
          const SizedBox(height: 12),
          _Footer(controller: controller),
        ],
      ],
    );
  }

  Widget _switch({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return SwitchListTile.adaptive(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.outline,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  void _set(AppSettings next) => controller.update(next);

  List<Widget> _announce(BuildContext context) {
    final s = controller.settings;
    final t = controller.strings;
    return [
      _Card(
        children: [
          _switch(
            title: t.announceOn,
            value: !s.muted,
            onChanged: (on) => _set(s.copyWith(muted: !on)),
          ),
          _ChoiceRow(
            title: t.every,
            width: 280,
            child: _Segmented<int>(
              segments: [
                for (final m in AppSettings.intervals)
                  _Segment(value: m, label: Text(t.interval(m))),
              ],
              selected: s.intervalMinutes,
              onChanged: (v) => _set(s.copyWith(intervalMinutes: v)),
            ),
          ),
        ],
      ),
      RadioGroup<AnnouncementStyle>(
        // A quarter-hour voice always speaks traditionally.
        groupValue: controller.voiceSaysEveryMinute
            ? s.style
            : AnnouncementStyle.traditional,
        onChanged: (v) => _set(s.copyWith(style: v)),
        child: _OptionGroup(
          children: [
            _styleTile(
              AnnouncementStyle.exact,
              t.exact,
              enabled: controller.voiceSaysEveryMinute,
            ),
            _styleTile(AnnouncementStyle.traditional, t.traditional),
          ],
        ),
      ),
      if (!controller.voiceSaysEveryMinute)
        _Note(t.quarterOnlyVoice(controller.voice.manifest.name))
      else if (s.style == AnnouncementStyle.exact)
        _Card(
          children: [
            _switch(
              title: t.sayBeje,
              subtitle: t.sayBejeHint,
              value: s.sayBeje,
              onChanged: (v) => _set(s.copyWith(sayBeje: v)),
            ),
          ],
        ),
    ];
  }

  List<Widget> _voice(BuildContext context) {
    final s = controller.settings;
    final t = controller.strings;
    return [
      RadioGroup<String>(
        groupValue: controller.voice.id,
        onChanged: (id) => _set(s.copyWith(voiceId: id)),
        child: _OptionGroup(
          children: [
            for (final MapEntry(key: id, value: pack)
                in controller.voices.entries)
              _OptionTile(
                value: id,
                title: Text(
                  t.voiceLabel(pack.manifest.name, pack.manifest.author),
                ),
              ),
          ],
        ),
      ),
      _Card(
        children: [
          ListTile(
            title: Row(
              children: [
                Text(t.volume),
                Expanded(
                  child: Slider.adaptive(
                    value: s.volume,
                    semanticFormatterCallback: (v) =>
                        '${t.volume} ${(v * 100).round()}%',
                    onChanged: (v) => _set(s.copyWith(volume: v)),
                  ),
                ),
              ],
            ),
          ),
          _switch(
            title: t.chime,
            value: s.chime,
            onChanged: (v) => _set(s.copyWith(chime: v)),
          ),
          _ChoiceRow(
            title: t.output,
            width: 260,
            child: _OutputPicker(controller: controller),
          ),
        ],
      ),
      if (s.outputDeviceId.isNotEmpty) _Note(t.outputHint),
    ];
  }

  List<Widget> _quiet(BuildContext context) {
    final s = controller.settings;
    final t = controller.strings;
    return [
      _Card(
        children: [
          _switch(
            title: t.quietHoursOn,
            value: s.quietHoursEnabled,
            onChanged: (v) => _set(s.copyWith(quietHoursEnabled: v)),
          ),
          if (s.quietHoursEnabled)
            ListTile(
              title: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (t.quietFrom.isNotEmpty) Text(t.quietFrom),
                  _TimePicker(
                    strings: t,
                    minutes: s.quietStart,
                    onChanged: (m) => _set(s.copyWith(quietStart: m)),
                  ),
                  Text(t.quietTo),
                  _TimePicker(
                    strings: t,
                    minutes: s.quietEnd,
                    onChanged: (m) => _set(s.copyWith(quietEnd: m)),
                  ),
                  if (t.quietUntil.isNotEmpty) Text(t.quietUntil),
                ],
              ),
            ),
        ],
      ),
    ];
  }

  List<Widget> _general(BuildContext context) {
    final s = controller.settings;
    final t = controller.strings;
    return [
      if (controller.panelHelp != PanelHelp.none)
        _TopBarCard(controller: controller),
      _Card(
        children: [
          _ChoiceRow(
            title: t.languageLabel,
            width: 220,
            child: _Segmented<AppLanguage>(
              segments: [
                for (final l in AppLanguage.values)
                  _Segment(value: l, label: Text(l.label)),
              ],
              selected: s.language,
              onChanged: (v) => _set(s.copyWith(language: v)),
            ),
          ),
          _ChoiceRow(
            title: t.appearance,
            width: 300,
            child: _Segmented<Appearance>(
              segments: [
                _Segment(
                  value: Appearance.light,
                  label: Text(t.appearanceLight),
                ),
                _Segment(value: Appearance.dark, label: Text(t.appearanceDark)),
                _Segment(
                  value: Appearance.system,
                  label: Text(t.appearanceSystem),
                ),
              ],
              selected: s.appearance,
              onChanged: (v) => _set(s.copyWith(appearance: v)),
            ),
          ),
          // A Windows tray icon can't show text, so the time goes in its
          // tooltip. A Linux panel always shows the icon, with the time
          // beside it if chosen (KDE puts it in the tooltip instead).
          if (hostOs == HostOs.macos)
            _ChoiceRow(
              title: t.menuBarShows,
              width: 300,
              child: _Segmented<MenuBarShows>(
                segments: [
                  _Segment(
                    value: MenuBarShows.time,
                    label: Text(t.menuBarTime),
                  ),
                  _Segment(
                    value: MenuBarShows.logo,
                    label: Text(t.menuBarLogo),
                    icon: _logoMark(context),
                  ),
                  _Segment(
                    value: MenuBarShows.both,
                    label: Text(t.menuBarBoth),
                  ),
                ],
                selected: s.menuBarShows,
                onChanged: (v) => _set(s.copyWith(menuBarShows: v)),
              ),
            )
          else if (hostOs == HostOs.linux && controller.hasStatusIcon)
            _ChoiceRow(
              title: t.panelShows,
              width: 260,
              child: _Segmented<MenuBarShows>(
                segments: [
                  _Segment(
                    value: MenuBarShows.logo,
                    label: Text(t.menuBarLogo),
                    icon: _logoMark(context),
                  ),
                  _Segment(
                    value: MenuBarShows.both,
                    label: Text(t.menuBarBoth),
                  ),
                ],
                selected: s.menuBarShows == MenuBarShows.logo
                    ? MenuBarShows.logo
                    : MenuBarShows.both,
                onChanged: (v) => _set(s.copyWith(menuBarShows: v)),
              ),
            ),
        ],
      ),
      _Card(
        children: [
          _switch(
            title: t.notify,
            value: s.notify,
            onChanged: (v) => _set(s.copyWith(notify: v)),
          ),
          if (controller.launchAtLogin case final enabled?)
            _switch(
              title: t.launchAtLogin,
              value: enabled,
              onChanged: controller.setLaunchAtLogin,
            ),
          // Flathub updates its apps itself.
          if (controller.checksForUpdates)
            _switch(
              title: t.checkUpdates,
              value: s.checkUpdates,
              onChanged: (v) => _set(s.copyWith(checkUpdates: v)),
            ),
          ListTile(
            title: Text(t.version(appVersion)),
            trailing: controller.checksForUpdates
                ? _CheckNowButton(controller: controller)
                : null,
          ),
        ],
      ),
    ];
  }

  Widget _logoMark(BuildContext context) => SizedBox.square(
    dimension: 18,
    child: CustomPaint(
      painter: DotDialPainter.template(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );

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
    return _OptionTile(
      value: style,
      enabled: enabled,
      title: Text(label),
      subtitle: Text(controller.voice.spokenText(tokens.skip(1).toList())),
    );
  }
}

extension on _Pane {
  String title(Strings t) => switch (this) {
    _Pane.announce => t.announcements,
    _Pane.voice => t.voiceAndSound,
    _Pane.quiet => t.quietHours,
    _Pane.timer => t.timerTab,
    _Pane.general => t.other,
  };

  IconData get icon => switch (this) {
    _Pane.announce => Icons.campaign_outlined,
    _Pane.voice => Icons.record_voice_over_outlined,
    _Pane.quiet => Icons.bedtime_outlined,
    _Pane.timer => Icons.timer_outlined,
    _Pane.general => Icons.tune,
  };

  /// Marks General while GNOME needs a step to show the clock in its top
  /// bar.
  bool needsLook(AppController c) =>
      this == _Pane.general && c.panelHelp != PanelHelp.none;
}

/// The day dial: the time on a 12-hour ring of dots, the parts of the day
/// around it and the coming announcements lit.
class _Dial extends StatelessWidget {
  const _Dial({
    required this.controller,
    required this.size,
    this.showTime = true,
    this.showZones = true,
  });

  final AppController controller;
  final double size;
  final bool showTime;
  final bool showZones;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = controller.strings;
    final s = controller.settings;
    final dark = theme.brightness == Brightness.dark;
    return Semantics(
      label: t.dialSummary(s),
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: DayDialPainter(
            now: controller.now,
            schedule: s.schedule,
            muted: s.muted,
            speaking: controller.speaking,
            zoneLabels: showZones ? t.zone : (_) => '',
            color: theme.colorScheme.primary,
            background: dark ? Sky.bandNight : Sky.band,
            labelStyle: theme.textTheme.labelMedium!.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          child: showTime
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: size * 0.22),
                    child: FittedBox(
                      child: Text(
                        t.clock(controller.now),
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// The left of a wide window: the clock, Speak now, the sections and the
/// credits.
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.controller,
    required this.pane,
    required this.onPick,
  });

  final AppController controller;
  final _Pane pane;
  final ValueChanged<_Pane> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = controller.strings;
    return Container(
      width: 264,
      color: theme.brightness == Brightness.dark ? Sky.bandNight : Sky.band,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The dial takes the height the rest leaves, up to a size that
          // leaves room beside it for the longest part-of-day label.
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => Center(
                child: _Dial(
                  controller: controller,
                  size: math.min(176, box.biggest.shortestSide),
                ),
              ),
            ),
          ),
          Text(
            t.nextAnnouncement(controller.nextAnnouncement),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: controller.speakNow,
            icon: const Icon(Icons.record_voice_over_outlined),
            label: Text(t.speakNow),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: t.settingsLabel,
            container: true,
            explicitChildNodes: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final p in _Pane.values)
                  _NavItem(
                    icon: p.icon,
                    label: p.title(t),
                    selected: p == pane,
                    dot: p.needsLook(controller),
                    onTap: () => onPick(p),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _Footer(controller: controller, dense: true),
        ],
      ),
    );
  }
}

/// A section in the sidebar: white and bold when chosen.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dot = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool dot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = scheme.brightness == Brightness.light;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? (light ? scheme.surfaceContainerLowest : const Color(0xFF3B5078))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontSize: 15,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (dot)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The top of a narrow window: a small dial, the time, the next
/// announcement and Speak now.
class _ClockStrip extends StatelessWidget {
  const _ClockStrip({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = controller.strings;
    return ColoredBox(
      color: theme.brightness == Brightness.dark ? Sky.bandNight : Sky.band,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            _Dial(
              controller: controller,
              size: 72,
              showTime: false,
              showZones: false,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    child: Text(
                      t.clock(controller.now),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    t.nextAnnouncement(controller.nextAnnouncement),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: t.speakNow,
              onPressed: controller.speakNow,
              icon: const Icon(Icons.record_voice_over_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

/// The sections as tabs, for a window too narrow for the sidebar.
class _PaneTabs extends StatelessWidget {
  const _PaneTabs({
    required this.controller,
    required this.pane,
    required this.onPick,
  });

  final AppController controller;
  final _Pane pane;
  final ValueChanged<_Pane> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = controller.strings;
    return ColoredBox(
      color: theme.brightness == Brightness.dark ? Sky.bandNight : Sky.band,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            for (final p in _Pane.values)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: p == pane,
                  child: InkWell(
                    onTap: () => onPick(p),
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: p == pane
                                ? scheme.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          p.title(t),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: p == pane
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                            fontWeight: p == pane
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// On GNOME without its AppIndicator extension: how to get the icon and
/// time into the top bar, or a button that does it.
class _TopBarCard extends StatelessWidget {
  const _TopBarCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = controller.strings;
    final help = controller.panelHelp;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.primary.withValues(
        alpha: scheme.brightness == Brightness.light ? 0.08 : 0.16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.vertical_align_top, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.topBarTitle,
                    style: theme.listTileTheme.titleTextStyle?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(switch (help) {
              PanelHelp.enable => t.topBarEnable,
              PanelHelp.install => t.topBarInstall,
              PanelHelp.relogin => t.topBarRelogin,
              PanelHelp.flatpak || PanelHelp.none => t.topBarFlatpak,
            }, style: theme.textTheme.bodyMedium),
            if (help == PanelHelp.install) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: const SelectableText(
                  Strings.topBarCommand,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ),
            ],
            if (help == PanelHelp.enable) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: controller.showInTopBar,
                  child: Text(t.turnOn),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Settings on one white card, divided only by their own spacing.
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card.outlined(
    margin: EdgeInsets.zero,
    child: Column(children: children),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
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

/// Options inside a [RadioGroup], each on its own card with a gap between,
/// so neighbouring choices never run together.
class _OptionGroup extends StatelessWidget {
  const _OptionGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, child) in children.indexed) ...[
        if (i > 0) const SizedBox(height: 8),
        child,
      ],
    ],
  );
}

/// One option in an [_OptionGroup]: a card with a radio mark, tinted and
/// outlined sky blue when chosen.
class _OptionTile<T> extends StatelessWidget {
  const _OptionTile({
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final group = RadioGroup.maybeOf<T>(context);
    final chosen = group?.groupValue == value;
    final light = scheme.brightness == Brightness.light;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: chosen,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: chosen
              ? scheme.primary.withValues(alpha: light ? 0.08 : 0.16)
              : scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: chosen
                ? BorderSide(color: scheme.primary, width: 1.5)
                : BorderSide(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? () => group?.onChanged(value) : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _RadioMark(chosen: chosen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultTextStyle.merge(
                          style: theme.listTileTheme.titleTextStyle,
                          child: title,
                        ),
                        if (subtitle case final subtitle?) ...[
                          const SizedBox(height: 2),
                          DefaultTextStyle.merge(
                            style: theme.listTileTheme.subtitleTextStyle,
                            child: subtitle,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A 20pt radio mark: a sky-blue disc with a white centre when chosen, an
/// outline ring when not.
class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.chosen});

  final bool chosen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: chosen ? scheme.primary : scheme.surfaceContainerLowest,
        border: chosen ? null : Border.all(color: scheme.outline, width: 1.5),
      ),
      child: chosen
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.onPrimary,
              ),
            )
          : null,
    );
  }
}

/// A pop-up button choosing where announcements play: the system default
/// or one of the outputs connected now, looked up each time it opens.
class _OutputPicker extends StatelessWidget {
  const _OutputPicker({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final t = controller.strings;
    final s = controller.settings;
    final theme = Theme.of(context);
    final connected = controller.outputs.any((d) => d.id == s.outputDeviceId);
    final label = s.outputDeviceId.isEmpty
        ? t.systemOutput
        : connected || controller.outputs.isEmpty
        ? s.outputDeviceName
        : t.notConnected(s.outputDeviceName);
    Widget item(AudioDevice? device, String name) {
      final chosen = (device?.id ?? '') == s.outputDeviceId;
      return MenuItemButton(
        leadingIcon: Icon(
          Icons.check,
          size: 18,
          color: chosen ? theme.colorScheme.primary : Colors.transparent,
        ),
        onPressed: () => controller.chooseOutput(device),
        child: Text(name),
      );
    }

    return MenuAnchor(
      onOpen: controller.refreshOutputs,
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          theme.colorScheme.surfaceContainerLowest,
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      menuChildren: [
        item(null, t.systemOutput),
        for (final device in controller.outputs) item(device, device.name),
      ],
      builder: (context, menu, _) => OutlinedButton(
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          children: [
            const Icon(Icons.speaker_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
            const Icon(Icons.unfold_more, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Checks GitHub for a newer version on request, then offers it or says
/// this one is the latest.
class _CheckNowButton extends StatefulWidget {
  const _CheckNowButton({required this.controller});

  final AppController controller;

  @override
  State<_CheckNowButton> createState() => _CheckNowButtonState();
}

class _CheckNowButtonState extends State<_CheckNowButton> {
  var _checking = false;

  Future<void> _check() async {
    final t = widget.controller.strings;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _checking = true);
    try {
      final release = await widget.controller.checkForUpdate();
      if (!mounted) return;
      if (release == null) {
        messenger.showSnackBar(SnackBar(content: Text(t.upToDate)));
      } else {
        await showUpdateDialog(context, widget.controller, release);
      }
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(t.checkFailed)));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) => _checking
      ? const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : TextButton(
          onPressed: _check,
          child: Text(widget.controller.strings.checkNow),
        );
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

/// A setting chosen from a few options: its label with the options beside
/// it, [width] wide, or under it where the row is too narrow for both.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.title,
    required this.child,
    required this.width,
  });

  final String title;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      title,
      style: Theme.of(context).listTileTheme.titleTextStyle,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: LayoutBuilder(
        builder: (context, box) => box.maxWidth >= width + 110
            ? Row(
                children: [
                  Expanded(child: label),
                  const SizedBox(width: 12),
                  SizedBox(width: width, child: child),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [label, const SizedBox(height: 8), child],
              ),
      ),
    );
  }
}

/// A bordered pop-up button showing a time of day, like a macOS pop-up
/// menu. It opens a panel with the hours in a list and the minutes, five
/// apart, in a grid: two short choices rather than one long list of times.
class _TimePicker extends StatefulWidget {
  const _TimePicker({
    required this.strings,
    required this.minutes,
    required this.onChanged,
  });

  final Strings strings;

  /// The time shown, in minutes from midnight.
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  State<_TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<_TimePicker> {
  final _menu = MenuController();

  static const _minuteStep = 5;
  static const _hourExtent = 40.0;

  int get _hour => widget.minutes ~/ 60;
  int get _minute => widget.minutes % 60;

  @override
  Widget build(BuildContext context) {
    final t = widget.strings;
    final theme = Theme.of(context);
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    return MenuAnchor(
      controller: _menu,
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          theme.colorScheme.surfaceContainerLowest,
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 148,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading(t.hourHeading),
                    SizedBox(
                      height: _hourExtent * 6,
                      child: ListView.builder(
                        // Opens with the chosen hour in view.
                        controller: ScrollController(
                          initialScrollOffset:
                              math.max(0, _hour - 2) * _hourExtent,
                        ),
                        itemExtent: _hourExtent,
                        itemCount: 24,
                        itemBuilder: (context, h) => _PickerChoice(
                          label: t.hourOfDay(h),
                          chosen: h == _hour,
                          alignment: Alignment.centerLeft,
                          // Stays open, so the minutes can be picked next.
                          onPressed: () => widget.onChanged(h * 60 + _minute),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading(t.minuteHeading),
                  for (var row = 0; row < 4; row++)
                    Row(
                      children: [
                        for (var col = 0; col < 3; col++)
                          SizedBox(
                            width: 60,
                            height: _hourExtent,
                            child: _PickerChoice(
                              label: t.minuteOfHour(
                                (row * 3 + col) * _minuteStep,
                              ),
                              chosen: _minute == (row * 3 + col) * _minuteStep,
                              onPressed: () {
                                widget.onChanged(
                                  _hour * 60 + (row * 3 + col) * _minuteStep,
                                );
                                _menu.close();
                              },
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
      builder: (context, menu, _) => OutlinedButton(
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.timeOfDay(widget.minutes)),
            const SizedBox(width: 4),
            const Icon(Icons.unfold_more, size: 18),
          ],
        ),
      ),
    );
  }
}

/// One hour or minute in a [_TimePicker]'s panel, filled sky blue when
/// chosen.
class _PickerChoice extends StatelessWidget {
  const _PickerChoice({
    required this.label,
    required this.chosen,
    required this.onPressed,
    this.alignment = Alignment.center,
  });

  final String label;
  final bool chosen;
  final VoidCallback onPressed;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          alignment: alignment,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: chosen ? scheme.primary : null,
          foregroundColor: chosen ? scheme.onPrimary : scheme.onSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label, maxLines: 1),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller, this.dense = false});

  final AppController controller;

  /// Smaller, for the sidebar.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = controller.strings;
    // The deeper section blue, so 15pt link text clears 4.5:1.
    final link = TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.secondary,
      visualDensity: dense ? VisualDensity.compact : null,
      textStyle: dense
          ? Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 14)
          : null,
      padding: dense ? const EdgeInsets.symmetric(horizontal: 6) : null,
    );
    final developer = TextButton(
      style: link,
      onPressed: () => controller.openLink(developerUrl),
      child: Text(t.developedBy),
    );
    final rest = [
      TextButton(
        style: link,
        onPressed: () => showCredits(context, controller),
        child: Text(t.credits),
      ),
      // With no menu-bar, tray or panel icon, Quit has nowhere else to be.
      if (!controller.hasStatusIcon) ...[
        const Text('·'),
        TextButton(
          style: link,
          onPressed: controller.quit,
          child: Text(t.quitClock),
        ),
      ],
    ];
    Widget row(List<Widget> children) => Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: children,
    );
    // The sidebar is too narrow for one line, so the developer gets one.
    return dense
        ? Column(children: [developer, row(rest)])
        : row([developer, const Text('·'), ...rest]);
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
