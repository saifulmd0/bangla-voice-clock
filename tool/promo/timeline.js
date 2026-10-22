// The launch video's clock: the music's beat grid, and when each of the
// app's voice lines plays. Shared by index.html (pictures) and render.mjs
// (sound), so the two stay in step.

export const FPS = 60;
export const DURATION = 60;

// build/promo/music/launch.mp3 runs at 112 beats a minute; its first beat
// lands 0.222 s in, and the drop is on bar 8.
export const BEAT = 0.5345;
export const T0 = 0.222;
export const beat = (n) => T0 + n * BEAT;
export const bar = (n) => T0 + n * 4 * BEAT;

// Each scene starts on a bar line.
export const scenes = {
  intro: [0, bar(2)],
  menu: [bar(2), bar(6)],
  title: [bar(6), bar(8)],
  every: [bar(8), bar(10)],
  styles: [bar(10), bar(13)],
  voices: [bar(13), bar(16)],
  quiet: [bar(16), bar(18)],
  timer: [bar(18), bar(20)],
  look: [bar(20), bar(22)],
  everywhere: [bar(22), bar(24)],
  end: [bar(24), DURATION],
};

// The app's own announcements, rendered by tool/showcase_test.dart and
// tool/promo/sounds_test.dart. `words` are each word's start in seconds
// from the start of the file, for the captions.
export const voices = {
  speak: {
    file: 'build/showcase/speak.wav',
    at: 6.35,
    // The app's chime first, then Areeba AI from 1.70 s.
    words: [
      ['এখন', 1.76], ['সময়', 2.32], ['সকাল', 3.06], ['দশটা', 3.64],
      ['বেজে', 3.88], ['বিশ', 4.28], ['মিনিট', 4.56],
    ],
  },
  exact: {
    file: 'build/promo/audio/ai_1007.wav',
    at: bar(10) + 0.25,
    words: [
      ['এখন', 0.06], ['সময়', 0.62], ['সকাল', 1.36], ['দশটা', 1.94],
      ['বেজে', 2.18], ['সাত', 2.58], ['মিনিট', 2.95],
    ],
  },
  traditional: {
    file: 'build/promo/audio/ai_1015_trad.wav',
    at: bar(10) + 3.8,
    words: [
      ['এখন', 0.04], ['সময়', 0.62], ['সকাল', 1.35], ['সোয়া', 1.72],
      ['দশটা', 2.0],
    ],
  },
  classic: {
    file: 'build/promo/audio/classic_1015.wav',
    at: bar(13) + 0.6,
    words: [
      ['এখন', 0.0], ['সময়', 0.55], ['সকাল', 1.2], ['দশটা', 2.13],
      ['বেজে', 2.5], ['পনেরো', 3.04], ['মিনিট', 3.42],
    ],
  },
  timerLeft: {
    file: 'build/promo/audio/ai_timer_9.wav',
    at: bar(18) + 0.6,
    words: [['আর', 0.0], ['নয়', 0.43], ['মিনিট', 0.75], ['বাকি', 1.16]],
  },
  timerDone: {
    file: 'build/promo/audio/ai_timer_done.wav',
    at: bar(19) + 0.95,
    words: [['সময়', 0.0], ['শেষ', 0.55]],
  },
  endChime: {
    file: 'build/promo/audio/chime.wav',
    at: bar(24) + 0.05,
    gain: 0.55,
    words: [],
  },
};

// Mouse clicks in the menu-bar scene.
export const clicks = [5.5, 6.25];

// The quiet-hours scene muffles the music, like a closed door at night.
export const night = scenes.quiet;
