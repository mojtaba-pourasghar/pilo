#!/usr/bin/env python3
"""استفاده: python3 tools/art/set_status.py <status> <id> [<id>...]  (status: todo|draft|final). وضعیت را در manifest به‌روز می‌کند."""
import csv, sys, os
p=os.path.join(os.path.dirname(__file__),'..','..','assets','manifest','assets.csv')
st=sys.argv[1]; ids=set(sys.argv[2:]); assert st in('todo','draft','final')
rows=list(csv.DictReader(open(p,encoding='utf8'))); n=0
for r in rows:
    if r['id'] in ids: r['status']=st; n+=1
w=csv.DictWriter(open(p,'w',encoding='utf8',newline=''),fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
print('updated',n,'of',len(ids))
