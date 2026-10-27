import sys
from PIL import Image, ImageDraw, ImageFilter
from collections import deque
src = Image.open(sys.argv[1]).convert('RGB')
out = sys.argv[2]
crops = {
 'hero': (505,45,632,297), 'hero_side': (638,128,704,250),
 'pilo': (795,82,894,200), 'pilo_sleep': (935,240,1022,307),
 'star': (522,362,588,428), 'coin': (605,362,668,428), 'crystal': (688,360,745,428),
 'key': (772,362,822,428), 'heart': (843,368,904,424), 'backpack': (938,362,1000,430),
}
TOL={'pilo':14,'pilo_sleep':14,'hero':40}
def isbg(p, ref, tol=60):
    return sum(abs(a-b) for a,b in zip(p,ref)) < tol and min(p) > 200
for name,(x0,y0,x1,y1) in crops.items():
    im = src.crop((x0,y0,x1,y1)); w,h = im.size; px = im.load()
    ref = px[0,0]
    mask = [[False]*h for _ in range(w)]
    q = deque()
    for x in range(w):
        for y in (0,h-1): q.append((x,y))
    for y in range(h):
        for x in (0,w-1): q.append((x,y))
    while q:
        x,y = q.popleft()
        if mask[x][y] or not isbg(px[x,y], ref, TOL.get(name,60)): continue
        mask[x][y] = True
        for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
            nx,ny = x+dx,y+dy
            if 0<=nx<w and 0<=ny<h and not mask[nx][ny]: q.append((nx,ny))
    a = Image.new('L',(w,h),255); ap = a.load()
    for x in range(w):
        for y in range(h):
            if mask[x][y]: ap[x,y]=0
    a = a.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
    rgba = im.convert('RGBA'); rgba.putalpha(a)
    bbox = rgba.getbbox(); rgba = rgba.crop(bbox)
    scale = 2 if name.startswith(('hero','pilo')) else 1
    rgba = rgba.resize((rgba.width*scale, rgba.height*scale), Image.LANCZOS)
    rgba.save(f'{out}/{name}.png')
    print(name, rgba.size)
