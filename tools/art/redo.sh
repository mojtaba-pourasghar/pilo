#!/bin/bash
# Makes pictures again that were judged not good enough. The old picture stays until the
# new one is made (so a day whose allowance runs out never leaves a character without one),
# then the new ones are post-processed.
#   CF_KEYS=... VENV=... tools/art/redo.sh id1 id2 ...
set -e
cd "$(dirname "$0")/../.."
python3 tools/art/cf_generate.py --redo --only "$(IFS=,; echo "$*")" | tee /tmp/redo_gen.log
made=$(grep '^made' /tmp/redo_gen.log | awk '{print $2}' | tr '\n' ' ')
VENV=${VENV:-venv}
[ -n "$made" ] && "$VENV/bin/python" tools/art/postprocess.py $made
echo "made: $made"
