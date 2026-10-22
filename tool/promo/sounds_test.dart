// Renders the launch video's extra voice lines and the chime from the
// app's own voice engine into build/promo/audio/, with each clip's timing.
//
//   flutter test tool/promo/sounds_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:bangla_voice_clock/app/app_controller.dart';
import 'package:bangla_voice_clock/core/audio/chime.dart';
import 'package:bangla_voice_clock/core/audio/wav.dart';
import 'package:bangla_voice_clock/core/speech/bangla_phrase_builder.dart';
import 'package:bangla_voice_clock/core/speech/timer_phrases.dart';
import 'package:bangla_voice_clock/core/settings/app_settings.dart';
import 'package:bangla_voice_clock/core/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/app/app_test.dart' show FakePlatform;

void main() {
  testWidgets('promo sounds', (tester) async {
    final out = Directory('build/promo/audio')..createSync(recursive: true);
    Future<AppController> app(String voice) async {
      final dir = Directory.systemTemp.createTempSync();
      final store = SettingsStore(File('${dir.path}/s.json'));
      await tester.runAsync(() => store.save(AppSettings(voiceId: voice)));
      return (await tester.runAsync(
        () => AppController.create(platform: FakePlatform(), store: store),
      ))!;
    }

    final ai = await app('bn_ai');
    final classic = await app('bn_classic');
    final lines = <String, (AppController, List)>{
      'ai_1020': (ai, ai.announcementAt(DateTime(2026, 1, 1, 10, 20))),
      'ai_1007': (ai, ai.announcementAt(DateTime(2026, 1, 1, 10, 7))),
      'ai_1015_trad': (
        ai,
        ai.announcementAt(
          DateTime(2026, 1, 1, 10, 15),
          style: AnnouncementStyle.traditional,
        ),
      ),
      'classic_1015': (
        classic,
        classic.announcementAt(
          DateTime(2026, 1, 1, 10, 15),
          style: AnnouncementStyle.traditional,
        ),
      ),
      'ai_timer_9': (ai, timeLeftTokens(9)),
      'ai_timer_done': (ai, timerDoneTokens),
    };
    var rate = 0;
    final timing = <String, List<Map<String, Object>>>{};
    for (final MapEntry(:key, value: (c, tokens)) in lines.entries) {
      final pcm = (await tester.runAsync(() => c.voice.render(tokens.cast())))!;
      rate = pcm.sampleRate;
      await tester.runAsync(
        () => File('${out.path}/$key.wav').writeAsBytes(encodeWav(pcm)),
      );
      var at = 0.0;
      timing[key] = [];
      for (final k in c.voice.clipKeysFor(tokens.cast())) {
        final clip = (await tester.runAsync(() => c.voice.clip(k)))!;
        final d = clip.samples.length / clip.sampleRate;
        timing[key]!.add({'key': k, 'start': at, 'dur': d});
        at += d + 0.06;
      }
    }
    await tester.runAsync(
      () => File('${out.path}/chime.wav').writeAsBytes(encodeWav(chime(rate))),
    );
    await tester.runAsync(
      () => File('${out.path}/timing.json').writeAsString(jsonEncode(timing)),
    );
    ai.dispose();
    classic.dispose();
  });
}
