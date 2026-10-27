#!/usr/bin/env bash
# Regenerates the three world backgrounds with Cloudflare Workers AI (flux-1-schnell).
# Credentials come from the environment; never commit them:
#   export CF_ACCOUNT_ID=...  CF_API_TOKEN=...
#   tools/gen_backgrounds.sh /tmp/bg   # then review and copy into assets/environments/
# Each 1024px image is cropped and joined with its mirror so it scrolls without a seam.
set -euo pipefail
out="${1:-/tmp/pilo_backgrounds}"
mkdir -p "$out"
: "${CF_ACCOUNT_ID:?set CF_ACCOUNT_ID}" "${CF_API_TOKEN:?set CF_API_TOKEN}"
style="2D cartoon side-scrolling platformer game background, vivid cheerful colors, children's game art, no characters, no text"
declare -A prompts=(
  [forest]="bright sunny magical forest of sprouts, giant colorful mushrooms, soft green hills, blue sky with fluffy clouds"
  [sky]="floating sky islands with waterfalls and tiny cottages, big fluffy white clouds, bright blue sky, windmills"
  [cave]="magical crystal cave, glowing purple and cyan crystals, soft light beams, friendly not scary"
)
for name in "${!prompts[@]}"; do
  curl -sS -X POST "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/ai/run/@cf/black-forest-labs/flux-1-schnell" \
    -H "Authorization: Bearer $CF_API_TOKEN" -H "Content-Type: application/json" \
    -d "{\"prompt\":\"$style, ${prompts[$name]}\",\"steps\":8}" -o "$out/$name.json"
  python3 - "$out/$name.json" "$out/bg_$name.jpg" "$name" <<'PY'
import base64, io, json, sys
from PIL import Image, ImageOps
src, dst, name = sys.argv[1:]
im = Image.open(io.BytesIO(base64.b64decode(json.load(open(src))["result"]["image"]))).convert("RGB")
im = im.crop((0, 0, 1024, 880 if name == "cave" else 1024))
out = Image.new("RGB", (im.width * 2, im.height))
out.paste(im, (0, 0)); out.paste(ImageOps.mirror(im), (im.width, 0))
out.save(dst, quality=88)
PY
  echo "wrote $out/bg_$name.jpg"
done
