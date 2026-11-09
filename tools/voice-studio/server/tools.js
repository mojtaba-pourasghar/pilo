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
import { spawn } from "node:child_process";

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

export function createTools({ app, getConfig, saveConfig, say }) {
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

  return {
    status() {
      return {
        job,
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
