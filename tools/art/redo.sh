#!/bin/bash
# Regenerates pictures that were judged not good enough: their raw sources are moved aside
# (art_src/_old/) so cf_generate.py makes them again, then they are post-processed.
#   CF_KEYS=... tools/art/redo.sh id1 id2 ...
set -e
cd "$(dirname "$0")/../.."
mkdir -p art_src/_old
for id in "$@"; do
  [ -f "art_src/$id.png" ] && mv "art_src/$id.png" "art_src/_old/$id.png"
done
python3 tools/art/cf_generate.py --only "$(IFS=,; echo "$*")"
VENV=${VENV:-venv}
"$VENV/bin/python" tools/art/postprocess.py "$@"
