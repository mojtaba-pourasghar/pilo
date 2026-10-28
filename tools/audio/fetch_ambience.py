#!/usr/bin/env python3
"""Real ambience recordings for Safar-e Pilo, from Wikimedia Commons.

Same approach as pokpok's tools/sfx/fetch_sounds.py: tools/audio/picks.json names one hand-picked
Commons file per destination (e.g. "ambient/forest" -> assets/audio/ambient/forest.ogg) and which
stretch to keep. This script downloads each pick, reads its licence and author from Commons,
cuts the stretch, makes it a seamless loop (the tail is cross-faded into the head), turns it
mono 44.1 kHz at a quiet loudness so it sits under music and voice, writes Ogg Vorbis, and
records source, licence and author in docs/audio/sound_sources.json (credit CC BY / BY-SA
authors on the store page and the "about" screen).

    python3 tools/audio/fetch_ambience.py             # every pick not yet applied
    python3 tools/audio/fetch_ambience.py forest --force

Needs commons.wikimedia.org / upload.wikimedia.org and ffmpeg on PATH. Commons asks for a slow
pace (429 + Retry-After), which is honoured.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PICKS = Path(__file__).resolve().parent / "picks.json"
SOURCES = ROOT / "docs/audio/sound_sources.json"
CACHE = Path(__file__).resolve().parent / ".cache"
UA = "PiloSoundFetcher/1.0 (kids game; https://github.com/mojtaba-pourasghar/pilo)"
FREE = re.compile(r"^(cc0|public domain|pd|cc[ -]by(-sa)?( \d\.\d)?)", re.I)
FADE = 2.0  # seconds of cross-fade that hide the loop seam


def fetch(url: str) -> bytes:
    for _ in range(30):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": UA}), timeout=120) as res:
                return res.read()
        except urllib.error.HTTPError as err:
            if err.code != 429:
                raise
            wait = int(err.headers.get("Retry-After") or 20) + 2
            print(f"   Commons asks to wait {wait}s", flush=True)
            time.sleep(wait)
    raise RuntimeError("Commons kept answering 429")


def info(title: str) -> dict:
    query = {"action": "query", "titles": title, "prop": "imageinfo", "format": "json",
             "iiprop": "url|extmetadata", "iiextmetadatafilter": "LicenseShortName|Artist|ImageDescription"}
    data = json.loads(fetch("https://commons.wikimedia.org/w/api.php?" + urllib.parse.urlencode(query)))
    page = next(iter(data["query"]["pages"].values()))
    if "imageinfo" not in page:
        raise RuntimeError(f"{title} not found on Commons")
    ii = page["imageinfo"][0]
    meta = ii.get("extmetadata", {})
    strip = lambda s: re.sub(r"<[^>]+>", "", s or "").strip()
    return {"url": ii["url"], "page": ii.get("descriptionurl", ""),
            "license": strip(meta.get("LicenseShortName", {}).get("value")),
            "author": strip(meta.get("Artist", {}).get("value"))}


def ffmpeg(*args: str) -> None:
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", *args], check=True)


def make_loop(src: Path, dst: Path, start: float, seconds: float, lufs: float) -> None:
    """Cuts `seconds` from `start` and hides the seam: the first FADE seconds are an equal-power
    blend of the clip's own start (fading in) and the stretch just after its end (fading out),
    so when the loop wraps, the end flows straight into the beginning."""
    import numpy as np
    sr = 44100
    with tempfile.TemporaryDirectory() as tmp:
        cut = Path(tmp) / "cut.raw"
        ffmpeg("-ss", str(start), "-t", str(seconds + FADE), "-i", str(src), "-ac", "1", "-ar", str(sr),
               "-af", f"highpass=f=60,loudnorm=I={lufs}:TP=-3:LRA=11", "-f", "f32le", str(cut))
        audio = np.fromfile(cut, dtype=np.float32)
        fade = int(FADE * sr)
        length = min(int(seconds * sr), len(audio) - fade)  # a short source shortens the loop
        if length < fade * 3:
            raise RuntimeError("source too short for a loop")
        t = np.linspace(0.0, np.pi / 2, fade, dtype=np.float32)
        loop = audio[:length].copy()
        loop[:fade] = audio[:fade] * np.sin(t) + audio[length:length + fade] * np.cos(t)
        mixed = Path(tmp) / "loop.raw"
        np.clip(loop, -1.0, 1.0).astype(np.float32).tofile(mixed)
        dst.parent.mkdir(parents=True, exist_ok=True)
        ffmpeg("-f", "f32le", "-ar", str(sr), "-ac", "1", "-i", str(mixed),
               "-c:a", "libvorbis", "-q:a", "4", str(dst))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("names", nargs="*", help="pick keys or their last part (forest, cave...)")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    picks = json.loads(PICKS.read_text(encoding="utf-8"))["picks"]
    sources = json.loads(SOURCES.read_text(encoding="utf-8")) if SOURCES.exists() else {
        "note": "Real recordings with source and licence. Sounds not listed here are made by tools/audio.py.", "files": {}}
    failed = 0
    for key, pick in picks.items():
        if args.names and key not in args.names and key.split("/")[-1] not in args.names:
            continue
        dst = ROOT / "assets/audio" / f"{key}.ogg"
        if dst.exists() and key in sources["files"] and not args.force:
            print(f"skip {key} (already applied)")
            continue
        try:
            print(f"-> {key}: {pick['file']}", flush=True)
            meta = info(pick["file"])
            if not FREE.match(meta["license"]):
                raise RuntimeError(f"licence {meta['license']!r} is not free enough")
            # Downloads are kept in tools/audio/.cache (not in git): Commons throttles hard, and a
            # second run only re-cuts the loop.
            raw = CACHE / (key.replace("/", "_") + Path(urllib.parse.urlparse(meta["url"]).path).suffix)
            if not raw.exists():
                print(f"   downloading {meta['url'].rsplit('/', 1)[-1][:60]}", flush=True)
                CACHE.mkdir(parents=True, exist_ok=True)
                raw.write_bytes(fetch(meta["url"]))
            make_loop(raw, dst, float(pick.get("start", 0)), float(pick["seconds"]), float(pick.get("lufs", -24)))
            sources["files"][key] = {"file": f"assets/audio/{key}.ogg", "source": meta["page"], "license": meta["license"],
                                     "author": meta["author"], "fetched": datetime.now(timezone.utc).strftime("%Y-%m-%d")}
            save_sources(sources)
            print(f"   ok  {meta['license']} — {meta['author'][:60]}", flush=True)
            time.sleep(3)
        except Exception as err:  # keep going; report at the end
            failed += 1
            print(f"   FAILED {key}: {err}", file=sys.stderr, flush=True)
    save_sources(sources)
    return 1 if failed else 0


def save_sources(sources: dict) -> None:
    """Written after every file, so an interrupted run keeps what it already fetched."""
    SOURCES.parent.mkdir(parents=True, exist_ok=True)
    sources["files"] = dict(sorted(sources["files"].items()))
    SOURCES.write_text(json.dumps(sources, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")


if __name__ == "__main__":
    sys.exit(main())
