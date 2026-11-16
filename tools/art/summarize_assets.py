#!/usr/bin/env python3
"""docs/ASSET_LIST.md را از assets/manifest/assets.csv بازتولید می‌کند (شمارش هر پارت/اولویت و وضعیت)."""
import csv, os
from collections import Counter
root=os.path.join(os.path.dirname(__file__),'..','..')
r=list(csv.DictReader(open(os.path.join(root,'assets/manifest/assets.csv'),encoding='utf8')))
c=Counter((x['part'],x['priority']) for x in r); st=Counter((x['part'],x['status']) for x in r)
parts=sorted({k[0] for k in c})
L=['# فهرست دارایی‌ها (خلاصه)\n','> خودکار از `assets/manifest/assets.csv`. بازتولید: `python3 tools/art/summarize_assets.py`.\n','| پارت | P0 | P1 | P2 | جمع | draft | final |','|---|---|---|---|---|---|---|']
for p in parts:
    a=[c[(p,q)] for q in ('P0','P1','P2')]
    L.append(f"| {p} | {a[0]} | {a[1]} | {a[2]} | {sum(a)} | {st[(p,'draft')]} | {st[(p,'final')]} |")
tot=[sum(c[(p,q)] for p in parts) for q in ('P0','P1','P2')]
L.append(f"| **جمع** | {tot[0]} | {tot[1]} | {tot[2]} | {sum(tot)} | {sum(st[(p,'draft')] for p in parts)} | {sum(st[(p,'final')] for p in parts)} |")
open(os.path.join(root,'docs/ASSET_LIST.md'),'w',encoding='utf8').write('\n'.join(L)+'\n'); print('\n'.join(L))
