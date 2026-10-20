import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/audio/audio_composer.dart';
import '../core/audio/chime.dart';
import '../core/audio/pcm_audio.dart';
import '../core/audio/wav.dart';
import '../core/settings/app_settings.dart';
import '../core/settings/settings_store.dart';
import '../core/speech/announcement.dart';
import '../core/speech/bangla_phrase_builder.dart';
import '../core/speech/speech_token.dart';
import '../core/speech/voice_pack.dart';
import '../ui/strings.dart';
import '../core/speech/timer_phrases.dart';
import '../core/update/release.dart';
import 'announcer.dart';
import 'countdown.dart';
import 'asset_clip_source.dart';
import 'platform.dart';
import 'updater.dart';
import 'version.dart';

/// Voice packs bundled with the app, best first.
const bundledVoices = {
  'bn_ai': 'assets/voices/bn_ai',
  'bn_classic': 'assets/voices/bn_classic',
};

/// The running app: settings, voices, the minute ticker and the menu bar.
class AppController extends ChangeNotifier {
  AppController._(
    this._platform,
    this._store,
    this._settings,
    this.voices, {
    DateTime Function()? now,
    this._updates,
    this._openAtLoginOnFirstRun = false,
  }) : _clock = now ?? DateTime.now {
    _now = _clock();
    _announcer = Announcer(
      schedule: () => _settings.schedule,
      // The timer has the floor while it runs.
      muted: () => _settings.muted || countdown.running,
      speak: _speak,
    );
    countdown = Countdown(
      onMinute: _onTimerMinute,
      onDone: _onTimerDone,
      onTick: notifyListeners,
      now: _clock,
    );
    _ticker = MinuteTicker(_onMinute, now: _clock);
  }

  static Future<AppController> create({
    required AppPlatform platform,
    required SettingsStore store,
    Map<String, ClipSource>? voiceSources,
    DateTime Function()? now,
    UpdateSource? updates,
    bool openAtLoginOnFirstRun = false,
  }) async {
    final sources =
        voiceSources ??
        {
          for (final MapEntry(:key, :value) in bundledVoices.entries)
            key: AssetClipSource(value),
        };
    final voices = {
      for (final MapEntry(:key, :value) in sources.entries)
        key: await VoicePack.load(value),
    };
    return AppController._(
      platform,
      store,
      await store.load(),
      voices,
      now: now,
      updates: updates,
      openAtLoginOnFirstRun: openAtLoginOnFirstRun,
    );
  }

  /// How long after starting, and then how often, to look for a new version.
  static const firstUpdateCheck = Duration(seconds: 30);
  static const updateCheckEvery = Duration(hours: 24);

  final AppPlatform _platform;
  final SettingsStore _store;
  final DateTime Function() _clock;
  final UpdateSource? _updates;

  /// Whether the first launch turns on opening at login. On Windows the
  /// setup's own (ticked) box decides instead.
  final bool _openAtLoginOnFirstRun;
  late final Announcer _announcer;
  late final MinuteTicker _ticker;

  /// The timer tab's countdown.
  late final Countdown countdown;
  final _subscriptions = <StreamSubscription<void>>[];
  final _chimes = <int, PcmAudio>{};

  /// Voice packs by id, in [bundledVoices] order.
  final Map<String, VoicePack> voices;

  AppSettings _settings;
  AppSettings get settings => _settings;

  /// Interface text in the chosen language.
  Strings get strings => Strings(_settings.language);

  late DateTime _now;

  /// The current minute, updated every tick.
  DateTime get now => _now;

  bool _speaking = false;

  /// Whether an announcement is playing now.
  bool get speaking => _speaking;
  Timer? _speakingTimer;

  final _creditsRequests = StreamController<void>.broadcast();

  /// Fires when the menu bar asks for the credits page.
  Stream<void> get creditsRequests => _creditsRequests.stream;

  final _updateRequests = StreamController<Release>.broadcast();

  /// Fires when a daily check finds a version worth offering.
  Stream<Release> get updateRequests => _updateRequests.stream;
  Timer? _updateTimer;

  /// Whether a found update can be installed from the app.
  bool get canInstallUpdates => _updates?.canInstall ?? false;

  List<AudioDevice> _outputs = const [];

  /// The sound outputs found by the last [refreshOutputs].
  List<AudioDevice> get outputs => _outputs;

  bool? _launchAtLogin;

  /// Null when the system can't launch the app at login.
  bool? get launchAtLogin => _launchAtLogin;

  /// The selected voice, or the first bundled one if it's gone.
  VoicePack get voice => voices[_settings.voiceId] ?? voices.values.first;

  DateTime? get nextAnnouncement =>
      _settings.muted ? null : _settings.schedule.nextAfter(_now);

  Future<void> start() async {
    _subscriptions
      ..add(_platform.menuSelections.listen(_onMenu))
      ..add(_platform.clockDisturbed.listen((_) => _ticker.restart()));
    _launchAtLogin = await _platform.launchAtLogin();
    await _platform.setAppearance(_settings.appearance);
    _ticker.start();
    await _refreshMenuBar();
    if (!_settings.welcomed) {
      if (_openAtLoginOnFirstRun && _launchAtLogin == false) {
        await setLaunchAtLogin(true);
      }
      await _platform.showWindow();
      await update(_settings.copyWith(welcomed: true));
    }
    if (_updates != null) {
      _updateTimer = Timer(firstUpdateCheck, () {
        unawaited(_offerUpdate());
        _updateTimer = Timer.periodic(
          updateCheckEvery,
          (_) => unawaited(_offerUpdate()),
        );
      });
    }
  }

  /// The newest release if it is newer than this copy, else null. Throws
  /// when GitHub can't be reached.
  Future<Release?> checkForUpdate() async {
    final latest = await _updates?.latest();
    final current = Version.tryParse(appVersion)!;
    return latest != null && latest.version > current ? latest : null;
  }

  /// The daily check: opens the window to offer a new version, unless
  /// checks are off or the user skipped that version.
  Future<void> _offerUpdate() async {
    if (!_settings.checkUpdates) return;
    try {
      final release = await checkForUpdate();
      if (release == null || '${release.version}' == _settings.skippedVersion) {
        return;
      }
      await _platform.showWindow();
      _updateRequests.add(release);
    } on Object {
      // Offline, or GitHub is busy; try again tomorrow.
    }
  }

  /// Never offers [release] again; a later version is still offered.
  Future<void> skipUpdate(Release release) =>
      update(_settings.copyWith(skippedVersion: '${release.version}'));

  /// Installs [release] and quits, leaving the setup to open the new copy.
  Future<void> installUpdate(
    Release release, {
    void Function(double)? progress,
  }) async {
    await _updates!.install(release, progress: progress);
    await _platform.quit();
  }

  /// Looks for the sound outputs connected now.
  Future<void> refreshOutputs() async {
    _outputs = await _platform.outputDevices();
    notifyListeners();
  }

  /// Plays announcements through [device], or the system default if null.
  Future<void> chooseOutput(AudioDevice? device) => update(
    _settings.copyWith(
      outputDeviceId: device?.id ?? '',
      outputDeviceName: device?.name ?? '',
    ),
  );

  Future<void> update(AppSettings settings) async {
    final appearanceChanged = settings.appearance != _settings.appearance;
    _settings = settings;
    if (appearanceChanged) await _platform.setAppearance(settings.appearance);
    notifyListeners();
    await _refreshMenuBar();
    await _store.save(settings);
  }

  Future<void> setLaunchAtLogin(bool enabled) async {
    if (await _platform.setLaunchAtLogin(enabled)) {
      _launchAtLogin = enabled;
      notifyListeners();
    }
  }

  Future<void> openLink(String url) => _platform.openUrl(url);

  /// Announces the current time, whatever the schedule says.
  Future<void> speakNow() => _speak(_clock());

  /// The words [speakNow] would say.
  List<SpeechToken> announcementAt(DateTime time, {AnnouncementStyle? style}) =>
      announcementFor(
        time,
        style ?? _settings.style,
        voice,
        builder: BanglaPhraseBuilder(sayBeje: _settings.sayBeje),
      );

  /// Whether the selected voice can say any minute (the classic voice only
  /// says quarter hours).
  bool get voiceSaysEveryMinute => voice.canSpeak(
    BanglaPhraseBuilder().build(10, 7, style: AnnouncementStyle.exact),
  );

  void _onMinute(DateTime now) {
    _now = now;
    notifyListeners();
    unawaited(_refreshMenuBar());
    unawaited(_announcer.onMinute(now));
  }

  Future<void> _speak(DateTime time) =>
      _say(announcementAt(time), title: strings.clock(time));

  /// Starts the timer at [minutes] and remembers the length for next time.
  Future<void> startTimer(int minutes) async {
    countdown.start(Duration(minutes: minutes));
    notifyListeners();
    await _refreshMenuBar();
    await update(_settings.copyWith(timerMinutes: minutes));
  }

  Future<void> stopTimer() async {
    countdown.stop();
    notifyListeners();
    await _refreshMenuBar();
  }

  /// Whether the selected voice can count the timer down; the classic voice
  /// can't, so it says the time instead.
  bool get voiceCountsDown => voice.canSpeak(timeLeftTokens(1));

  Future<void> _onTimerMinute(int minutesLeft) async {
    await _refreshMenuBar();
    if (voiceCountsDown) {
      await _say(timeLeftTokens(minutesLeft), title: strings.timerTab);
    } else {
      await _speak(_clock());
    }
  }

  Future<void> _onTimerDone() async {
    await _refreshMenuBar();
    if (voiceCountsDown) {
      await _say(timerDoneTokens, title: strings.timerTab, withChime: true);
    } else {
      await _speak(_clock());
    }
  }

  Future<void> _say(
    List<SpeechToken> tokens, {
    required String title,
    bool? withChime,
  }) async {
    final speech = await voice.render(tokens);
    final audio = (withChime ?? _settings.chime)
        ? const AudioComposer(gap: Duration(milliseconds: 250)).compose([
            _chimes.putIfAbsent(
              speech.sampleRate,
              () => chime(speech.sampleRate),
            ),
            speech,
          ])
        : speech;
    await _platform.play(
      encodeWav(audio),
      volume: _settings.volume,
      device: _settings.outputDeviceId,
    );
    _speaking = true;
    notifyListeners();
    _speakingTimer?.cancel();
    _speakingTimer = Timer(audio.duration, () {
      _speaking = false;
      notifyListeners();
    });
    if (_settings.notify) {
      await _platform.notify(title, tokens.text);
    }
  }

  Future<void> _onMenu(String id) async {
    switch (id.split(':')) {
      case ['speak']:
        await speakNow();
      case ['mute']:
        await update(_settings.copyWith(muted: !_settings.muted));
      case ['interval', final minutes]:
        await update(
          _settings.copyWith(intervalMinutes: int.parse(minutes), muted: false),
        );
      case ['settings']:
        await _platform.showWindow();
      case ['timer-stop']:
        await stopTimer();
      case ['credits']:
        await _platform.showWindow();
        _creditsRequests.add(null);
      case ['quit']:
        await _platform.quit();
    }
  }

  Future<void> _refreshMenuBar() async {
    final shows = _settings.menuBarShows;
    await _platform.setStatus(
      title: shows == MenuBarShows.logo ? '' : statusTitle,
      icon: shows != MenuBarShows.time,
    );
    await _platform.setMenu(menuEntries());
  }

  /// The text beside the menu-bar icon: the time.
  String get statusTitle => strings.clockFace(_now);

  @visibleForTesting
  List<MenuEntry> menuEntries() {
    final t = strings;
    return [
      MenuEntry('', t.clock(_now), enabled: false),
      MenuEntry('speak', t.speakNow),
      const MenuEntry.separator(),
      if (countdown.running) ...[
        MenuEntry(
          '',
          t.timerLeftMenu((countdown.remaining.inSeconds / 60).ceil()),
          enabled: false,
        ),
        MenuEntry('timer-stop', t.stopTimer),
      ],
      MenuEntry('mute', t.muteMenu, checked: _settings.muted),
      MenuEntry(
        'interval',
        t.every,
        children: [
          for (final minutes in AppSettings.intervals)
            MenuEntry(
              'interval:$minutes',
              t.interval(minutes),
              checked: !_settings.muted && _settings.intervalMinutes == minutes,
            ),
        ],
      ),
      const MenuEntry.separator(),
      MenuEntry('settings', t.settings),
      MenuEntry('credits', t.creditsMenu),
      MenuEntry('quit', t.quit),
    ];
  }

  @override
  void dispose() {
    _ticker.stop();
    countdown.stop();
    _speakingTimer?.cancel();
    _updateTimer?.cancel();
    unawaited(_creditsRequests.close());
    unawaited(_updateRequests.close());
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
