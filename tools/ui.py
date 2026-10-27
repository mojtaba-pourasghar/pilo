import sys
from PIL import Image, ImageDraw, ImageFilter
R = sys.argv[1]
N = 160
def base(c1, c2):
    im = Image.new('RGBA', (N, N), (0,0,0,0))
    sh = Image.new('RGBA', (N, N), (0,0,0,0)); d = ImageDraw.Draw(sh)
    d.ellipse((10,16,N-10,N-4), fill=(0,0,0,90)); sh = sh.filter(ImageFilter.GaussianBlur(4))
    im.alpha_composite(sh)
    d = ImageDraw.Draw(im)
    d.ellipse((8,6,N-8,N-12), fill=(255,255,255,235))
    d.ellipse((16,14,N-16,N-20), fill=c1)
    d.ellipse((24,18,N-24,N//2), fill=c2)
    return im, d
def save(im, name): im.save(f'{R}/assets/ui/{name}.png')
W = (255,255,255,255)
im,d = base((70,140,230,255),(120,180,250,255)); d.polygon([(52,74),(96,44),(96,104)], fill=W); d.rectangle((90,62,112,86), fill=W); save(im,'btn_left')
im,d = base((70,140,230,255),(120,180,250,255)); d.polygon([(108,74),(64,44),(64,104)], fill=W); d.rectangle((48,62,70,86), fill=W); save(im,'btn_right')
im,d = base((60,180,90,255),(120,220,140,255)); d.polygon([(80,36),(116,80),(44,80)], fill=W); d.rectangle((66,78,94,112), fill=W); save(im,'btn_jump')
im,d = base((150,90,220,255),(190,140,250,255))
d.polygon([(54,40),(106,40),(80,74)], fill=W); d.polygon([(80,74),(106,108),(54,108)], fill=W)
d.rectangle((48,34,112,42), fill=W); d.rectangle((48,106,112,114), fill=W); save(im,'btn_time')
im,d = base((245,170,40,255),(255,210,110,255)); d.ellipse((54,36,106,88), fill=W); d.rectangle((68,84,92,104), fill=W); d.rectangle((70,106,90,112), fill=W); save(im,'btn_hint')
im,d = base((245,140,40,255),(255,190,110,255)); d.rounded_rectangle((56,44,74,104),4, fill=W); d.rounded_rectangle((86,44,104,104),4, fill=W); save(im,'btn_pause')
# app icon
ic = Image.new('RGBA',(512,512),(0,0,0,0)); d = ImageDraw.Draw(ic)
d.rounded_rectangle((0,0,511,511),110, fill=(90,170,240,255)); d.ellipse((40,240,472,620), fill=(110,200,90,255))
p = Image.open(f'{R}/assets/characters/pilo.png'); s = 380/p.height; p = p.resize((int(p.width*s),380), Image.LANCZOS)
ic.alpha_composite(p, ((512-p.width)//2, 80)); ic.save(f'{R}/icon.png')
