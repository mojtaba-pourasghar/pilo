#!/usr/bin/env python3
"""Generates or edits a picture with Gemini's image model (art for characters, backgrounds,
story panels). The key is read from the environment (GEMINI_API_KEYS, comma separated) and
is never written to the project.

    python3 tools/art/gemini_image.py OUT.png "prompt" [--ref a.png --ref b.png] [--aspect 16:9] [--size 2K]
"""
import argparse, base64, json, os, sys, time, urllib.request, urllib.error

MODEL = os.environ.get("GEMINI_IMAGE_MODEL", "gemini-3-pro-image")


def generate(out, prompt, refs=(), aspect="1:1", size="2K", model=MODEL, tries=3):
    keys = [k for k in os.environ.get("GEMINI_API_KEYS", "").split(",") if k]
    if not keys:
        sys.exit("GEMINI_API_KEYS is not set")
    parts = []
    for ref in refs:
        mime = "image/webp" if ref.endswith(".webp") else "image/jpeg" if ref.endswith((".jpg", ".jpeg")) else "image/png"
        parts.append({"inline_data": {"mime_type": mime, "data": base64.b64encode(open(ref, "rb").read()).decode()}})
    parts.append({"text": prompt})
    body = {"contents": [{"parts": parts}],
            "generationConfig": {"responseModalities": ["IMAGE"], "imageConfig": {"aspectRatio": aspect, "imageSize": size}}}
    last = None
    for attempt in range(tries):
        key = keys[attempt % len(keys)]
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
        req = urllib.request.Request(url, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=300) as r:
                data = json.load(r)
            for cand in data.get("candidates", []):
                for part in cand.get("content", {}).get("parts", []):
                    inline = part.get("inline_data") or part.get("inlineData")
                    if inline:
                        os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
                        open(out, "wb").write(base64.b64decode(inline["data"]))
                        return out
            last = json.dumps(data)[:400]
        except urllib.error.HTTPError as e:
            last = f"HTTP {e.code}: {e.read()[:300]!r}"
        except Exception as e:  # network hiccup: retry
            last = repr(e)
        time.sleep(4 * (attempt + 1))
    sys.exit(f"no image for {out}: {last}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("prompt")
    ap.add_argument("--ref", action="append", default=[])
    ap.add_argument("--aspect", default="1:1")
    ap.add_argument("--size", default="2K")
    ap.add_argument("--model", default=MODEL)
    a = ap.parse_args()
    print(generate(a.out, a.prompt, a.ref, a.aspect, a.size, a.model))
