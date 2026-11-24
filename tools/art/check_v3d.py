# Checks that all P0 art files exist and are PNGs; prints size vs wanted.
import json, os, struct, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
man = json.load(open(os.path.join(ROOT, "tools", "art", "v3d_manifest.json"), encoding="utf-8"))


def png_size(p):
    with open(p, "rb") as f:
        h = f.read(24)
    if h[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    return struct.unpack(">II", h[16:24])


missing, bad = [], []
for m in man:
    p = os.path.join(ROOT, m["path"])
    if not os.path.exists(p):
        missing.append(m)
        continue
    s = png_size(p)
    if s is None:
        bad.append(m)
        continue
    print(f"OK  {m['n']:02d} {m['id']}  {s[0]}x{s[1]}  (wanted {m['size']})")
for m in missing:
    print(f"MISSING {m['n']:02d} {m['path']}")
for m in bad:
    print(f"BAD (not a PNG) {m['path']}")
print(f"\n{len(man) - len(missing) - len(bad)}/{len(man)} present")
sys.exit(1 if missing or bad else 0)
