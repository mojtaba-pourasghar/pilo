import React, { useCallback, useEffect, useMemo, useState } from "react";

// تب «ابزارها»: کلیدهای Cloudflare، ساخت دوبارهٔ تصویرها، صدای محیط واقعی (server/tools.js).
//
// Same layout as the other tabs (cards, chips). The keys are saved only in
// voice-studio.config.json on this computer and are never shown back in full. The jobs run the
// project's own Python tools; their progress appears in the log at the bottom of the page.

const fa = (n) => Number(n || 0).toLocaleString("fa-IR");

async function json(res) {
  const text = await res.text();
  const body = text ? JSON.parse(text) : {};
  if (!res.ok) throw new Error(body.error || `HTTP ${res.status}`);
  return body;
}

const post = (url, body) => fetch(url, {
  method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body),
}).then(json);

export default function ToolsPanel() {
  const [status, setStatus] = useState(null);
  const [art, setArt] = useState([]);
  const [ambient, setAmbient] = useState([]);
  const [keysText, setKeysText] = useState("");
  const [python, setPython] = useState("");
  const [filter, setFilter] = useState("");
  const [picked, setPicked] = useState(new Set());
  const [error, setError] = useState("");
  const [note, setNote] = useState("");

  const load = useCallback(async () => {
    try {
      const [s, a, m] = await Promise.all([
        fetch("/api/tools").then(json), fetch("/api/tools/art").then(json), fetch("/api/tools/ambient").then(json)]);
      setStatus(s);
      setArt(a);
      setAmbient(m);
      setPython((p) => p || s.python);
      setError("");
    } catch (err) {
      setError(err.message);
    }
  }, []);

  useEffect(() => { load(); }, [load]);
  // while a job runs, look again every few seconds so the lists catch up when it ends
  useEffect(() => {
    if (!status?.job) return undefined;
    const t = setInterval(load, 4000);
    return () => clearInterval(t);
  }, [status?.job, load]);

  const act = async (work, done) => {
    try {
      setError("");
      const s = await work();
      if (s && s.accounts) setStatus(s);
      if (done) setNote(done);
      load();
    } catch (err) {
      setError(err.message);
    }
  };

  const shown = useMemo(() => {
    const q = filter.trim().toLowerCase();
    return art.filter((j) => !q || j.id.includes(q) || j.prompt.toLowerCase().includes(q)).slice(0, 120);
  }, [art, filter]);

  const toggle = (id) => setPicked((old) => {
    const next = new Set(old);
    if (next.has(id)) next.delete(id); else next.add(id);
    return next;
  });

  if (!status) return <div className="card">{error ? <div className="err">{error}</div> : "…"}</div>;
  const busy = Boolean(status.job);

  return (<>
    {error && <div className="err">{error}</div>}
    {note && <div className="note">{note}</div>}
    {busy && <div className="note">در حال کار: «{status.job.kind}» — پیشرفت در گزارش پایین صفحه.</div>}

    <div className="card">
      <h3>کلیدهای Cloudflare (ساخت تصویر)</h3>
      <p className="note">
        جفت‌های <code>CF_API_TOKEN=…</code> و <code>CF_ACCOUNT_ID=…</code> را همان‌طور که هست اینجا بچسبانید. فقط در
        فایل <code>voice-studio.config.json</code> روی همین رایانه ذخیره می‌شوند و هرگز به گیت نمی‌روند. وقتی سهمیهٔ روزانهٔ
        یک حساب تمام شود، حساب بعدی به کار می‌رود.
      </p>
      <div className="row">
        <span>ذخیره‌شده: {fa(status.accounts.length)} حساب</span>
        {status.accounts.map((a) => <code key={a.token}>{a.token}</code>)}
      </div>
      <textarea rows={6} dir="ltr" style={{ width: "100%" }} value={keysText}
                placeholder={"CF_API_TOKEN=cfut_…\nCF_ACCOUNT_ID=…"}
                onChange={(e) => setKeysText(e.target.value)} />
      <div className="row">
        <button className="go" disabled={!keysText.trim()}
                onClick={() => act(() => post("/api/tools/keys", { text: keysText }), "کلیدها ذخیره شد").then(() => setKeysText(""))}>
          ذخیرهٔ کلیدها
        </button>
        <button className="ghost" disabled={!status.accounts.length}
                onClick={() => act(() => post("/api/tools/keys", { text: "" }), "کلیدها پاک شد")}>
          پاک کردن
        </button>
      </div>
    </div>

    <div className="card">
      <h3>پایتون</h3>
      <p className="note">
        ابزارهای تصویر و صدا با پایتونِ همین رایانه اجرا می‌شوند. یک بار بسته‌ها را نصب کنید:
        <code dir="ltr"> pip install pillow numpy rembg opencv-python</code>
      </p>
      <div className="row">
        <input dir="ltr" value={python} onChange={(e) => setPython(e.target.value)} style={{ width: 280 }} />
        <button className="ghost" onClick={() => act(() => post("/api/tools/python", { python }), "مسیر پایتون ذخیره شد")}>
          ذخیره
        </button>
      </div>
    </div>

    <div className="card">
      <h3>تصویرها ({fa(art.length)})</h3>
      <p className="note">
        تصویرهای بازی (شخصیت‌ها، دشمن‌ها، محیط‌ها، اشیا) با متن درخواستِ <code>tools/art/manifest.json</code> ساخته
        می‌شوند. تصویری را که نمی‌پسندید انتخاب کنید و دوباره بسازید؛ تصویر قبلی تا ساخته شدن تصویر تازه می‌ماند.
      </p>
      <div className="row">
        <input placeholder="جست‌وجو (مثلاً kian یا bat)" value={filter} onChange={(e) => setFilter(e.target.value)} />
        <span>انتخاب‌شده: {fa(picked.size)}</span>
        <button className="go" disabled={busy || !picked.size || !status.accounts.length}
                onClick={() => act(() => post("/api/tools/art", { ids: [...picked] }), "ساخت شروع شد").then(() => setPicked(new Set()))}>
          ساخت دوباره
        </button>
      </div>
      <div className="grid">
        {shown.map((j) => (
          <label key={j.id} className={picked.has(j.id) ? "file sel" : "file"} title={j.prompt}>
            <input type="checkbox" checked={picked.has(j.id)} onChange={() => toggle(j.id)} />
            {j.made
              ? <img src={`/api/art/${j.id}?v=${status.job ? Date.now() : ""}`} alt="" loading="lazy"
                     style={{ width: 72, height: 72, objectFit: "contain", background: "#eee" }} />
              : <span className="empty">—</span>}
            <code>{j.id}</code>
          </label>
        ))}
      </div>
    </div>

    <div className="card">
      <h3>صدای محیط واقعی</h3>
      <p className="note">
        ضبط‌های واقعی انتخاب‌شده از Wikimedia Commons (<code>tools/audio/picks.json</code>) دانلود و به حلقهٔ بی‌درز تبدیل
        می‌شوند و جای صدای ساختگی را می‌گیرند. منبع و مجوز در <code>docs/audio/sound_sources.json</code> ثبت می‌شود.
        بعد در تب «صداهای بازی و محیط» گوش کنید.
      </p>
      <table>
        <tbody>
          {ambient.map((a) => (
            <tr key={a.key}>
              <td><code>{a.key}</code></td>
              <td><a href={a.page} target="_blank" rel="noreferrer">{a.file.replace("File:", "")}</a></td>
              <td>{a.applied ? `✓ ${a.license}` : "ساختگی"}</td>
              <td>
                <button className="ghost" disabled={busy}
                        onClick={() => act(() => post("/api/tools/ambient", { keys: [a.key], force: a.applied }), "دانلود شروع شد")}>
                  {a.applied ? "دوباره" : "دانلود"}
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      <div className="row">
        <button className="go" disabled={busy || ambient.every((a) => a.applied)}
                onClick={() => act(() => post("/api/tools/ambient", { keys: [] }), "دانلود همه شروع شد")}>
          دانلود همهٔ باقی‌مانده‌ها ({fa(ambient.filter((a) => !a.applied).length)})
        </button>
      </div>
    </div>
  </>);
}
