import 'package:bangla_voice_clock/core/speech/bangla_phrase_builder.dart';
import 'package:bangla_voice_clock/core/speech/bangla_words.dart';
import 'package:bangla_voice_clock/core/speech/speech_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final builder = BanglaPhraseBuilder();

  String say(
    int h,
    int m, [
    AnnouncementStyle s = AnnouncementStyle.traditional,
  ]) => builder.build(h, m, style: s).text;

  group('traditional style', () {
    const expected = {
      (0, 0): 'এখন সময় রাত বারোটা',
      (0, 15): 'এখন সময় রাত সোয়া বারোটা',
      (0, 45): 'এখন সময় রাত পৌনে একটা',
      (1, 30): 'এখন সময় রাত দেড়টা',
      (2, 30): 'এখন সময় রাত আড়াইটা',
      (3, 45): 'এখন সময় রাত পৌনে চারটা',
      (4, 0): 'এখন সময় ভোর চারটা',
      (6, 45): 'এখন সময় ভোর পৌনে সাতটা',
      (7, 0): 'এখন সময় সকাল সাতটা',
      (10, 15): 'এখন সময় সকাল সোয়া দশটা',
      (10, 30): 'এখন সময় সকাল সাড়ে দশটা',
      (10, 45): 'এখন সময় সকাল পৌনে এগারোটা',
      (11, 45): 'এখন সময় সকাল পৌনে বারোটা',
      (12, 0): 'এখন সময় দুপুর বারোটা',
      (12, 30): 'এখন সময় দুপুর সাড়ে বারোটা',
      (12, 45): 'এখন সময় দুপুর পৌনে একটা',
      (13, 30): 'এখন সময় দুপুর দেড়টা',
      (14, 30): 'এখন সময় দুপুর আড়াইটা',
      (15, 30): 'এখন সময় দুপুর সাড়ে তিনটা',
      (16, 0): 'এখন সময় বিকাল চারটা',
      (17, 45): 'এখন সময় বিকাল পৌনে ছয়টা',
      (18, 30): 'এখন সময় সন্ধ্যা সাড়ে ছয়টা',
      (19, 15): 'এখন সময় সন্ধ্যা সোয়া সাতটা',
      (20, 0): 'এখন সময় রাত আটটা',
      (23, 45): 'এখন সময় রাত পৌনে বারোটা',
    };
    for (final MapEntry(key: (h, m), value: text) in expected.entries) {
      test('$h:${m.toString().padLeft(2, '0')} → $text', () {
        expect(say(h, m), text);
      });
    }

    test('every quarter hour of the day builds', () {
      for (var h = 0; h < 24; h++) {
        for (final m in [0, 15, 30, 45]) {
          final tokens = builder.build(h, m);
          expect(tokens.first.key, ClipKeys.starter);
          expect(tokens[1].key, ClipKeys.zone(DayZones.standard.forHour(h)));
          expect(tokens.length, inInclusiveRange(3, 4), reason: '$h:$m');
        }
      }
    });

    test('rejects minutes off the quarter hour', () {
      expect(() => builder.build(10, 7), throwsArgumentError);
    });

    test('দেড়টা and আড়াইটা fall back to সাড়ে + hour', () {
      final der = builder.build(13, 30).last;
      expect(der.key, ClipKeys.der);
      expect(der.fallback, [ClipKeys.sare, ClipKeys.hour(1)]);
      final arai = builder.build(2, 30).last;
      expect(arai.fallback, [ClipKeys.sare, ClipKeys.hour(2)]);
    });
  });

  group('exact style', () {
    const exact = AnnouncementStyle.exact;

    test('on the hour has no minutes', () {
      expect(say(10, 0, exact), 'এখন সময় সকাল দশটা');
    });

    test('other minutes use বেজে … মিনিট', () {
      expect(say(10, 7, exact), 'এখন সময় সকাল দশটা বেজে সাত মিনিট');
      expect(say(23, 59, exact), 'এখন সময় রাত এগারোটা বেজে ঊনষাট মিনিট');
      expect(say(0, 1, exact), 'এখন সময় রাত বারোটা বেজে এক মিনিট');
    });

    test('every minute of the day builds', () {
      for (var h = 0; h < 24; h++) {
        for (var m = 0; m < 60; m++) {
          final tokens = builder.build(h, m, style: exact);
          expect(tokens.length, m == 0 ? 3 : 6, reason: '$h:$m');
          if (m > 0) expect(tokens[4].key, ClipKeys.number(m));
        }
      }
    });
  });

  test('number words 1–59 are all present and distinct', () {
    final words = numberWords.sublist(1);
    expect(words, hasLength(59));
    expect(words.toSet(), hasLength(59));
    expect(words.where((w) => w.isEmpty), isEmpty);
  });

  test('hour and minute out of range throw', () {
    expect(() => builder.build(24, 0), throwsRangeError);
    expect(() => builder.build(0, 60), throwsRangeError);
  });

  test('starter can be left out', () {
    final quiet = BanglaPhraseBuilder(includeStarter: false);
    expect(quiet.build(10, 0).text, 'সকাল দশটা');
  });

  group('DayZones', () {
    test('standard table matches the original app', () {
      final z = DayZones.standard;
      final byHour = [for (var h = 0; h < 24; h++) z.forHour(h)];
      expect(byHour, [
        for (var h = 0; h < 4; h++) DayZone.raat,
        for (var h = 4; h < 7; h++) DayZone.bhor,
        for (var h = 7; h < 12; h++) DayZone.sokal,
        for (var h = 12; h < 16; h++) DayZone.dupur,
        for (var h = 16; h < 18; h++) DayZone.bikal,
        for (var h = 18; h < 20; h++) DayZone.sondha,
        for (var h = 20; h < 24; h++) DayZone.raat,
      ]);
    });

    test('custom zones wrap past midnight', () {
      final z = DayZones({6: DayZone.sokal, 18: DayZone.raat});
      expect(z.forHour(3), DayZone.raat);
      expect(z.forHour(6), DayZone.sokal);
      expect(z.forHour(17), DayZone.sokal);
    });

    test('empty or out-of-range tables are rejected', () {
      expect(() => DayZones({}), throwsArgumentError);
      expect(() => DayZones({24: DayZone.raat}), throwsRangeError);
    });
  });
}
