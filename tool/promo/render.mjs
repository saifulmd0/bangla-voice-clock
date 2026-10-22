// Renders the launch video: every frame of index.html through Chrome, the
// app's voices and the music mixed under it, into build/promo/out/.
//
//   node tool/promo/render.mjs                 # landscape and vertical
//   node tool/promo/render.mjs vertical        # one format
//   node tool/promo/render.mjs stills 6.5 20   # PNGs of single moments
//
// Needs Google Chrome and ffmpeg, the window renders and sounds from
// `flutter test tool/showcase_test.dart` and tool/promo/sounds_test.dart,
// the fonts in build/promo/fonts and the music at build/promo/music/launch.mp3.
import { spawn, execFileSync } from 'node:child_process';
import { createServer } from 'node:http';
import { readFile, mkdir } from 'node:fs/promises';
import { extname, join, resolve } from 'node:path';
import puppeteer from 'puppeteer-core';
import { FPS, DURATION, voices, clicks, night } from './timeline.js';

const root = resolve(import.meta.dirname, '../..');
const outDir = join(root, 'build/promo/out');
const chrome = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const music = join(root, 'build/promo/music/launch.mp3');
const formats = { landscape: [1920, 1080], vertical: [1080, 1920] };

const types = { '.html': 'text/html', '.js': 'text/javascript', '.png': 'image/png', '.ttf': 'font/ttf', '.woff2': 'font/woff2' };
function serve() {
  const server = createServer(async (req, res) => {
    try {
      const path = join(root, decodeURIComponent(new URL(req.url, 'http://x').pathname));
      if (!path.startsWith(root)) throw new Error('outside');
      const body = await readFile(path);
      res.writeHead(200, { 'content-type': types[extname(path)] ?? 'application/octet-stream' });
      res.end(body);
    } catch {
      res.writeHead(404).end();
    }
  });
  return new Promise((ok) => server.listen(0, '127.0.0.1', () => ok(server)));
}

// Each voice file's loudness, 100 values a second, for the rings and meters.
function envelopes() {
  const out = {};
  for (const [name, v] of Object.entries(voices)) {
    const pcm = execFileSync('ffmpeg', ['-v', 'error', '-i', join(root, v.file), '-ac', '1', '-ar', '8000', '-f', 's16le', '-']);
    const samples = new Int16Array(pcm.buffer, pcm.byteOffset, pcm.length / 2);
    const env = [];
    for (let i = 0; i < samples.length; i += 80) {
      let sum = 0;
      for (let j = i; j < Math.min(i + 80, samples.length); j++) sum += (samples[j] / 32768) ** 2;
      env.push(+Math.sqrt(sum / 80).toFixed(4));
    }
    out[name] = env;
  }
  return out;
}

async function open(browser, url, format, env) {
  const [w, h] = formats[format];
  const page = await browser.newPage();
  await page.setViewport({ width: w, height: h, deviceScaleFactor: 1 });
  await page.evaluateOnNewDocument((e) => { window.ENVELOPES = e; }, env);
  page.on('pageerror', (e) => console.error('page:', e.message));
  await page.goto(`${url}/tool/promo/index.html?f=${format}`, { waitUntil: 'networkidle0' });
  await page.evaluate(() => window.ready);
  return page;
}

async function frames(page, format) {
  const silent = join(outDir, `${format}-video.mp4`);
  const ffmpeg = spawn('ffmpeg', ['-v', 'error', '-y', '-f', 'image2pipe', '-framerate', String(FPS), '-c:v', 'mjpeg', '-i', '-',
    '-c:v', 'libx264', '-preset', 'slow', '-crf', '16', '-pix_fmt', 'yuv420p', '-r', String(FPS), silent], { stdio: ['pipe', 'inherit', 'inherit'] });
  const cdp = await page.createCDPSession();
  const total = Math.round(DURATION * FPS);
  const started = Date.now();
  for (let f = 0; f < total; f++) {
    await page.evaluate((t) => window.seek(t), f / FPS);
    const { data } = await cdp.send('Page.captureScreenshot', { format: 'jpeg', quality: 94, optimizeForSpeed: true });
    if (!ffmpeg.stdin.write(Buffer.from(data, 'base64'))) await new Promise((ok) => ffmpeg.stdin.once('drain', ok));
    if (f % 300 === 0) console.log(`${format}: ${(f / FPS).toFixed(0)} s of ${DURATION} (${((Date.now() - started) / 1000).toFixed(0)} s elapsed)`);
  }
  ffmpeg.stdin.end();
  await new Promise((ok, fail) => ffmpeg.on('close', (c) => (c ? fail(new Error(`ffmpeg ${c}`)) : ok())));
  return silent;
}

// The soundtrack: music ducked under each voice line and muffled for the
// night scene, the app's voices on top, a soft click for each mouse click.
function soundtrack() {
  const out = join(outDir, 'soundtrack.wav');
  const list = Object.values(voices);
  const inputs = ['-i', music, ...list.flatMap((v) => ['-i', join(root, v.file)])];
  // A short, soft click, made here rather than recorded.
  inputs.push('-f', 'lavfi', '-i', 'sine=frequency=2600:duration=0.03,afade=t=out:st=0:d=0.03,volume=0.35');
  const clickIn = list.length + 1;
  const dur = (v) => +execFileSync('ffprobe', ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', join(root, v.file)]).toString();
  // Down to 30% while a voice speaks, with short ramps either side.
  const duck = list.filter((v) => !v.gain).map((v) => {
    const a = v.at, b = v.at + dur(v);
    return `clip((t-${(a - 0.25).toFixed(3)})/0.25,0,1)*clip((${(b + 0.35).toFixed(3)}-t)/0.35,0,1)`;
  }).join('+');
  const [n0, n1] = night;
  const dark = `clip((t-${(n0 - 0.2).toFixed(3)})/0.5,0,1)*clip((${(n1 + 0.1).toFixed(3)}-t)/0.4,0,1)`;
  const f = [];
  f.push(`[0:a]atrim=0:${DURATION},asplit=2[m1][m2]`);
  f.push(`[m1]volume='(1-0.7*min(1,${duck}))*(1-${dark})':eval=frame[dry]`);
  f.push(`[m2]lowpass=f=520,lowpass=f=520,volume='0.75*(1-0.7*min(1,${duck}))*(${dark})':eval=frame[wet]`);
  list.forEach((v, i) => {
    const ms = Math.round(v.at * 1000);
    f.push(`[${i + 1}:a]aresample=48000,pan=stereo|c0=c0|c1=c0,volume=${v.gain ?? 1.9},adelay=${ms}|${ms}[v${i}]`);
  });
  const clickTags = clicks.map((_, i) => `[c${i}]`);
  f.push(`[${clickIn}:a]aresample=48000,pan=stereo|c0=c0|c1=c0,asplit=${clicks.length}${clickTags.join('')}`);
  clicks.forEach((c, i) => {
    const ms = Math.round(c * 1000);
    f.push(`[c${i}]adelay=${ms}|${ms}[k${i}]`);
  });
  const mixIns = ['[dry]', '[wet]', ...list.map((_, i) => `[v${i}]`), ...clicks.map((_, i) => `[k${i}]`)];
  f.push(`${mixIns.join('')}amix=inputs=${mixIns.length}:normalize=0:duration=longest,atrim=0:${DURATION},` +
    `afade=t=out:st=${DURATION - 1.5}:d=1.5,loudnorm=I=-14:TP=-1.0:LRA=11,aresample=48000[mix]`);
  execFileSync('ffmpeg', ['-v', 'error', '-y', ...inputs, '-filter_complex', f.join(';'), '-map', '[mix]', '-c:a', 'pcm_s16le', out]);
  return out;
}

const mode = process.argv[2];
await mkdir(outDir, { recursive: true });
const server = await serve();
const url = `http://127.0.0.1:${server.address().port}`;
const browser = await puppeteer.launch({ executablePath: chrome, headless: true, args: ['--force-color-profile=srgb', '--disable-lcd-text', '--font-render-hinting=none'] });
try {
  const env = envelopes();
  if (mode === 'stills') {
    const times = process.argv.slice(3).map(Number);
    for (const format of Object.keys(formats)) {
      const page = await open(browser, url, format, env);
      for (const t of times) {
        await page.evaluate((x) => window.seek(x), t);
        await page.screenshot({ path: join(outDir, `still-${format}-${t.toFixed(2)}.png`) });
      }
      await page.close();
    }
  } else {
    const audio = soundtrack();
    for (const format of mode ? [mode] : Object.keys(formats)) {
      const page = await open(browser, url, format, env);
      const video = await frames(page, format);
      await page.close();
      const final = join(outDir, `BanglaVoiceClock-launch-${format}.mp4`);
      execFileSync('ffmpeg', ['-v', 'error', '-y', '-i', video, '-i', audio, '-c:v', 'copy', '-c:a', 'aac', '-b:a', '256k', '-movflags', '+faststart', '-shortest', final]);
      console.log(`Wrote ${final}`);
    }
  }
} finally {
  await browser.close();
  server.close();
}
