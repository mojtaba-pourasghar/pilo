import React, { useCallback, useEffect, useMemo, useState } from "react";

// صدای حیوان‌ها و وسایل.
//
// The TTS service cannot make a cow moo, so these are real recordings someone finds and drops
// here. The server cleans each one with ffmpeg (trim, a few seconds, even loudness, MP3) and
// writes it over the file the app already plays in assets/audio/sfx. Nothing leaves the
// computer; the next `flutter run` or build carries the new sound.

const fa = (n) => Number(n || 0).toLocaleString("fa-IR");

const SEARCH = {
  lion: "lion roar", cow: "cow moo", dog: "dog bark", cat: "cat meow", rabbit: "rabbit",
  bird: "bird chirp", sheep: "sheep baa", horse: "horse neigh", duck: "duck quack",
  frog: "frog croak", elephant: "elephant trumpet", rooster: "rooster crow",
  doorbell: "doorbell", clock: "clock ticking", phone: "phone ringing", vacuum: "vacuum cleaner",
  kettle: "kettle whistle", washer: "washing machine", tap: "water tap running", door: "door knock",
  rain: "rain", thunder: "thunder", wind: "wind", sea: "sea waves", river: "river stream",
  fire: "campfire crackling", waterfall: "waterfall", drum: "drum", piano: "piano",
  guitar: "acoustic guitar", violin: "violin", flute: "flute", bell: "small bell",
  tambourine: "frame drum daf", hammer: "hammer nail", saw: "hand saw", ambulance: "ambulance siren",
  firetruck: "fire truck siren", police: "police siren", scissors: "scissors cutting",
  typing: "keyboard typing", rocket: "rocket launch", robot: "robot", spaceship: "spaceship",
  satellite: "satellite beep", laser: "laser",
};

async function json(res) {
  const text = await res.text();
  const body = text ? JSON.parse(text) : {};
  if (!res.ok) throw new Error(body.error || `HTTP ${res.status}`);
  return body;
}

export default function SfxPanel({ ffmpeg }) {
  const [data, setData] = useState(null);
  const [error, setError] = useState("");
  const [category, setCategory] = useState("all");
  const [onlyFake, setOnlyFake] = useState(false);
  const [busy, setBusy] = useState("");             // the id being written
  const [maxSeconds, setMaxSeconds] = useState(6);
  const [meta, setMeta] = useState({});              // id → { source, license } being typed

  const load = useCallback(async () => {
    try {
      setData(await json(await fetch("/api/sfx")));
      setError("");
    } catch (err) { setError(err.message); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const shown = useMemo(() => (data?.sounds || []).filter((s) =>
    (category === "all" || s.category === category) && (!onlyFake || !s.real)), [data, category, onlyFake]);

  const realCount = (data?.sounds || []).filter((s) => s.real).length;

  const replace = async (sound, file) => {
    if (!file) return;
    setBusy(sound.id);
    try {
      const m = meta[sound.id] || {};
      const q = new URLSearchParams({
        name: file.name, max: String(maxSeconds),
        source: m.source ?? sound.source?.source ?? "", license: m.license ?? sound.source?.license ?? "",
      });
      await json(await fetch(`/api/sfx/${sound.id}?${q}`, {
        method: "POST", headers: { "Content-Type": "application/octet-stream" }, body: file,
      }));
      await load();
    } catch (err) { setError(`${sound.title}: ${err.message}`); }
    setBusy("");
  };

  const saveMeta = async (sound) => {
    try {
      await json(await fetch(`/api/sfx/${sound.id}/meta`, {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify(meta[sound.id] || {}),
      }));
      setMeta((old) => { const next = { ...old }; delete next[sound.id]; return next; });
      await load();
    } catch (err) { setError(err.message); }
  };

  if (!data) return <div className="card">{error ? <div className="err">{error}</div> : "در حال خواندن…"}</div>;

  return (
    <div className="card">
      <h2>
        🐄 صدای حیوان‌ها و وسایل
        <span className="hint">
          {fa(realCount)} از {fa(data.sounds.length)} صدا واقعی است — بقیه هنوز سنتزیِ نسخه‌ی قبلی‌اند
        </span>
      </h2>

      {!ffmpeg && (
        <div className="err">
          ffmpeg پیدا نشد. بدون آن فایل‌ها تمیز و یکسان نمی‌شوند و جایگزینی کار نمی‌کند — راهنمای نصب در README.
        </div>
      )}
      {error && <div className="err">{error}</div>}

      <p className="note">
        فایل صوتیِ واقعی (mp3، wav، ogg، m4a…) را روی ردیفِ هر صدا بینداز یا «انتخابِ فایل» را بزن.
        فایل بریده (حداکثر چند ثانیه)، هم‌بلندی و MP3 می‌شود و <b>مستقیم جای همان فایلِ داخلِ پروژه</b>
        (<code>assets/audio/sfx/…</code>) می‌نشیند. هیچ چیزی جایی آپلود نمی‌شود؛ بعد از کار
        <code> flutter run</code> بزن و کامیت کن.
      </p>
      <p className="note">
        منبعِ پیشنهادی: Freesound (فیلترِ CC0)، Pixabay Sound Effects، BigSoundBank — هر سه رایگان‌اند.
        منبع و مجوز را در ردیف بنویس تا در <code>{data.sourcesFile}</code> بماند (برای انتشار در
        بازار لازم می‌شود).
      </p>

      <div className="row" style={{ margin: "12px 0" }}>
        <button className={category === "all" ? "chip sel" : "chip"} onClick={() => setCategory("all")}>همه</button>
        {data.categories.map((c) => (
          <button key={c.id} className={category === c.id ? "chip sel" : "chip"}
                  onClick={() => setCategory(c.id)}>{c.title}</button>
        ))}
        <label className="check" style={{ marginTop: 0 }}>
          <input type="checkbox" checked={onlyFake} onChange={(e) => setOnlyFake(e.target.checked)} />
          فقط سنتزی‌ها
        </label>
        <label className="check" style={{ marginTop: 0 }}>
          حداکثر طول (ثانیه)
          <input type="number" min="1" max="15" value={maxSeconds} style={{ width: 64 }}
                 onChange={(e) => setMaxSeconds(Number(e.target.value) || 6)} />
        </label>
      </div>

      <div className="files">
        {shown.map((s) => {
          const m = meta[s.id] || {};
          const source = m.source ?? s.source?.source ?? "";
          const license = m.license ?? s.source?.license ?? "";
          return (
            <div key={s.id} className="file sfx"
                 onDragOver={(e) => e.preventDefault()}
                 onDrop={(e) => { e.preventDefault(); replace(s, e.dataTransfer.files[0]); }}>
              <div>
                <b>{s.title}</b>
                <div className="key">{s.file}</div>
                <span className={s.real ? "tag done" : "tag"}>{s.real ? "واقعی" : "سنتزی"}</span>
                {" "}<span className="tag">{s.categoryTitle}</span>
              </div>
              <div>
                {s.exists
                  ? <audio controls preload="none" src={`/api/sfx/${s.id}/audio?t=${s.stamp}`} />
                  : <span className="note">فایل ندارد</span>}
                <div className="row" style={{ marginTop: 6 }}>
                  <input type="text" placeholder="منبع (لینک)" value={source} style={{ flex: 2, minWidth: 140 }}
                         onChange={(e) => setMeta({ ...meta, [s.id]: { ...m, source: e.target.value } })} />
                  <input type="text" placeholder="مجوز (CC0، …)" value={license} style={{ flex: 1, minWidth: 90 }}
                         onChange={(e) => setMeta({ ...meta, [s.id]: { ...m, license: e.target.value } })} />
                  {s.real && meta[s.id] && <button className="ghost" onClick={() => saveMeta(s)}>ذخیره</button>}
                </div>
                <a className="note" target="_blank" rel="noreferrer"
                   href={`https://freesound.org/search/?q=${encodeURIComponent(SEARCH[s.id] || s.id)}&f=license:%22Creative+Commons+0%22`}>
                  جست‌وجو در Freesound: {SEARCH[s.id] || s.id}
                </a>
              </div>
              <div>
                <label className={ffmpeg && !busy ? "pick" : "pick off"}>
                  {busy === s.id ? "در حال ساخت…" : "انتخابِ فایل"}
                  <input type="file" accept="audio/*,video/mp4" hidden disabled={!ffmpeg || Boolean(busy)}
                         onChange={(e) => { replace(s, e.target.files[0]); e.target.value = ""; }} />
                </label>
              </div>
            </div>
          );
        })}
        {!shown.length && <div className="empty">چیزی نمانده 🎉</div>}
      </div>
    </div>
  );
}
