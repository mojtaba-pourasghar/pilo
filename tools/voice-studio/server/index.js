// استودیوی صداگذاری «سفر پیلو» — the local half (ported from the pokpok studio).
//
// A browser cannot write to a folder you name, and it cannot call the آواشو gateway without
// being stopped by CORS. So the React page talks to this small Express server, which keeps the
// token, reads the manifest, records one line at a time, and writes the files where you said.
// Nothing is uploaded or pushed anywhere: the only things it writes are audio files inside the
// project (assets/audio/voice, assets/audio/sfx), the lists beside them in docs/, and its own
// config beside this file.

import express from "express";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import crypto from "node:crypto";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { readManifest, existingKeys, setSpoken, GROUP_LABELS } from "./manifest.js";
import { createRegistry } from "./tts-registry.js";
import { speak, SPEAKERS, VOICES, RateLimited } from "./avasho.js";
import { createSfx } from "./sfx.js";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "..");
const CONFIG_FILE = path.join(ROOT, "voice-studio.config.json");
const PORT = Number(process.env.PORT || 5174);
// The Godot project root (two levels up) this studio belongs to.
const APP = path.resolve(ROOT, "../..");
// Listening clips (_test-…, _diag-…, _sample-…) stay out of assets/audio/voice, which ships in the game.
const SAMPLES = path.join(ROOT, "samples");
// Which clips are TTS (temporary) and which are human recordings — see server/tts-registry.js.
const registry = createRegistry(path.join(APP, "docs/voice/tts_generated.json"));

// ── config ───────────────────────────────────────────────────────────────────
const DEFAULTS = {
  token: "",
  // Every line a character says (built by tools/voice/build_voice_lines.py from the level files).
  manifestPath: path.join(APP, "data/voice/voice_lines.json"),
  // The game plays assets/audio/voice/<key>.mp3 (AudioManager.play_voice), so clips are written
  // straight there and travel with the project.
  outDir: path.join(APP, "assets/audio/voice"),
  // Fallback voice for a line whose character has no entry in `characters`.
  speaker: "pune",
  speed: 1,
  // One voice per character — each line is voiced by its "who". Avasho has no child voices, so
  // the boy Nima is voiced by a young female voice (as in Persian dubbing of children's films).
  characters: {
    nima: { speaker: "bahar", speed: 1 },
    pilo: { speaker: "pune", speed: 0.9 },
    ghubarak: { speaker: "ariya", speed: 1.1 },
    squirrel: { speaker: "sheyda", speed: 1.1 },
  },
  // Every line is a sentence or two, so the short family is the right one.
  endpoint: "short",
  useVowels: true,          // send "spoken" (the respelling with vowels) when a line has one
  concurrency: 2,
  delayMs: 400,
  retries: 3,
  // Bring every clip to the game's format: MP3 mono 96 kbps, −16 LUFS, trimmed with a short
  // lead-in — the same treatment tools/voice/import_recordings.sh gives human recordings.
  // Needs ffmpeg on PATH. Without it the service's own file is kept.
  normalize: true,
  schedule: { enabled: false, everySeconds: 300, batchSize: 25 },
};

/** The voice and pace for one line: its character's, else the default. */
function voiceFor(line) {
  const c = (config.characters || {})[line.who] || {};
  return { speaker: normalizeSpeaker(c.speaker || config.speaker), speed: speedOf(c.speed, config.speed) };
}

/**
 * Two settings decide whether the service answers at all, so neither is taken on trust.
 *
 * A stored «long» is rewritten to «short»: the long family is for pages of text, and the
 * studio only ever sends single sentences. A session that had once picked long kept the
 * generation section on it for good, and that was the whole of «the test tab works but
 * generating does not» — the test tab normalises its endpoint, the job did not.
 */
function normalizeEndpoint(value) {
  return value === "long" ? "long" : "short";
}

function normalizeSpeaker(value) {
  const name = String(value || "").trim().toLowerCase();
  return SPEAKERS.includes(name) ? name : DEFAULTS.speaker;
}

/** A pace the service will accept: half speed to double, one decimal. */
function speedOf(value, fallback = 1) {
  const n = Number(value);
  if (!Number.isFinite(n) || n <= 0) return Number(fallback) || 1;
  return Math.round(Math.min(2, Math.max(0.5, n)) * 10) / 10;
}

/** One sentence Pilo really says, so a sample is judged on the real thing. */
const SAMPLE_TEXT = "سَلام نیما! مَن پیلو هَستَم. غُبارَک تِکّه‌هایِ زَمان را پَخش کَردِه؛ بیا پِیداشان کُنیم!";

/** _sample-pune-090 — the speed in the name, so two paces never overwrite each other. */
const sampleKey = (speaker, speed) =>
  `_sample-${speaker}-${String(Math.round(speed * 100)).padStart(3, "0")}`;

let config = { ...DEFAULTS };
let migrated = null;
try {
  if (fs.existsSync(CONFIG_FILE)) {
    const saved = JSON.parse(fs.readFileSync(CONFIG_FILE, "utf8"));
    config = {
      ...DEFAULTS, ...saved,
      schedule: { ...DEFAULTS.schedule, ...(saved.schedule || {}) },
      characters: { ...DEFAULTS.characters, ...(saved.characters || {}) },
    };
    if (normalizeEndpoint(config.endpoint) === "long") {
      migrated = `نقطه‌ی سرویس از avasho-large به متنِ کوتاه برگشت (جمله‌های بازی کوتاه‌اند)`;
      config.endpoint = "short";
    }
    if (normalizeSpeaker(config.speaker) !== config.speaker) {
      migrated = `${migrated ? migrated + "؛ " : ""}صدای «${config.speaker}» شناخته نشد — `
        + `${DEFAULTS.speaker}`;
      config.speaker = normalizeSpeaker(config.speaker);
    }
  }
} catch (err) {
  console.error("config خوانده نشد:", err.message);
}
config.endpoint = normalizeEndpoint(config.endpoint);
config.speaker = normalizeSpeaker(config.speaker);

let savedAt = fs.existsSync(CONFIG_FILE) ? fs.statSync(CONFIG_FILE).mtimeMs : 0;

/**
 * Writes the settings — the token included — beside this file. Written to a
 * temporary name first and then moved, so a crash half-way cannot leave a truncated config
 * that would look on the next launch as though the token had vanished.
 */
function saveConfig() {
  const temp = CONFIG_FILE + ".tmp";
  fs.writeFileSync(temp, JSON.stringify(config, null, 2), "utf8");
  fs.renameSync(temp, CONFIG_FILE);
  savedAt = Date.now();
}

// ── the live log, shared with the page over SSE ───────────────────────────────
const listeners = new Set();
const log = [];

function say(level, message) {
  const entry = { at: new Date().toISOString(), level, message };
  log.push(entry);
  if (log.length > 600) log.splice(0, log.length - 600);
  const frame = `data: ${JSON.stringify({ type: "log", entry })}\n\n`;
  for (const res of listeners) res.write(frame);
  console.log(`[${entry.at.slice(11, 19)}] ${level}: ${message}`);
}

function push(type, payload) {
  const frame = `data: ${JSON.stringify({ type, ...payload })}\n\n`;
  for (const res of listeners) res.write(frame);
}

// ── the job ──────────────────────────────────────────────────────────────────
const job = {
  running: false,
  stopping: false,
  total: 0,
  done: 0,
  failed: 0,
  current: [],
  startedAt: null,
  lastError: null,
  shapeShown: false,
  traceShown: false,
  controller: null,
};

function snapshot() {
  return {
    running: job.running,
    stopping: job.stopping,
    total: job.total,
    done: job.done,
    failed: job.failed,
    current: job.current,
    startedAt: job.startedAt,
    lastError: job.lastError,
  };
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// The same filter chain as tools/voice/import_recordings.sh, so TTS and recorded clips sound alike.
const NORMALIZE_FILTER = "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.02,"
  + "areverse,silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.02,areverse,"
  + "adelay=80,apad=pad_dur=0.15,loudnorm=I=-16:TP=-1.5:LRA=11";

function normalizeForApp(src, dst) {
  return new Promise((resolve) => {
    const ff = spawn("ffmpeg", ["-y", "-loglevel", "error", "-i", src, "-ac", "1", "-ar", "44100",
      "-af", NORMALIZE_FILTER, "-c:a", "libmp3lame", "-b:a", "96k", dst]);
    ff.on("error", () => resolve(false));
    ff.on("close", (code) => resolve(code === 0));
  });
}

// Effects are louder and shorter than speech: silence trimmed at both ends, cut to a few seconds
// with a soft fade-out so a long field recording does not run on under the next question, and
// brought to −14 LUFS. Only the first minute of the input is read, and ffmpeg is stopped after
// two minutes whatever happens, so a strange file cannot hang the page.
function normalizeSfx(src, dst, maxSeconds) {
  const seconds = Math.min(90, Math.max(1, Number(maxSeconds) || 6));
  const filter = "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.02,"
    + "areverse,silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.05,areverse,"
    + `atrim=0:${seconds},afade=t=out:st=${Math.max(0, seconds - 0.4)}:d=0.4,`
    + "apad=pad_dur=0.1,loudnorm=I=-14:TP=-1.5:LRA=11";
  return new Promise((resolve) => {
    const ff = spawn("ffmpeg", ["-y", "-loglevel", "error", "-t", "60", "-i", src, "-vn", "-ac", "1",
      "-ar", "44100", "-af", filter,
      ...(dst.toLowerCase().endsWith(".ogg") ? ["-c:a", "libvorbis", "-q:a", "5"] : ["-c:a", "libmp3lame", "-b:a", "128k"]),
      dst],
      { stdio: ["ignore", "ignore", "pipe"] });
    const timer = setTimeout(() => ff.kill(), 120000);
    let err = "";
    ff.stderr.on("data", (d) => { err += d; });
    ff.on("error", (e) => { clearTimeout(timer); resolve({ ok: false, error: e.message }); });
    ff.on("close", (code) => {
      clearTimeout(timer);
      resolve(code === 0 ? { ok: true } : { ok: false, error: err.trim().slice(-300) || "ffmpeg ایستاد" });
    });
  });
}

let hasFfmpeg = false;
spawn("ffmpeg", ["-version"]).on("error", () => { hasFfmpeg = false; })
  .on("close", (code) => {
    hasFfmpeg = code === 0;
    if (!hasFfmpeg) say("warn", "ffmpeg پیدا نشد — یکسان‌سازی صدا و بخشِ «صدای حیوان‌ها و وسایل» کار نمی‌کند");
  });

/** Record one line and write it into the output folder. */
async function recordOne(line, { force = false } = {}) {
  if (existingKeys(config.outDir).has(line.key) && !registry.has(line.key)) {
    return { ok: false, error: "این فایل ضبطِ انسانی است و با صدای ماشینی جایگزین نمی‌شود" };
  }
  if (force) {
    for (const ext of [".ogg", ".mp3", ".wav"]) {
      const old = path.join(config.outDir, line.key + ext);
      if (fs.existsSync(old)) fs.unlinkSync(old);
    }
  }
  const text = config.useVowels ? line.spoken : line.written;
  const voice = voiceFor(line);
  let attempt = 0;

  for (;;) {
    attempt += 1;

    // Every exchange is kept, exactly as the test tab keeps them. On the first line they go
    // into the log so a run can be read while it is young, and after that only a failure
    // prints them — otherwise four thousand clips would bury the log.
    const trace = [];
    const step = (entry) => {
      trace.push(entry);
      if (!job.traceShown) {
        say("info", `${line.key} · ${entry.name} ${entry.method} ${entry.status} `
          + `(${entry.ms} میلی‌ثانیه) ${String(entry.body || "").slice(0, 300)}`);
      }
    };

    try {
      const { buffer, ext, raw } = await speak({
        token: config.token, text, speaker: voice.speaker,
        speed: voice.speed, endpoint: config.endpoint,
        timestamps: false,
        signal: job.controller ? job.controller.signal : null,
        onHttp: step,
        onNote: (note) => say("info", `${line.key}: ${note}`),
      });

      job.traceShown = true;
      if (raw && !job.shapeShown) {
        job.shapeShown = true;
        say("info", `شکلِ پاسخِ سرویس: ${JSON.stringify(raw).slice(0, 400)}`);
      }

      fs.mkdirSync(config.outDir, { recursive: true });
      let saved = line.key + ext;
      let size = buffer.length;
      const rawFile = path.join(config.outDir, `.${line.key}.raw${ext}`);
      fs.writeFileSync(rawFile, buffer);
      const target = path.join(config.outDir, line.key + ".mp3");
      if (config.normalize && await normalizeForApp(rawFile, target + ".tmp.mp3")) {
        fs.renameSync(target + ".tmp.mp3", target);
        fs.unlinkSync(rawFile);
        saved = path.basename(target);
        size = fs.statSync(target).size;
      } else {
        if (config.normalize) say("warn", "ffmpeg اجرا نشد؛ فایل با فرمتِ خودِ سرویس ماند");
        fs.renameSync(rawFile, path.join(config.outDir, saved));
        if (ext !== ".mp3") say("warn", `${saved}: برنامه فقط ${line.key}.mp3 را پخش می‌کند`);
      }
      registry.mark(line.key, { who: line.who, speaker: voice.speaker, speed: voice.speed });
      return { ok: true, saved, size };
    } catch (err) {
      const limited = err instanceof RateLimited;
      if (job.traceShown && trace.length) {
        for (const entry of trace) {
          say("warn", `${line.key} · ${entry.name} ${entry.method} ${entry.status} `
            + `(${entry.ms} میلی‌ثانیه) ${String(entry.body || "").slice(0, 300)}`);
        }
      }
      job.traceShown = true;
      if (job.stopping) return { ok: false, error: "ایستاد" };
      if (attempt > Number(config.retries)) {
        return { ok: false, error: err.message };
      }
      const wait = limited ? 20000 * attempt : 1500 * attempt;
      say("warn", `${line.key}: ${err.message} — ${Math.round(wait / 1000)} ثانیه صبر و تلاشِ ${attempt + 1}`);
      await sleep(wait);
    }
  }
}

/**
 * Starts a batch and comes back straight away.
 *
 * The page used to wait on the whole run: one request held open for four thousand clips, with
 * the buttons disabled and the list below untouched until the very end. Now the checks happen
 * here, the answer goes back, and the run reports itself over the stream.
 */
function startJob(keys, { force = false } = {}) {
  if (job.running) return { error: "یک کار در حال اجراست" };
  if (!config.token) return { error: "توکن خالی است" };
  if (!keys.length) return { error: "چیزی برای ساختن نیست" };
  try {
    readManifest(config.manifestPath);
  } catch (err) {
    return { error: `منیفست خوانده نشد: ${err.message}` };
  }
  runJob(keys, { force }).catch((err) => {
    job.running = false;
    job.controller = null;
    job.lastError = err.message;
    say("error", `کار ایستاد: ${err.message}`);
    push("status", snapshot());
  });
  return { started: true };
}

async function runJob(keys, { force = false } = {}) {
  const lines = readManifest(config.manifestPath);
  const byKey = new Map(lines.map((l) => [l.key, l]));
  const todo = keys.map((k) => byKey.get(k)).filter(Boolean);

  Object.assign(job, { running: true, stopping: false, total: todo.length, done: 0,
                       failed: 0, current: [], startedAt: Date.now(), lastError: null,
                       traceShown: false, controller: new AbortController() });
  say("info", `شروع: ${todo.length} کلیپ — هر جمله با صدای شخصیتِ خودش، `
    + `${config.endpoint === "long" ? "avasho-large" : "avasho (متنِ کوتاه)"} → ${config.outDir}`);
  push("status", snapshot());

  let cursor = 0;
  const workers = Array.from({ length: Math.max(1, Number(config.concurrency)) }, async () => {
    while (cursor < todo.length && !job.stopping) {
      const line = todo[cursor++];
      job.current = [...job.current.filter((k) => k !== line.key), line.key];
      push("status", snapshot());

      const result = await recordOne(line, { force });
      job.current = job.current.filter((k) => k !== line.key);
      if (result.ok) {
        job.done += 1;
        say("ok", `${line.key} ← ${result.saved} (${Math.round(result.size / 1024)} کیلوبایت)`);
      } else {
        job.failed += 1;
        job.lastError = result.error;
        say("error", `${line.key}: ${result.error}`);
      }
      // the list at the bottom of the page follows along: one line, one frame, as it happens.
      // Waiting for the whole batch to end before rereading the folder made a run look frozen.
      push("line", { key: line.key, done: result.ok, stamp: Date.now(),
                     file: result.ok ? result.saved : null, size: result.ok ? result.size : 0 });
      push("status", snapshot());
      if (Number(config.delayMs) > 0) await sleep(Number(config.delayMs));
    }
  });

  await Promise.all(workers);
  job.running = false;
  job.current = [];
  job.controller = null;
  say("info", job.stopping
    ? `ایستاد — ${job.done} ساخته، ${job.failed} ناموفق`
    : `تمام — ${job.done} ساخته، ${job.failed} ناموفق`);
  job.stopping = false;
  push("status", snapshot());
}

// ── the scheduler: wake up now and then and take the next batch ───────────────
let timer = null;

function applySchedule() {
  if (timer) clearInterval(timer);
  timer = null;
  if (!config.schedule.enabled) {
    say("info", "زمان‌بندی خاموش شد");
    return;
  }
  const every = Math.max(30, Number(config.schedule.everySeconds) || 300);
  say("info", `زمان‌بندی روشن: هر ${every} ثانیه، ${config.schedule.batchSize} کلیپ`);
  timer = setInterval(() => {
    if (job.running) return;
    const missing = missingKeys();
    if (!missing.length) {
      say("info", "زمان‌بندی: چیزی باقی نمانده");
      return;
    }
    const batch = missing.slice(0, Math.max(1, Number(config.schedule.batchSize) || 25));
    say("info", `زمان‌بندی: دسته‌ی تازه، ${batch.length} کلیپ`);
    startJob(batch);
  }, every * 1000);
}

function missingKeys() {
  const lines = readManifest(config.manifestPath);
  const have = existingKeys(config.outDir);
  return lines.filter((l) => !have.has(l.key)).map((l) => l.key);
}

// ── HTTP ─────────────────────────────────────────────────────────────────────
const app = express();
app.use(express.json({ limit: "64mb" }));   // a worksheet PDF arrives as base64

const publicConfig = () => ({
  ...config,
  token: undefined,
  tokenSet: Boolean(config.token),
  tokenHint: config.token ? `${config.token.slice(0, 6)}…${config.token.slice(-4)}` : "",
  configFile: CONFIG_FILE,
  savedAt,
  speakers: SPEAKERS,
  voices: VOICES.filter((v) => SPEAKERS.includes(v.name)),
  groupLabels: GROUP_LABELS,
  ffmpeg: hasFfmpeg,
});

app.get("/api/config", (_req, res) => res.json(publicConfig()));

app.post("/api/config", (req, res) => {
  const body = req.body || {};
  for (const key of ["manifestPath", "outDir"]) {
    if (typeof body[key] === "string" && body[key].trim()) config[key] = body[key].trim();
  }
  if (typeof body.speaker === "string" && body.speaker.trim()) {
    config.speaker = normalizeSpeaker(body.speaker);
  }
  // { characters: { pilo: { speaker: "pune", speed: 0.95 }, … } } — one or more characters at a time
  if (body.characters && typeof body.characters === "object") {
    for (const [who, v] of Object.entries(body.characters)) {
      const old = config.characters[who] || {};
      config.characters[who] = {
        speaker: normalizeSpeaker(v?.speaker || old.speaker),
        speed: speedOf(v?.speed ?? old.speed, 1),
      };
    }
  }
  if (typeof body.endpoint === "string" && body.endpoint.trim()) {
    config.endpoint = normalizeEndpoint(body.endpoint.trim());
  }
  for (const key of ["speed", "concurrency", "delayMs", "retries"]) {
    if (body[key] !== undefined && body[key] !== "") config[key] = Number(body[key]);
  }
  for (const key of ["useVowels", "normalize"]) {
    if (typeof body[key] === "boolean") config[key] = body[key];
  }
  if (typeof body.token === "string" && body.token.trim()) {
    config.token = body.token.trim();
    say("info", "توکن ذخیره شد");
  }
  if (body.token === "") {
    config.token = "";
    say("info", "توکن پاک شد");
  }
  if (body.schedule) {
    config.schedule = { ...config.schedule, ...body.schedule };
    applySchedule();
  }
  saveConfig();
  res.json(publicConfig());
});

app.get("/api/manifest", (_req, res) => {
  try {
    const lines = readManifest(config.manifestPath);
    const have = existingKeys(config.outDir);
    const overrides = readOverrides();
    const tts = registry.keys();
    res.json({
      outDir: config.outDir,
      ttsFile: registry.file,
      lines: lines.map((l) => {
        const file = have.get(l.key);
        return {
          ...l,
          done: Boolean(file),
          file: file?.name ?? null,
          size: file?.size ?? 0,
          edited: Object.prototype.hasOwnProperty.call(overrides, l.key),
          tts: tts.has(l.key),
        };
      }),
    });
  } catch (err) {
    res.status(400).json({ error: `منیفست خوانده نشد: ${err.message}` });
  }
});

app.get("/api/status", (_req, res) => res.json({ ...snapshot(), log: log.slice(-120) }));

// ── «does the service work at all?» ──────────────────────────────────────────
// One call, with every exchange written down: the address, the status, how long it took and
// the start of the body. When something does not work this is what turns «it failed» into a
// sentence someone can act on.
const diag = { running: false, controller: null, steps: [], startedAt: 0, outcome: null };

app.get("/api/diag", (_req, res) => res.json({
  running: diag.running, steps: diag.steps, startedAt: diag.startedAt, outcome: diag.outcome,
  speakers: SPEAKERS, voices: VOICES,
}));

app.post("/api/diag", async (req, res) => {
  if (!config.token) return res.status(400).json({ error: "توکن خالی است" });
  if (diag.running) return res.status(409).json({ error: "یک تست در حال اجراست" });

  // the same two guards the job uses, so the two sections can never drift apart again
  const speaker = normalizeSpeaker(req.body?.speaker || config.speaker);
  const endpoint = normalizeEndpoint(req.body?.endpoint);
  const text = String(req.body?.text || SAMPLE_TEXT);
  const speed = speedOf(req.body?.speed, config.speed);
  const timestamps = req.body?.timestamps === true;

  diag.controller = new AbortController();
  Object.assign(diag, { running: true, steps: [], startedAt: Date.now(), outcome: null });
  push("diag", { running: true, steps: [] });
  say("info", `تستِ وب‌سرویس — ${endpoint === "long" ? "avasho-large" : "avasho"}، `
    + `صدای ${speaker}، سرعتِ ${speed}`);
  res.json({ started: true });

  const step = (entry) => {
    diag.steps.push({ at: Date.now() - diag.startedAt, ...entry });
    push("diag", { running: true, steps: diag.steps });
  };

  try {
    const { buffer, ext, timestamps: marks } = await speak({
      token: config.token, text, speaker, speed,
      endpoint, timestamps,
      signal: diag.controller.signal,
      onHttp: step,
      onNote: (note) => say("info", `تست: ${note}`),
    });

    fs.mkdirSync(SAMPLES, { recursive: true });
    const name = `_diag-${speaker}${ext}`;
    fs.writeFileSync(path.join(SAMPLES, name), buffer);
    diag.outcome = {
      ok: true, file: name, bytes: buffer.length, ext,
      words: marks ? marks.length : 0,
      ms: Date.now() - diag.startedAt,
    };
    say("ok", `تست موفق — ${name}، ${Math.round(buffer.length / 1024)} کیلوبایت، `
      + `${((Date.now() - diag.startedAt) / 1000).toFixed(1)} ثانیه`);
  } catch (err) {
    diag.outcome = { ok: false, error: err.message, ms: Date.now() - diag.startedAt };
    say("error", `تست ناموفق: ${err.message}`);
  } finally {
    diag.running = false;
    diag.controller = null;
    push("diag", { running: false, steps: diag.steps, outcome: diag.outcome });
  }
});

app.post("/api/diag/stop", (_req, res) => {
  if (diag.controller) {
    diag.controller.abort();
    say("warn", "تست متوقف شد");
  }
  res.json({ ok: true });
});

// ── نمونه‌ها: choosing a voice and a pace by ear ──────────────────────────────
//
// Fourteen voices and a handful of speeds are not a thing to argue about; they are a thing to
// listen to. This records the same sentence across whichever set is asked for and leaves the
// clips in the output folder under «_sample-…», where the page plays them side by side. The
// underscore keeps them out of index.json, so a sample can never reach the host as a lesson.
const sampler = { running: false, controller: null, mode: "", text: "", items: [],
                  duplicates: [] };

function samplerState() {
  return { running: sampler.running, mode: sampler.mode, text: sampler.text,
           items: sampler.items, duplicates: sampler.duplicates };
}

/**
 * Names whose clip is byte-for-byte another's.
 *
 * Two different voices reading the same sentence cannot produce the same bytes, so a match is
 * the service handing back one recording for several names — the one answer to «I chose a man
 * and got a woman» that does not depend on anyone's ear.
 */
function identicalSets(items) {
  const byHash = new Map();
  for (const item of items) {
    if (!item.hash) continue;
    const label = item.speed === items[0]?.speed
      ? item.speaker : `${item.speaker}@${item.speed}`;
    byHash.set(item.hash, [...(byHash.get(item.hash) || []), label]);
  }
  return [...byHash.values()].filter((set) => set.length > 1);
}

app.get("/api/diag/sample", (_req, res) => res.json(samplerState()));

app.post("/api/diag/sample", async (req, res) => {
  if (!config.token) return res.status(400).json({ error: "توکن خالی است" });
  if (sampler.running) return res.status(409).json({ error: "یک نمونه‌گیری در حال اجراست" });

  const mode = req.body?.mode === "speeds" ? "speeds" : "voices";
  const text = String(req.body?.text || SAMPLE_TEXT);
  const endpoint = normalizeEndpoint(req.body?.endpoint);
  const speed = speedOf(req.body?.speed, config.speed);
  const speaker = normalizeSpeaker(req.body?.speaker || config.speaker);

  let pairs;
  if (mode === "speeds") {
    const speeds = Array.isArray(req.body?.speeds) && req.body.speeds.length
      ? req.body.speeds.map((v) => speedOf(v, 1))
      : [0.8, 0.9, 1, 1.1];
    pairs = [...new Set(speeds)].map((sp) => ({ speaker, speed: sp }));
  } else {
    const gender = ["male", "female"].includes(req.body?.gender) ? req.body.gender : null;
    pairs = VOICES.filter((v) => !gender || v.gender === gender)
                  .map((v) => ({ speaker: v.name, speed }));
  }

  sampler.controller = new AbortController();
  Object.assign(sampler, { running: true, mode, text, duplicates: [],
    items: pairs.map((pair) => ({
      ...pair, key: sampleKey(pair.speaker, pair.speed), state: "در نوبت",
    })) });
  push("sample", samplerState());
  say("info", mode === "speeds"
    ? `نمونه‌ی سرعت‌ها — ${speaker}، ${pairs.map((p) => p.speed).join("، ")}`
    : `نمونه‌ی گوینده‌ها — ${pairs.length} صدا، سرعتِ ${speed}`);
  res.json({ started: true, items: sampler.items.length });

  fs.mkdirSync(SAMPLES, { recursive: true });
  for (const item of sampler.items) {
    if (sampler.controller?.signal.aborted) {
      item.state = "ایستاد";
      continue;
    }
    item.state = "در حال ساخت";
    push("sample", samplerState());
    try {
      const { buffer, ext } = await speak({
        token: config.token, text, speaker: item.speaker, speed: item.speed,
        endpoint, timestamps: false, signal: sampler.controller.signal,
        // what went out and what came back, kept per row: «it made a female voice» is then a
        // thing anyone can check instead of a thing to take on trust
        onHttp: (entry) => {
          if (entry.name === "request") item.reply = String(entry.body || "").slice(0, 400);
        },
      });
      // one name per voice-and-speed, whatever the container turns out to be
      for (const old of [".ogg", ".mp3", ".wav"]) {
        const stale = path.join(SAMPLES, item.key + old);
        if (old !== ext && fs.existsSync(stale)) fs.unlinkSync(stale);
      }
      fs.writeFileSync(path.join(SAMPLES, item.key + ext), buffer);
      item.state = "آماده";
      item.bytes = buffer.length;
      // the fingerprint of the audio itself. Two names that come back with the same one got
      // the same recording, and that means the service ignored the name it was given.
      item.hash = crypto.createHash("sha1").update(buffer).digest("hex").slice(0, 10);
      say("ok", `نمونه: ${item.speaker} با سرعتِ ${item.speed} — `
        + `${Math.round(buffer.length / 1024)} کیلوبایت · ${item.hash}`);
    } catch (err) {
      item.state = "نشد";
      item.error = err.message;
      say("error", `نمونه‌ی ${item.speaker}: ${err.message}`);
    }
    push("sample", samplerState());
    if (Number(config.delayMs) > 0) await sleep(Number(config.delayMs));
  }

  sampler.running = false;
  sampler.controller = null;
  const ready = sampler.items.filter((i) => i.state === "آماده").length;
  sampler.duplicates = identicalSets(sampler.items);
  for (const set of sampler.duplicates) {
    say("warn", `سرویس برای ${set.join("، ")} فایلِ یکسان داد — نامِ گوینده را نگرفته است`);
  }
  say("info", `نمونه‌ها تمام — ${ready} از ${sampler.items.length} آماده`
    + (sampler.duplicates.length ? `، ${sampler.duplicates.length} دسته تکراری` : ""));
  push("sample", samplerState());
});

app.post("/api/diag/sample/stop", (_req, res) => {
  if (sampler.controller) {
    sampler.controller.abort();
    say("warn", "نمونه‌گیری متوقف شد");
  }
  res.json({ ok: true });
});

/** Takes the voice and the pace that were just listened to and makes them the settings. */
app.post("/api/diag/sample/pick", (req, res) => {
  const speaker = normalizeSpeaker(req.body?.speaker);
  const speed = speedOf(req.body?.speed, config.speed);
  // with { who } the sample becomes that character's voice; without it, the fallback voice
  const who = String(req.body?.who || "");
  if (who && config.characters[who]) config.characters[who] = { speaker, speed };
  else {
    config.speaker = speaker;
    config.speed = speed;
  }
  saveConfig();
  const voice = VOICES.find((v) => v.name === speaker);
  say("ok", `${who ? `صدای ${who}` : "صدای پیش‌فرض"}: ${voice ? voice.label : speaker} (${speaker})، سرعتِ ${speed}`);
  res.json(publicConfig());
});

// ── fixing the words of one line ─────────────────────────────────────────────
// The manifest is generated from the lesson sources, so an edit typed here would be lost the
// next time it is rebuilt. It is therefore kept in tools/voice-overrides.json — which goes into
// git — and the manifest line is patched straight away so the change takes effect now.
const OVERRIDES = path.resolve(ROOT, "../voice/voice-overrides.json");

function readOverrides() {
  try {
    return JSON.parse(fs.readFileSync(OVERRIDES, "utf8"));
  } catch {
    return {};
  }
}

function patchManifestLine(key, spoken) {
  if (config.manifestPath.toLowerCase().endsWith(".json")) return setSpoken(config.manifestPath, key, spoken);
  const text = fs.readFileSync(config.manifestPath, "utf8");
  const lines = text.split(/\r?\n/);
  let hit = false;
  for (let i = 0; i < lines.length; i++) {
    if (!lines[i].startsWith(key + " |")) continue;
    const cols = lines[i].split("|").map((c) => c.trim());
    lines[i] = `${cols[0]} | ${cols[1]} | ${spoken}`;
    hit = true;
    break;
  }
  if (!hit) return false;
  fs.writeFileSync(config.manifestPath, lines.join("\n"), "utf8");
  return true;
}

app.get("/api/overrides", (_req, res) => res.json({ file: OVERRIDES, overrides: readOverrides() }));

app.post("/api/text", (req, res) => {
  const key = String(req.body?.key || "").trim();
  const spoken = String(req.body?.spoken || "").trim();
  if (!key || !spoken) return res.status(400).json({ error: "کلید و متن لازم است" });
  if (spoken.includes("|")) return res.status(400).json({ error: "متن نباید | داشته باشد" });

  try {
    const overrides = readOverrides();
    overrides[key] = spoken;
    fs.writeFileSync(OVERRIDES, JSON.stringify(overrides, null, 2), "utf8");
    const patched = patchManifestLine(key, spoken);
    say("ok", `متنِ ${key} عوض شد${patched ? "" : " (در منیفست پیدا نشد)"} — در voice-overrides.json ماند`);
    res.json({ ok: true, patched, file: OVERRIDES });
  } catch (err) {
    say("error", `متن ذخیره نشد: ${err.message}`);
    res.status(400).json({ error: err.message });
  }
});

app.delete("/api/text/:key", (req, res) => {
  const overrides = readOverrides();
  delete overrides[req.params.key];
  fs.writeFileSync(OVERRIDES, JSON.stringify(overrides, null, 2), "utf8");
  if (config.manifestPath.toLowerCase().endsWith(".json")) setSpoken(config.manifestPath, req.params.key, null);
  say("warn", `تلفظِ ویژه‌ی ${req.params.key} برداشته شد — متنِ اصلی خوانده می‌شود`);
  res.json({ ok: true });
});

app.post("/api/generate", async (req, res) => {
  const keys = Array.isArray(req.body?.keys) ? req.body.keys : [];
  const picked = keys.length ? keys : missingKeys();
  const limit = Number(req.body?.limit);
  const batch = Number.isFinite(limit) && limit > 0 ? picked.slice(0, limit) : picked;
  const outcome = startJob(batch, { force: req.body?.force === true });
  if (outcome.error) return res.status(409).json(outcome);
  res.json({ ok: true, started: batch.length });
});

app.post("/api/stop", (_req, res) => {
  if (job.running) {
    job.stopping = true;
    // the test tab can be stopped mid-request; so can this one now
    if (job.controller) job.controller.abort();
    say("warn", "درخواستِ ایستادن");
  }
  res.json(snapshot());
});

app.post("/api/test", async (req, res) => {
  if (!config.token) return res.status(400).json({ error: "توکن خالی است" });
  const who = String(req.body?.who || "pilo");
  const voice = voiceFor({ who });
  const text = String(req.body?.text || SAMPLE_TEXT);
  try {
    const { buffer, ext, raw } = await speak({
      token: config.token, text, speaker: voice.speaker,
      speed: voice.speed, endpoint: config.endpoint,
      onNote: (note) => say("info", `تست: ${note}`),
    });
    fs.mkdirSync(SAMPLES, { recursive: true });
    const name = `_test-${who}${ext}`;
    fs.writeFileSync(path.join(SAMPLES, name), buffer);
    say("ok", `تستِ صدا ساخته شد: ${name} (${Math.round(buffer.length / 1024)} کیلوبایت)`);
    res.json({ ok: true, file: name, bytes: buffer.length, shape: raw ? JSON.stringify(raw).slice(0, 400) : null });
  } catch (err) {
    say("error", `تستِ صدا نشد: ${err.message}`);
    res.status(502).json({ error: err.message });
  }
});

// play a produced file back in the browser
app.get("/api/audio/:key", (req, res) => {
  const dir = req.params.key.startsWith("_") ? SAMPLES : config.outDir;
  const file = existingKeys(dir).get(req.params.key);
  if (!file) return res.status(404).end();
  res.sendFile(path.join(dir, file.name));
});

app.delete("/api/audio/:key", (req, res) => {
  const have = existingKeys(config.outDir);
  const file = have.get(req.params.key);
  if (!file) return res.status(404).end();
  if (!registry.has(req.params.key)) {
    return res.status(400).json({ error: "این فایل ضبطِ انسانی است؛ از اینجا پاک نمی‌شود" });
  }
  fs.unlinkSync(path.join(config.outDir, file.name));
  say("warn", `پاک شد: ${file.name}`);
  res.json({ ok: true });
});

app.get("/api/events", (req, res) => {
  res.writeHead(200, {
    "Content-Type": "text/event-stream",
    "Cache-Control": "no-cache",
    Connection: "keep-alive",
  });
  res.write(`data: ${JSON.stringify({ type: "status", ...snapshot() })}\n\n`);
  listeners.add(res);
  req.on("close", () => listeners.delete(res));
});

// ── صداهای بازی و محیط: real recordings dropped in by hand ──────────────────
// A file found by a person (Freesound, Pixabay, a recording of their own) is dropped on the page,
// cleaned up by ffmpeg and written over the .ogg the game already plays (assets/audio/sfx, ambient,
// music) — inside the project, so the next export carries it. Nothing is uploaded anywhere.
const sfx = createSfx({ app: APP, normalize: normalizeSfx, say });

app.get("/api/sfx", (_req, res) => {
  try {
    res.json(sfx.list());
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.get("/api/sfx/:id/audio", (req, res) => {
  const file = sfx.fileOf(req.params.id);
  if (!file || !fs.existsSync(file)) return res.status(404).end();
  res.sendFile(file);
});

app.post("/api/sfx/:id", express.raw({ type: "*/*", limit: "40mb" }), async (req, res) => {
  if (!hasFfmpeg) return res.status(400).json({ error: "ffmpeg پیدا نشد؛ اول نصبش کن (README)" });
  if (!req.body?.length) return res.status(400).json({ error: "فایلی نرسید" });
  try {
    const outcome = await sfx.replace(req.params.id, req.body, {
      name: String(req.query.name || ""),
      source: String(req.query.source || ""),
      license: String(req.query.license || ""),
      maxSeconds: Number(req.query.max) || 6,
    });
    res.json(outcome);
  } catch (err) {
    say("error", `${req.params.id}: ${err.message}`);
    res.status(400).json({ error: err.message });
  }
});

app.post("/api/sfx/:id/meta", (req, res) => {
  try {
    res.json(sfx.setMeta(req.params.id, req.body || {}));
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

const dist = path.join(ROOT, "dist");
if (fs.existsSync(dist)) {
  app.use(express.static(dist));
  app.get("*", (_req, res) => res.sendFile(path.join(dist, "index.html")));
}

app.listen(PORT, "127.0.0.1", () => {
  console.log(`\n  استودیوی صداگذاری سفر پیلو → http://127.0.0.1:${PORT}\n`);
  console.log(`  منیفست : ${config.manifestPath}`);
  console.log(`  خروجی  : ${config.outDir}`);
  console.log(`  صداها  : ${Object.entries(config.characters).map(([w, c]) => `${w}=${c.speaker}@${c.speed}`).join("، ")}`);
  console.log(`  سرویس  : ${config.endpoint === "long" ? "avasho-large" : "avasho (متنِ کوتاه)"}\n`);
  if (migrated) {
    say("warn", migrated);
    saveConfig();
  }
  if (config.schedule.enabled) applySchedule();
});
