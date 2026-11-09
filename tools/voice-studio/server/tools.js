// تب «ابزارها»: کلیدهای Cloudflare، ساخت دوبارهٔ تصویرها، و دانلود صدای محیط واقعی.
//
// Everything here runs the project's own Python tools on this computer, the same ones used to
// make the game's art and sounds:
//   - tools/art/cf_generate.py + tools/art/postprocess.py: (re)make pictures listed in
//     tools/art/manifest.json with Cloudflare Workers AI, rotating over the saved accounts;
//   - tools/audio/fetch_ambience.py: download the hand-picked real recordings in
//     tools/audio/picks.json from Wikimedia Commons and turn them into seamless loops.
//
// The Cloudflare keys are pasted once in the tab and kept only in voice-studio.config.json next
// to this folder (in .gitignore — never committed); they reach the Python tools only through the
// CF_KEYS environment variable of the process the studio starts. Only one job runs at a time,
// and its output lines go to the studio log.

import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { spawn } from "node:child_process";

/** "https://creativecommons.org/licenses/by/4.0/" -> "CC BY 4.0" */
function licenceName(url) {
  if (/publicdomain\/zero/.test(url)) return "CC0";
  const m = String(url).match(/licenses\/([a-z-]+)\/([\d.]+)/);
  return m ? `CC ${m[1].toUpperCase()} ${m[2]}` : String(url);
}

/** Reads «CF_API_TOKEN=… / CF_ACCOUNT_ID=…» pairs (in either order, any spacing) or account:token lines. */
export function parseCloudflare(text) {
  const accounts = [];
  let token = "";
  let account = "";
  const push = () => {
    if (token && account && !accounts.some((a) => a.token === token)) accounts.push({ account, token });
    token = "";
    account = "";
  };
  for (const raw of String(text || "").split(/[\r\n,]+/)) {
    const line = raw.trim();
    if (!line) continue;
    let m = line.match(/^CF_API_TOKEN\s*[=:]\s*(\S+)/i);
    if (m) { if (token) push(); token = m[1]; if (account) push(); continue; }
    m = line.match(/^CF_ACCOUNT_ID\s*[=:]\s*([0-9a-f]{32})/i);
    if (m) { if (account) push(); account = m[1]; if (token) push(); continue; }
    m = line.match(/^([0-9a-f]{32}):(\S+)$/i);
    if (m) { accounts.push({ account: m[1], token: m[2] }); }
  }
  push();
  return accounts;
}

// Freesound: one search per world, only sounds a commercial game may use (CC0 or CC-BY; no
// NonCommercial, no Sampling+), long enough to loop. The key is the user's own Freesound API key
// (https://freesound.org/apiv2/apply), saved like the Cloudflare keys.
const FREESOUND = "https://freesound.org/apiv2";
const LICENCE_OK = /publicdomain\/zero|licenses\/by\/\d/;
export const AMBIENT_TARGETS = {
  forest: { title: "جنگل", query: "forest birds ambience" },
  stream: { title: "جوی آب (آبراه‌ها)", query: "gentle stream water ambience" },
  sky: { title: "آسمان، کوهستان، سرزمین وارونه", query: "wind ambience mountain" },
  cave: { title: "غار بلورین", query: "cave water drips ambience" },
  waves: { title: "ساحل مرجانی", query: "ocean waves beach gentle" },
  desert: { title: "بیابان طلایی", query: "desert wind ambience" },
  factory: { title: "کارخانهٔ ساعت", query: "clockwork ticking machinery ambience" },
  night: { title: "قلعهٔ سایه (شب)", query: "crickets night ambience" },
  rain: { title: "مرحله‌های بارانی", query: "steady rain ambience" },
};

export function createTools({ app, getConfig, saveConfig, say, makeLoop }) {
  const manifestFile = path.join(app, "tools/art/manifest.json");
  const picksFile = path.join(app, "tools/audio/picks.json");
  const sourcesFile = path.join(app, "docs/audio/sound_sources.json");
  let job = null;   // { kind, started, lines }

  const accounts = () => getConfig().cloudflare || [];
  const python = () => getConfig().python || (process.platform === "win32" ? "python" : "python3");

  function run(kind, args, env = {}) {
    return new Promise((resolve) => {
      say("info", `▶ ${kind}: ${python()} ${args.join(" ")}`);
      const child = spawn(python(), args, { cwd: app, env: { ...process.env, PYTHONIOENCODING: "utf-8", ...env } });
      const out = [];
      const pipe = (stream, level) => {
        let rest = "";
        stream.on("data", (d) => {
          const parts = (rest + d.toString("utf8")).split(/\r?\n/);
          rest = parts.pop();
          for (const line of parts) {
            if (!line.trim()) continue;
            out.push(line);
            say(/FAILED|fail|Error|Traceback/.test(line) ? "warn" : level, line.slice(0, 400));
          }
        });
      };
      pipe(child.stdout, "info");
      pipe(child.stderr, "info");
      child.on("error", (e) => {
        say("err", `${python()} اجرا نشد: ${e.message} — پایتون نصب است؟ (مسیرش را در همین تب بدهید)`);
        resolve({ ok: false, lines: out });
      });
      child.on("close", (code) => resolve({ ok: code === 0, lines: out }));
    });
  }

  async function exclusive(kind, work) {
    if (job) throw new Error(`کار «${job.kind}» هنوز در جریان است`);
    job = { kind, started: new Date().toISOString() };
    try {
      return await work();
    } finally {
      job = null;
    }
  }

  async function freesound(pathAndQuery) {
    const key = getConfig().freesound;
    if (!key) throw new Error("اول کلید API فری‌ساند را در همین تب وارد کنید");
    const res = await fetch(`${FREESOUND}${pathAndQuery}`, { headers: { Authorization: `Token ${key}` } });
    if (res.status === 401 || res.status === 403) throw new Error("فری‌ساند کلید را نپذیرفت — کلید API درست است؟");
    if (!res.ok) throw new Error(`فری‌ساند: HTTP ${res.status}`);
    return res.json();
  }

  return {
    status() {
      return {
        job,
        freesound: getConfig().freesound ? `${getConfig().freesound.slice(0, 4)}…${getConfig().freesound.slice(-3)}` : "",
        python: python(),
        accounts: accounts().map((a) => ({ account: `${a.account.slice(0, 6)}…`, token: `${a.token.slice(0, 9)}…${a.token.slice(-4)}` })),
      };
    },

    /** Replaces the saved Cloudflare accounts with the ones in the pasted text. */
    setKeys(text) {
      const parsed = parseCloudflare(text);
      if (!parsed.length) throw new Error("هیچ جفت CF_API_TOKEN / CF_ACCOUNT_ID پیدا نشد");
      saveConfig({ cloudflare: parsed });
      say("ok", `${parsed.length} حساب Cloudflare ذخیره شد (فقط در voice-studio.config.json)`);
      return this.status();
    },

    clearKeys() {
      saveConfig({ cloudflare: [] });
      say("ok", "کلیدهای Cloudflare پاک شد");
      return this.status();
    },

    setFreesoundKey(value) {
      saveConfig({ freesound: String(value || "").trim() });
      say("ok", value ? "کلید فری‌ساند ذخیره شد (فقط در voice-studio.config.json)" : "کلید فری‌ساند پاک شد");
      return this.status();
    },

    /** Each ambient file of the game, what it is for, and where its current sound came from. */
    ambientTargets() {
      const sources = fs.existsSync(sourcesFile) ? JSON.parse(fs.readFileSync(sourcesFile, "utf8")).files || {} : {};
      return Object.entries(AMBIENT_TARGETS).map(([name, t]) => ({
        name, ...t, file: `assets/audio/ambient/${name}.ogg`,
        exists: fs.existsSync(path.join(app, "assets/audio/ambient", name + ".ogg")),
        source: sources[`ambient/${name}`] || null,
      }));
    },

    /** Freesound candidates: free licences only, 20 s to 10 min, best rated first. */
    async searchFreesound(query) {
      const q = String(query || "").trim();
      if (!q) throw new Error("چیزی برای جست‌وجو نوشته نشده");
      const filter = 'duration:[20 TO 600] license:("Creative Commons 0" OR "Attribution")';
      const fields = "id,name,username,license,duration,previews,url,avg_rating,num_ratings,description";
      const data = await freesound(`/search/text/?query=${encodeURIComponent(q)}&filter=${encodeURIComponent(filter)}`
        + `&fields=${fields}&sort=rating_desc&page_size=20`);
      return (data.results || []).filter((r) => LICENCE_OK.test(r.license)).map((r) => ({
        id: r.id, name: r.name, author: r.username, license: r.license, duration: Math.round(r.duration),
        page: r.url, rating: r.avg_rating, ratings: r.num_ratings,
        preview: r.previews?.["preview-hq-ogg"] || r.previews?.["preview-hq-mp3"],
        description: String(r.description || "").replace(/<[^>]+>/g, "").slice(0, 200),
      }));
    },

    /**
     * Makes one Freesound sound the loop of an ambient file: its high-quality preview is fetched,
     * turned into a seamless 24 s loop (end cross-faded into the start, −24 LUFS, Ogg) and written
     * over assets/audio/ambient/<name>.ogg; source, licence and author go to docs/audio/sound_sources.json.
     */
    async useFreesound(name, id, start = 0) {
      if (!AMBIENT_TARGETS[name]) throw new Error(`صدای محیط «${name}» نداریم`);
      const sound = await freesound(`/sounds/${Number(id)}/?fields=id,name,username,license,url,previews,duration`);
      if (!LICENCE_OK.test(sound.license)) throw new Error("مجوز این صدا برای بازی تجاری آزاد نیست");
      const url = sound.previews?.["preview-hq-ogg"] || sound.previews?.["preview-hq-mp3"];
      const audio = Buffer.from(await (await fetch(url)).arrayBuffer());
      const temp = fs.mkdtempSync(path.join(os.tmpdir(), "pilo-fs-"));
      try {
        const input = path.join(temp, "in" + path.extname(new URL(url).pathname));
        const cut = path.join(temp, "cut.ogg");
        const output = path.join(temp, "out.ogg");
        fs.writeFileSync(input, audio);
        // the part to keep starts at `start` seconds (some recordings begin with handling noise)
        const trimmed = Number(start) > 0
          ? await new Promise((resolve) => spawn("ffmpeg", ["-y", "-loglevel", "error", "-ss", String(Number(start)), "-i", input, cut])
            .on("close", (code) => resolve(code === 0)))
          : false;
        const done = await makeLoop(trimmed ? cut : input, output, 24);
        if (!done.ok) throw new Error(`ffmpeg: ${done.error || "؟"}`);
        fs.copyFileSync(output, path.join(app, "assets/audio/ambient", name + ".ogg"));
      } finally {
        fs.rmSync(temp, { recursive: true, force: true });
      }
      const data = fs.existsSync(sourcesFile) ? JSON.parse(fs.readFileSync(sourcesFile, "utf8"))
        : { note: "Real recordings with source and licence. Sounds not listed here are made by tools/audio.py.", files: {} };
      data.files[`ambient/${name}`] = {
        file: `assets/audio/ambient/${name}.ogg`, source: sound.url, license: licenceName(sound.license),
        author: sound.username, title: sound.name, fetched: new Date().toISOString().slice(0, 10),
      };
      fs.writeFileSync(sourcesFile, JSON.stringify(data, null, 1) + "\n", "utf8");
      say("ok", `صدای محیط «${AMBIENT_TARGETS[name].title}» از فری‌ساند گذاشته شد: «${sound.name}» از ${sound.username} (${licenceName(sound.license)})`);
      return this.ambientTargets();
    },

    setPython(value) {
      saveConfig({ python: String(value || "").trim() });
      return this.status();
    },

    /** Every picture job in the art manifest, with whether its file exists. */
    art() {
      const manifest = JSON.parse(fs.readFileSync(manifestFile, "utf8"));
      return manifest.jobs.map((j) => ({
        id: j.id,
        prompt: j.prompt,
        post: j.post || "",
        made: fs.existsSync(path.join(app, "assets/art", j.id + ".png")),
      }));
    },

    /** Makes the chosen pictures again (the old one stays until the new one is made), then post-processes them. */
    remakeArt(ids) {
      const clean = (ids || []).filter((id) => /^[\w-]+$/.test(id));
      if (!clean.length) throw new Error("هیچ تصویری انتخاب نشده");
      if (!accounts().length) throw new Error("اول کلیدهای Cloudflare را در همین تب وارد کنید");
      const CF_KEYS = accounts().map((a) => `${a.account}:${a.token}`).join(",");
      return exclusive("تصویر", async () => {
        const made = await run("تصویر", ["tools/art/cf_generate.py", "--redo", "--only", clean.join(",")], { CF_KEYS });
        const done = made.lines.filter((l) => l.startsWith("made ")).map((l) => l.split(/\s+/)[1]);
        if (!done.length) {
          say("warn", "تصویری ساخته نشد (سهمیهٔ روزانه، یا متن را فیلتر رد کرد) — خط‌های بالا را ببینید");
          return { made: [] };
        }
        const post = await run("پردازش", ["tools/art/postprocess.py", ...done]);
        say(post.ok ? "ok" : "warn", post.ok ? `${done.length} تصویر ساخته و در assets/art گذاشته شد`
          : "پردازش کامل نشد — postprocess.py به Pillow، numpy و rembg نیاز دارد (pip install pillow numpy rembg opencv-python)");
        return { made: done };
      });
    },

    /** The hand-picked real recordings and whether each is already in the game. */
    ambient() {
      const picks = JSON.parse(fs.readFileSync(picksFile, "utf8")).picks;
      const sources = fs.existsSync(sourcesFile) ? JSON.parse(fs.readFileSync(sourcesFile, "utf8")).files || {} : {};
      return Object.entries(picks).map(([key, p]) => ({
        key,
        file: p.file,
        page: "https://commons.wikimedia.org/wiki/" + encodeURIComponent(p.file.replace(/ /g, "_")),
        applied: Boolean(sources[key]),
        license: sources[key]?.license || "",
      }));
    },

    /** Downloads the chosen picks from Commons and writes the loops over assets/audio/ambient. */
    fetchAmbient(keys, force) {
      const names = (keys || []).filter((k) => /^[\w/-]+$/.test(k));
      return exclusive("صدای محیط", async () => {
        const result = await run("صدای محیط", ["tools/audio/fetch_ambience.py", ...names, ...(force ? ["--force"] : [])]);
        say(result.ok ? "ok" : "warn", result.ok ? "صدای محیط آماده شد — در تب صداها گوش کنید"
          : "بعضی صداها دانلود نشدند — خط‌های بالا را ببینید (fetch_ambience.py به numpy نیاز دارد)");
        return { ok: result.ok };
      });
    },
  };
}
