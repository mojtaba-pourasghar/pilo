#!/usr/bin/env bash
# صدای ضبط‌شده‌ی گوینده را برای برنامه آماده می‌کند:
#   tools/voice/import_recordings.sh /path/to/studio/wavs
#
# برای هر فایل WAV/MP3 با نامی که در docs/voice/recording_list.csv آمده:
#   - مونو، ۴۴.۱ کیلوهرتز
#   - بریدن سکوت ابتدا و انتها، سپس ۸۰ میلی‌ثانیه سکوت اول و ۱۵۰ آخر
#   - یکسان‌سازی بلندی به −16 LUFS (EBU R128)
#   - MP3 با ۹۶ kbps در assets/audio/voice/
# نام‌های ناشناخته گزارش می‌شوند و کپی نمی‌شوند.
set -euo pipefail

SRC="${1:?usage: import_recordings.sh <folder-with-recordings>}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/assets/audio/voice"
LIST="$ROOT/docs/voice/recording_list.csv"
command -v ffmpeg >/dev/null || { echo "ffmpeg لازم است" >&2; exit 1; }
[ -f "$LIST" ] || python3 "$ROOT/tools/voice/make_recording_script.py"

known=$(cut -d, -f2 "$LIST" | tail -n +2 | sed 's/\.mp3$//')
ok=0; unknown=0; imported=()
for f in "$SRC"/*.{wav,WAV,mp3,MP3}; do
  [ -e "$f" ] || continue
  base="$(basename "${f%.*}")"
  if ! grep -qx "$base" <<<"$known"; then
    echo "⚠️  ناشناخته (در فهرست نیست): $base"; unknown=$((unknown + 1)); continue
  fi
  ffmpeg -loglevel error -y -i "$f" -ac 1 -ar 44100 -af \
    "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.02,areverse,silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.02,areverse,adelay=80,apad=pad_dur=0.15,loudnorm=I=-16:TP=-1.5:LRA=11" \
    -c:a libmp3lame -b:a 96k "$OUT/$base.mp3"
  ok=$((ok + 1))
  imported+=("$base")
done
# ضبطِ انسانی جای صدای ماشینیِ استودیو را می‌گیرد: از فهرستِ TTS برداشته می‌شود.
if [ "${#imported[@]}" -gt 0 ] && [ -f "$ROOT/docs/voice/tts_generated.json" ]; then
  python3 - "$ROOT/docs/voice/tts_generated.json" "${imported[@]}" <<'PY'
import json, sys
path, keys = sys.argv[1], sys.argv[2:]
data = json.load(open(path, encoding="utf-8"))
for k in keys:
    data.get("files", {}).pop(k, None)
json.dump(data, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
open(path, "a").write("\n")
PY
fi
echo "✅ $ok فایل آماده شد در assets/audio/voice ($unknown ناشناخته)"
python3 "$ROOT/tools/voice/make_recording_script.py"
