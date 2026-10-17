import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/audio/audio_composer.dart';
import '../core/audio/chime.dart';
import '../core/audio/pcm_audio.dart';
import '../core/audio/wav.dart';
import '../core/clock/bangla_clock.dart';
import '../core/settings/app_settings.dart';
import '../core/settings/settings_store.dart';
import '../core/speech/announcement.dart';
import '../core/speech/speech_token.dart';
import '../core/speech/voice_pack.dart';
import 'announcer.dart';
import 'asset_clip_source.dart';
import 'platform.dart';

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
  }) : _clock = now ?? DateTime.now {
    _now = _clock();
    _announcer = Announcer(
      schedule: () => _settings.schedule,
      muted: () => _settings.muted,
      speak: _speak,
    );
    _ticker = MinuteTicker(_onMinute, now: _clock);
  }

  static Future<AppController> create({
    required AppPlatform platform,
    required SettingsStore store,
    Map<String, ClipSource>? voiceSources,
    DateTime Function()? now,
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
    );
  }

  final AppPlatform _platform;
  final SettingsStore _store;
  final DateTime Function() _clock;
  late final Announcer _announcer;
  late final MinuteTicker _ticker;
  final _subscriptions = <StreamSubscription<void>>[];
  final _chimes = <int, PcmAudio>{};

  /// Voice packs by id, in [bundledVoices] order.
  final Map<String, VoicePack> voices;

  AppSettings _settings;
  AppSettings get settings => _settings;

  late DateTime _now;

  /// The current minute, updated every tick.
  DateTime get now => _now;

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
    _ticker.start();
    await _refreshMenuBar();
    if (!_settings.welcomed) {
      await _platform.showWindow();
      await update(_settings.copyWith(welcomed: true));
    }
  }

  Future<void> update(AppSettings settings) async {
    _settings = settings;
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

  /// Announces the current time, whatever the schedule says.
  Future<void> speakNow() => _speak(_clock());

  /// The words [speakNow] would say.
  List<SpeechToken> announcementAt(DateTime time) =>
      announcementFor(time, _settings.style, voice);

  void _onMinute(DateTime now) {
    _now = now;
    notifyListeners();
    unawaited(_refreshMenuBar());
    unawaited(_announcer.onMinute(now));
  }

  Future<void> _speak(DateTime time) async {
    final tokens = announcementAt(time);
    final speech = await voice.render(tokens);
    final audio = _settings.chime
        ? const AudioComposer(gap: Duration(milliseconds: 250)).compose([
            _chimes.putIfAbsent(
              speech.sampleRate,
              () => chime(speech.sampleRate),
            ),
            speech,
          ])
        : speech;
    await _platform.play(encodeWav(audio), volume: _settings.volume);
    if (_settings.notify) {
      await _platform.notify(banglaClockWithZone(time), tokens.text);
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
      case ['quit']:
        await _platform.quit();
    }
  }

  Future<void> _refreshMenuBar() async {
    await _platform.setStatusTitle(
      _settings.showClockInMenuBar ? banglaClockFace(_now) : '',
    );
    await _platform.setMenu(menuEntries());
  }

  @visibleForTesting
  List<MenuEntry> menuEntries() => [
    MenuEntry('', banglaClockWithZone(_now), enabled: false),
    const MenuEntry('speak', 'এখনই সময় শুনুন'),
    const MenuEntry.separator(),
    MenuEntry('mute', 'ঘোষণা বন্ধ', checked: _settings.muted),
    MenuEntry(
      'interval',
      'কতক্ষণ পরপর',
      children: [
        for (final minutes in AppSettings.intervals)
          MenuEntry(
            'interval:$minutes',
            intervalLabel(minutes),
            checked: !_settings.muted && _settings.intervalMinutes == minutes,
          ),
      ],
    ),
    const MenuEntry.separator(),
    const MenuEntry('settings', 'সেটিংস…'),
    const MenuEntry('quit', 'বন্ধ করুন'),
  ];

  @override
  void dispose() {
    _ticker.stop();
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}

/// "১৫ মিনিট", "৩০ মিনিট", "১ ঘণ্টা".
String intervalLabel(int minutes) => minutes % 60 == 0
    ? '${banglaDigits(minutes ~/ 60)} ঘণ্টা'
    : '${banglaDigits(minutes)} মিনিট';
