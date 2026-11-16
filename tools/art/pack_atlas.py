#!/usr/bin/env python3
"""اطلس‌ساز ساده: همهٔ PNGهای یک پارت (بدون sheet_*) را در اطلس ≤2048 می‌چیند و JSON مختصات می‌نویسد.
اجرا: python3 tools/art/pack_atlas.py p4_weapons [اندازه=2048]
خروجی: assets/atlas/<part>_<n>.png و <part>_<n>.json  (name → x,y,w,h)"""
import sys, os, json, glob
from PIL import Image
ROOT = os.path.join(os.path.dirname(__file__), '..', '..')
def main(part, size=2048, pad=2):
    files = sorted(f for f in glob.glob(f'{ROOT}/assets/art/{part}/*.png') if not os.path.basename(f).startswith('sheet_'))
    ims = [(os.path.basename(f)[:-4], Image.open(f).convert('RGBA')) for f in files]
    for n, im in ims:
        if im.width > size or im.height > size: im.thumbnail((size - 2*pad, size - 2*pad))
    ims.sort(key=lambda t: -t[1].height)
    os.makedirs(f'{ROOT}/assets/atlas', exist_ok=True)
    page = 0; i = 0
    while i < len(ims):
        at = Image.new('RGBA', (size, size), (0, 0, 0, 0)); meta = {}
        x = y = rowh = pad
        while i < len(ims):
            n, im = ims[i]
            if x + im.width + pad > size: x = pad; y += rowh + pad; rowh = 0
            if y + im.height + pad > size: break
            at.paste(im, (x, y)); meta[n] = [x, y, im.width, im.height]
            x += im.width + pad; rowh = max(rowh, im.height); i += 1
        at.save(f'{ROOT}/assets/atlas/{part}_{page}.png', optimize=True)
        json.dump(meta, open(f'{ROOT}/assets/atlas/{part}_{page}.json', 'w'), indent=1)
        print(part, page, len(meta)); page += 1
if __name__ == '__main__': main(sys.argv[1], int(sys.argv[2]) if len(sys.argv) > 2 else 2048)
