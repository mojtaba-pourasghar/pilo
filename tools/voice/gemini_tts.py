#!/usr/bin/env python3
"""Narration and character lines with Gemini's text-to-speech (Persian), written to
assets/audio/voice/<id>.ogg. The key comes from the environment (GEMINI_API_KEYS).

    python3 tools/voice/gemini_tts.py data/story/intro.json     # every panel of a story file
    python3 tools/voice/gemini_tts.py --check data/story/intro.json   # transcribe back and compare

Existing files are kept; delete one to redo it. Every clip made here is listed in
docs/voice/tts_generated.json (like the voice studio does), and a clip that is not on that list
is a human recording and is never replaced.
"""
import base64, json, os, subprocess, sys, tempfile, time, urllib.request, urllib.error

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
TTS_MODEL = "gemini-2.5-flash-preview-tts"
CHECK_MODEL = "gemini-flash-lite-latest"


def _call(model, body):
    key = os.environ["GEMINI_API_KEYS"].split(",")[0]
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
    for attempt in range(4):
        req = urllib.request.Request(url, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=400) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            msg = e.read()[:200]
            if e.code in (429, 500, 503):
                time.sleep(20 * (attempt + 1))
                continue
            raise RuntimeError(f"HTTP {e.code} {msg!r}")
    raise RuntimeError("gave up after retries")


def speak(text, voice, style, out):
    body = {"contents": [{"parts": [{"text": f"{style}\n{text}"}]}],
            "generationConfig": {"responseModalities": ["AUDIO"],
                                 "speechConfig": {"voiceConfig": {"prebuiltVoiceConfig": {"voiceName": voice}}}}}
    data = _call(TTS_MODEL, body)
    part = data["candidates"][0]["content"]["parts"][0]["inlineData"]
    with tempfile.NamedTemporaryFile(suffix=".pcm", delete=False) as f:
        f.write(base64.b64decode(part["data"]))
        pcm = f.name
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", "24000", "-ac", "1", "-i", pcm,
                    "-af", "silenceremove=start_periods=1:start_threshold=-50dB,areverse,silenceremove=start_periods=1:start_threshold=-50dB,areverse,loudnorm=I=-16",
                    "-c:a", "libvorbis", "-q:a", "5", out], check=True)
    os.unlink(pcm)


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


def _mark(key, voice):
    data = _registry()
    data["files"][key] = {"service": "gemini", "model": TTS_MODEL, "voice": voice,
                          "at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
    data["files"] = dict(sorted(data["files"].items()))
    os.makedirs(os.path.dirname(REGISTRY), exist_ok=True)
    json.dump(data, open(REGISTRY, "w", encoding="utf-8"), ensure_ascii=False, indent=2)


def main():
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
        speak(panel["text"], voice, story["style"], out)
        _mark(panel["voice_id"], voice)
        print("made ", panel["voice_id"])


if __name__ == "__main__":
    main()
