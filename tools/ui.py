"""App icon. Menu and HUD art lives in tools/ui_art.py."""
import sys
from PIL import Image, ImageDraw
R = sys.argv[1]
# app icon
ic = Image.new('RGBA',(512,512),(0,0,0,0)); d = ImageDraw.Draw(ic)
d.rounded_rectangle((0,0,511,511),110, fill=(90,170,240,255)); d.ellipse((40,240,472,620), fill=(110,200,90,255))
p = Image.open(f'{R}/assets/characters/pilo.png'); s = 380/p.height; p = p.resize((int(p.width*s),380), Image.LANCZOS)
ic.alpha_composite(p, ((512-p.width)//2, 80)); ic.save(f'{R}/icon.png')

