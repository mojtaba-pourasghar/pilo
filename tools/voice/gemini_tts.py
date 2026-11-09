#!/usr/bin/env python3
"""Narration and character lines with Gemini's text-to-speech (Persian), written to
assets/audio/voice/<id>.ogg. The key comes from the environment (GEMINI_API_KEYS).

    python3 tools/voice/gemini_tts.py data/story/intro.json     # every panel of a story file
    python3 tools/voice/gemini_tts.py --check data/story/intro.json   # transcribe back and compare
    python3 tools/voice/gemini_tts.py --verify [--redo-below 0.8]
        # transcribes every clip made here back to text and scores it against the line
        # (docs/voice/tts_check.json); with --redo-below, weaker clips are made again
    python3 tools/voice/gemini_tts.py --lines [--kinds intro,outro,...] [--limit N]
        # every line in data/voice/voice_lines.json, each character with its own voice and
        # acting note (CHARACTERS in tools/voice/build_voice_lines.py)

GEMINI_API_KEYS may hold several keys separated by commas: when one runs out of daily quota the
next one is used, and when all have run out the newer model falls back to the older one.

Existing files are kept; delete one to redo it. Every clip made here is listed in
docs/voice/tts_generated.json (like the voice studio does), and a clip that is not on that list
is a human recording and is never replaced.
"""
import base64, json, os, subprocess, sys, tempfile, time, urllib.request, urllib.error

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
# The 3.8 model takes a short bracket tag before the line ("[cheerful, bouncy] ..."); a long
# English note would be read aloud. The 2.5 model (10 lines a day on the free tier) takes the
# long acting note. The newer model goes first.
TTS_MODELS = ["gemini-3.8-flash-tts", "gemini-2.5-flash-preview-tts", "gemini-3.8-flash-lite-tts"]
TAKES_STYLE = {"gemini-2.5-flash-preview-tts"}
TTS_MODEL = TTS_MODELS[0]
CHECK_MODEL = "gemini-flash-lite-latest"


class OutOfQuota(RuntimeError):
    pass


_spent = set()   # (model, key) pairs that hit their daily quota


def _daily(body):
    """Is this 429 the daily quota (not the per-minute one)?"""
    try:
        details = json.loads(body)["error"].get("details", [])
    except (ValueError, KeyError):
        return False
    ids = [v.get("quotaId", "") for d in details for v in d.get("violations", [])]
    return any("PerDay" in i for i in ids)


def _call(model, body):
    keys = [k for k in os.environ["GEMINI_API_KEYS"].split(",") if k]
    for key in keys:
        if (model, key) in _spent:
            continue
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
        for attempt in range(4):
            req = urllib.request.Request(url, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
            try:
                with urllib.request.urlopen(req, timeout=400) as r:
                    return json.load(r)
            except urllib.error.HTTPError as e:
                msg = e.read()
                if e.code == 429 and _daily(msg):
                    _spent.add((model, key))
                    break
                if e.code in (429, 500, 503):
                    time.sleep(15 * (attempt + 1))
                    continue
                if e.code in (400, 401, 403) and b"API key" in msg:
                    _spent.add((model, key))
                    break
                raise RuntimeError(f"HTTP {e.code} {msg[:200]!r}")
            except (urllib.error.URLError, TimeoutError) as e:
                time.sleep(10)
                continue
        else:
            raise RuntimeError("gave up after retries")
    raise OutOfQuota(model)


def speak(text, voice, style, out, tag=""):
    """Returns the model that spoke the line."""
    for model in TTS_MODELS:
        prompt = f"{style}\n{text}" if model in TAKES_STYLE else (f"[{tag}] {text}" if tag else text)
        body = {"contents": [{"parts": [{"text": prompt}]}],
                "generationConfig": {"responseModalities": ["AUDIO"],
                                     "speechConfig": {"voiceConfig": {"prebuiltVoiceConfig": {"voiceName": voice}}}}}
        try:
            data = _call(model, body)
            break
        except OutOfQuota:
            continue
    else:
        raise OutOfQuota("every key and model")
    part = data["candidates"][0]["content"]["parts"][0]["inlineData"]
    raw = "-f s16le -ar 24000 -ac 1".split() if "L16" in part.get("mimeType", "") or "pcm" in part.get("mimeType", "") else []
    with tempfile.NamedTemporaryFile(suffix=".pcm", delete=False) as f:
        f.write(base64.b64decode(part["data"]))
        pcm = f.name
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", *raw, "-i", pcm,
                    "-af", "silenceremove=start_periods=1:start_threshold=-50dB,areverse,silenceremove=start_periods=1:start_threshold=-50dB,areverse,loudnorm=I=-16",
                    "-c:a", "libvorbis", "-q:a", "5", out], check=True)
    os.unlink(pcm)
    return model


def transcribe(path):
    audio = base64.b64encode(open(path, "rb").read()).decode()
    body = {"contents": [{"parts": [{"inline_data": {"mime_type": "audio/ogg", "data": audio}},
                                    {"text": "Transcribe this Persian speech exactly, in Persian script. Output only the words."}]}]}
    data = _call(CHECK_MODEL, body)
    return data["candidates"][0]["content"]["parts"][0]["text"].strip()


REGISTRY = os.path.join(ROOT, "docs", "voice", "tts_generated.json")


def _registry():
    try:
        return json.load(open(REGISTRY, encoding="utf-8"))
    except (OSError, ValueError):
        return {"note": "clips made with the TTS service — temporary until a voice actor records them", "files": {}}


def _mark(key, voice, model=TTS_MODEL):
    data = _registry()
    data["files"][key] = {"service": "gemini", "model": model, "voice": voice,
                          "at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
    data["files"] = dict(sorted(data["files"].items()))
    os.makedirs(os.path.dirname(REGISTRY), exist_ok=True)
    json.dump(data, open(REGISTRY, "w", encoding="utf-8"), ensure_ascii=False, indent=2)


def duration(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path],
                         capture_output=True, text=True).stdout.strip()
    return float(out or 0)


def _too_long(path, text):
    """A clip far longer than its words (the acting note read aloud, or a long pause)."""
    return duration(path) > len(text.split()) * 0.75 + 3.0


def _exists(folder, line_id):
    return any(os.path.exists(os.path.join(folder, line_id + ext)) for ext in (".mp3", ".ogg", ".wav"))


def lines(kinds, limit):
    """Voices data/voice/voice_lines.json. A line that already has a file (a recording, or a clip
    made before) is skipped, so a human recording is never replaced."""
    data = json.load(open(os.path.join(ROOT, "data", "voice", "voice_lines.json"), encoding="utf-8"))
    characters = data["characters"]
    folder = os.path.join(ROOT, "assets", "audio", "voice")
    os.makedirs(folder, exist_ok=True)
    order = ["tutorial", "chapter", "intro", "outro", "rescue", "app", "sign"]
    todo = [l for l in data["lines"] if (not kinds or l["kind"] in kinds) and not _exists(folder, l["id"])]
    todo.sort(key=lambda l: order.index(l["kind"]) if l["kind"] in order else len(order))
    made = 0
    for line in todo[:limit or None]:
        who = characters.get(line["who"], characters["pilo"])
        style = f"Read this aloud in Persian (Farsi), in the voice of {who['style']}. Say only the line:"
        out = os.path.join(folder, line["id"] + ".ogg")
        text = line.get("spoken", line["text"])
        try:
            model = speak(text, who["voice"], style, out, who.get("tag", ""))
            if _too_long(out, text):
                model = speak(text, who["voice"], style, out, who.get("tag", ""))
                if _too_long(out, text):
                    os.unlink(out)
                    print("long ", line["id"], "(left for later)")
                    continue
        except OutOfQuota:
            print("out of quota on every key; %d made, %d left" % (made, len(todo) - made))
            return
        except Exception as e:      # one bad line must not stop the batch
            print("fail ", line["id"], e)
            continue
        _mark(line["id"], who["voice"], model)
        made += 1
        print("made ", line["id"], line["who"], model, flush=True)
    print("done; %d made" % made)


def _plain(text):
    import re, unicodedata
    text = text.replace("\u200c", " ").replace("ي", "ی").replace("ك", "ک").replace("ۀ", "ه").replace("هٔ", "ه")
    text = "".join(c for c in unicodedata.normalize("NFKD", text) if not unicodedata.combining(c))
    text = text.translate(str.maketrans("۰۱۲۳۴۵۶۷۸۹", "0123456789"))
    return re.sub(r"[^\w]+", "", text)


def score(text, heard):
    import difflib
    return difflib.SequenceMatcher(None, _plain(text), _plain(heard)).ratio()


def verify(redo_below):
    data = json.load(open(os.path.join(ROOT, "data", "voice", "voice_lines.json"), encoding="utf-8"))
    characters = data["characters"]
    made_here = _registry()["files"]
    folder = os.path.join(ROOT, "assets", "audio", "voice")
    report_path = os.path.join(ROOT, "docs", "voice", "tts_check.json")
    try:
        report = json.load(open(report_path, encoding="utf-8"))
    except (OSError, ValueError):
        report = {}
    for line in data["lines"]:
        out = os.path.join(folder, line["id"] + ".ogg")
        if line["id"] not in made_here or not os.path.exists(out):
            continue        # not made by the TTS service (a recording), or not made yet
        if line["id"] in report and report[line["id"]]["score"] >= (redo_below or 0):
            continue
        text = line.get("spoken", line["text"])
        best = None
        for attempt in range(3):
            try:
                heard = transcribe(out)
            except OutOfQuota:
                print("out of quota")
                return
            s = round(score(line["text"], heard), 3)
            if best is None or s > best[0]:
                best = (s, heard, open(out, "rb").read())
            if not redo_below or s >= redo_below:
                break
            who = characters.get(line["who"], characters["pilo"])
            style = f"Read this aloud in Persian (Farsi), in the voice of {who['style']}. Say only the line:"
            try:
                model = speak(text, who["voice"], style, out, who.get("tag", ""))
                _mark(line["id"], who["voice"], model)
            except OutOfQuota:
                break
        open(out, "wb").write(best[2])      # keep the clearest take
        report[line["id"]] = {"score": best[0], "heard": best[1]}
        print("%.2f %s" % (best[0], line["id"]), flush=True)
        json.dump(dict(sorted(report.items())), open(report_path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)


def main():
    if "--verify" in sys.argv:
        args = sys.argv[1:]
        verify(float(args[args.index("--redo-below") + 1]) if "--redo-below" in args else 0.0)
        return
    if "--lines" in sys.argv:
        args = sys.argv[1:]
        kinds = args[args.index("--kinds") + 1].split(",") if "--kinds" in args else []
        limit = int(args[args.index("--limit") + 1]) if "--limit" in args else 0
        lines(kinds, limit)
        return
    check = "--check" in sys.argv
    path = [a for a in sys.argv[1:] if not a.startswith("--")][0]
    story = json.load(open(path, encoding="utf-8"))
    folder = os.path.join(ROOT, "assets", "audio", "voice")
    for panel in story["panels"]:
        out = os.path.join(folder, panel["voice_id"] + ".ogg")
        if check:
            print(panel["voice_id"], "|", panel["text"], "\n    heard:", transcribe(out))
            continue
        if os.path.exists(out):
            print("keep ", panel["voice_id"])
            continue
        voice = panel.get("voice", story["voice"])
        model = speak(panel["text"], voice, story["style"], out)
        _mark(panel["voice_id"], voice, model)
        print("made ", panel["voice_id"])


if __name__ == "__main__":
    main()
