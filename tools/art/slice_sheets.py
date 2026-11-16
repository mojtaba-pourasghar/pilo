#!/usr/bin/env python3
"""برش شیت‌های کانسپت (assets/art/<part>/sheet_*_v1.png) به اسپرایت‌های جدا با پس‌زمینهٔ شفاف.
اجرا: python3 tools/art/slice_sheets.py   (فقط draft؛ هنر نهایی نیست)"""
import os, sys, numpy as np
from PIL import Image
from scipy import ndimage as ndi
R = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'art')
made = []

def bgcolor(a):
    c = np.concatenate([a[:6,:6].reshape(-1,3), a[-6:,-6:].reshape(-1,3), a[:6,-6:].reshape(-1,3), a[-6:,:6].reshape(-1,3)])
    return np.median(c, 0)

def cut(im, bg, tol=40, glob=False):
    """پس‌زمینه را (متصل به لبه) شفاف می‌کند."""
    a = np.asarray(im.convert('RGB')).astype(int)
    near = abs(a - bg).sum(2) < tol
    lab, n = ndi.label(near)
    edge = set(lab[0]) | set(lab[-1]) | set(lab[:, 0]) | set(lab[:, -1]); edge.discard(0)
    bgm = np.isin(lab, list(edge))
    bgm = ndi.binary_dilation(bgm, iterations=1) & near
    if glob:  # حفره‌های بسته (مثلاً داخل کمان) هم شفاف شوند
        hl, hn = ndi.label(ndi.binary_opening(near, iterations=1))
        if hn:
            sz = ndi.sum(np.ones_like(hl), hl, range(1, hn + 1))
            for k in range(1, hn + 1):
                if sz[k-1] > 1500: bgm = bgm | (hl == k)   # فقط حفره‌های بزرگ؛ سفیدی چشم می‌ماند
    al = np.where(bgm, 0, 255).astype(np.uint8)
    al = ndi.gaussian_filter(al.astype(float), 0.8).astype(np.uint8)
    # حذف تکه‌های کوچک چسبیده به لبه (باقی‌ماندهٔ اسپرایت همسایه)
    lab2, n2 = ndi.label(al > 20)
    if n2 > 1:
        sizes = ndi.sum(np.ones_like(al), lab2, range(1, n2 + 1)); big = sizes.max()
        for k in range(1, n2 + 1):
            ys, xs = np.where(lab2 == k)
            thin = (ys.max() - ys.min() < 10) and (xs.max() - xs.min() > 0.4 * al.shape[1])  # خط زمین
            if thin or sizes[k-1] < 0.15 * big and (xs.min() <= 1 or ys.min() <= 1 or xs.max() >= al.shape[1]-2 or ys.max() >= al.shape[0]-2):
                al[lab2 == k] = 0
    out = im.convert('RGBA'); out.putalpha(Image.fromarray(al))
    bb = out.getchannel('A').point(lambda v: 255 if v > 20 else 0).getbbox()
    return out.crop(bb) if bb else out

def save(sheet, box, part, name, tol=40, pad=6, glob=False):
    im = Image.open(sheet).convert('RGB')
    a = np.asarray(im).astype(int); bg = bgcolor(a)
    x0, y0, x1, y1 = box
    c = im.crop((max(0, x0-pad), max(0, y0-pad), min(im.width, x1+pad), min(im.height, y1+pad)))
    o = cut(c, bg, tol, glob)
    os.makedirs(f'{R}/{part}', exist_ok=True)
    o.save(f'{R}/{part}/{name}.png'); made.append(name)


def save_cell(sheet, box, part, name, cell=480, tol=40, glob=True):
    """برش + قرارگیری در سلول ثابت (مرکز-پایین) تا فریم‌های انیمیشن در Godot جابه‌جا نشوند."""
    im = Image.open(sheet).convert('RGB'); a = np.asarray(im).astype(int); bg = bgcolor(a)
    x0, y0, x1, y1 = box
    o = cut(im.crop((max(0, x0-6), max(0, y0-6), min(im.width, x1+6), min(im.height, y1))), bg, tol, glob)
    al = np.array(o.getchannel('A'))   # حذف خط زمینهٔ نازک چسبیده به پا
    for y in range(al.shape[0]-1, al.shape[0]//2, -1):
        if (al[y] > 20).sum() > 0.55 * al.shape[1]: al[y] = 0
        else: break
    o.putalpha(Image.fromarray(al)); bb = o.getchannel('A').getbbox(); o = o.crop(bb) if bb else o
    if o.width > cell or o.height > cell: o.thumbnail((cell, cell))
    c = Image.new('RGBA', (cell, cell), (0, 0, 0, 0))
    c.paste(o, ((cell - o.width)//2, cell - o.height), o)
    os.makedirs(f'{R}/{part}', exist_ok=True); c.save(f'{R}/{part}/{name}.png'); made.append(name)

def runs(v, minlen=30):
    r = []; s = None
    for i, x in enumerate(v):
        if x and s is None: s = i
        if not x and s is not None:
            if i - s >= minlen: r.append((s, i))
            s = None
    if s is not None: r.append((s, len(v)))
    return r

def comps(sheet, tol=40, close=4, minarea=6000):
    a = np.asarray(Image.open(sheet).convert('RGB')).astype(int)
    m = abs(a - bgcolor(a)).sum(2) > tol
    m = ndi.binary_closing(m, iterations=close)
    lab, n = ndi.label(m)
    out = []
    for s in ndi.find_objects(lab):
        h, w = s[0].stop - s[0].start, s[1].stop - s[1].start
        if h * w >= minarea and h > 60 and w > 60: out.append((s[1].start, s[0].start, s[1].stop, s[0].stop))
    return out

def reading_order(bxs, rows):
    """گروه‌بندی به ردیف با مرکز y؛ rows = لبه‌های y"""
    res = []
    for y0, y1 in rows:
        r = [b for b in bxs if y0 <= (b[1]+b[3])/2 < y1]
        res += sorted(r, key=lambda b: b[0])
    return res

def main():
    # ── P4 سلاح‌ها
    S = f'{R}/p4_weapons/sheet_weapons_v1.png'
    for i, (x0, x1) in enumerate([(84,439),(571,935),(1056,1417),(1539,1936),(2090,2610)]):
        save(S, (x0, 25, x1, 573), 'p4_weapons', f'p4_wpn_lens_bow_l{i+1}_icon', 30, 6, True)
    for name, row in (('wood_sword', [(57,343),(372,695),(714,1118)]), ('club', [(1203,1554),(1634,2030),(2107,2616)])):
        pass
    sw = [(57,343),(372,695),(714,1118)]; cl = [(1203,1554),(1634,2030),(2107,2616)]
    for i, (x0, x1) in enumerate(sw): save(S, (x0, 580, x1, 880), 'p4_weapons', f'p4_wpn_wood_sword_l{i+1}_icon', 35)
    for i, (x0, x1) in enumerate(cl): save(S, (x0, 580, x1, 880), 'p4_weapons', f'p4_wpn_club_l{i+1}_icon', 35)
    sp = [(57,364),(374,720),(722,1119)]; sl = [(1237,1566),(1669,2037),(2166,2587)]
    for i, (x0, x1) in enumerate(sp): save(S, (x0, 880, x1, 1178), 'p4_weapons', f'p4_wpn_spear_l{i+1}_icon', 35)
    for i, (x0, x1) in enumerate(sl): save(S, (x0, 880, x1, 1178), 'p4_weapons', f'p4_wpn_sling_l{i+1}_icon', 35)
    for nm, (x0, x1) in zip(['star', 'feather', 'heart', 'clock', 'rock'], [(444,666),(811,1072),(1233,1456),(1620,1862),(2005,2292)]):
        save(S, (x0, 1185, x1, 1508), 'p4_weapons', f'p4_wpn_special_{nm}_head_icon', 35)
    # ── P8 افکت‌ها (شبکهٔ ۶×۳ روی زمینهٔ سرمه‌ای)
    S = f'{R}/p8_fx/sheet_fx_v1.png'
    names = [['time_lens','ghost_layer','key_past_glow','key_present_glow','key_blue_glow','time_split'],
             ['element_fire','element_water','element_plant','element_wind','element_light','element_shadow'],
             ['ui_crystals','ui_heart','ui_star_burst','ui_chest_open','ui_music_trail','ui_beam']]
    W, H = 2720/6, 1536/3
    top = [(55,496),(604,978),(1088,1568),(1663,1906),(1929,2162),(2221,2688)]
    for c, (x0, x1) in enumerate(top):
        save(S, (x0, 9, x1, 497), 'p8_fx', f'p8_fx_{names[0][c]}', 70, 0)
    for r in range(1, 3):
        for c in range(6):
            save(S, (int(c*W)+14, int(r*H)+14, int((c+1)*W)-14, int((r+1)*H)-14), 'p8_fx', f'p8_fx_{names[r][c]}', 70, 0)
    # ── P9 کیت رابط (برش دستی؛ ۹-برش را در Godot با patch margin تنظیم کن)
    S = f'{R}/p9_ui/sheet_ui_kit_v1.png'
    ui = {'btn_gold':(47,51,680,262),'btn_blue_a':(47,272,380,407),'btn_blue_b':(380,272,687,407),
          'btn_back_green':(690,90,885,289),'btn_settings_purple':(885,90,1076,289),
          'bar_coin':(1105,94,1552,251),'bar_gem':(1580,93,2004,251),
          'star_1':(2046,74,2151,253),'star_2':(2161,74,2300,253),'star_3':(2313,74,2487,253),'icon_lock':(2504,45,2686,281),
          'ribbon_red':(47,422,845,570),'ribbon_purple':(47,572,845,713),
          'panel_big_tabs':(58,718,1267,1426),'panel_card_tall':(1297,795,1687,1439),
          'bar_heart':(1104,287,1978,456),'bar_mana':(1104,474,1979,661),
          'badge_keyhole_past':(2038,287,2346,691),'badge_keyhole_present':(2366,287,2674,690),
          'badge_paw_a':(1764,718,2175,1146),'badge_paw_b':(2239,718,2650,1146),
          'slot_lens':(1742,1167,2007,1436),'slot_hook':(2059,1167,2323,1436),'slot_lantern':(2381,1167,2650,1436)}
    for k, b in ui.items(): save(S, b, 'p9_ui', f'p9_ui_{k}', 40, 2)
    # ── P1 چرخهٔ حرکت آرسام (سلول ۴۸۰ ثابت، مرکز-پایین)
    S = f'{R}/p1_heroes/sheet_arsam_cycles_v1.png'
    cyc = [('idle', 36, 491, [(345,545),(686,889),(1032,1234),(1391,1593),(1745,1944),(2110,2312)]),
           ('walk', 554, 966, [(71,332),(421,644),(735,972),(1050,1298),(1382,1642),(1724,1967),(2064,2308),(2395,2643)]),
           ('run', 1050, 1449, [(51,334),(382,644),(672,976),(995,1340),(1363,1646),(1694,1972),(1995,2306),(2334,2669)])]
    for nm, y0, y1, xs in cyc:
        for i, (x0, x1) in enumerate(xs): save_cell(S, (x0, y0, x1, y1), 'p1_heroes', f'p1_hero_arsam_{nm}_f{i+1}')
    # ── پرتره‌های چهره
    S = f'{R}/p1_heroes/sheet_arsam_expressions_v1.png'
    ex = [('happy',(161,19,776,744)),('determined',(1060,19,1643,744)),('surprised',(1922,19,2540,744)),
          ('sad',(161,781,775,1493)),('laughing',(1048,781,1644,1493)),('tired',(1938,781,2540,1493))]
    for nm, b in ex: save(S, b, 'p1_heroes', f'p1_hero_arsam_portrait_{nm}', 40, 4)
    # ── NPC
    S = f'{R}/p1_heroes/sheet_npc_grandparents_crow_v1.png'
    npc = [('grandpa_idle',(20,330)),('grandpa_talk',(330,600)),('grandpa_smile',(600,990)),
           ('grandma_idle',(1000,1285)),('grandma_talk',(1285,1570)),('grandma_smile',(1570,1900)),
           ('crow_idle',(1900,2100)),('crow_call',(2100,2370)),('crow_wave',(2370,2710))]
    for nm, (x0, x1) in npc: save_cell(S, (x0, 242, x1, 1222), 'p1_heroes', f'p1_npc_{nm}', 480, 40)
    # ── P7 جزئیات زنده (۴ ردیف × ۴ گروه × ۴ فریم)
    S = f'{R}/p7_living/sheet_living_ch01_v1.png'
    groups = [['leaf','bird','butterfly','cloud'], ['waterfall','ripple','fish_jump','light_rays'],
              ['glow_mushroom','grass','tree_sway','vine'], ['firefly','squirrel','sleep_bear','sign']]
    rowsY = [(57,328),(425,695),(798,1065),(1158,1448)]
    colsX = [[(48,176),(204,331),(354,484),(513,637)],[(707,858),(876,1019),(1038,1170),(1185,1322)],
             [(1375,1549),(1570,1693),(1739,1835),(1854,2003)],[(2055,2221),(2225,2382),(2384,2533),(2539,2697)]]
    for r, (y0, y1) in enumerate(rowsY):
        for g in range(4):
            gn = groups[r][g]
            if r == 1:
                colsX2 = [[(26,176),(186,336),(345,496),(505,656)],[(695,854),(860,1018),(1024,1181),(1187,1344)],
                          [(1374,1516),(1525,1704),(1705,1846),(1856,1996)],[(2055,2205),(2219,2369),(2382,2531),(2545,2696)]][g]
            elif r == 2:
                colsX2 = [[(27,177),(186,336),(346,496),(506,656)],[(697,853),(862,1016),(1026,1178),(1190,1340)],
                          [(1374,1533),(1541,1699),(1706,1859),(1867,2018)],[(2053,2207),(2218,2370),(2381,2532),(2542,2683)]][g]
            elif r == 3:
                colsX2 = [[(38,638)],[(694,855),(859,1019),(1025,1175),(1189,1340)],
                          [(1373,1533),(1537,1699),(1703,1861),(1865,2019)],[(2055,2205),(2218,2369),(2372,2531),(2544,2695)]][g]
            else: colsX2 = colsX[g]
            for f, (x0, x1) in enumerate(colsX2):
                nm = f'p7_living_ch01_{gn}' if len(colsX2) == 1 else f'p7_living_ch01_{gn}_f{f+1}'
                save(S, (x0, y0, x1, y1), 'p7_living', nm, 30)
    # ── P5 دشمنان (اجزای متصل + چند برش دستی برای اسپرایت‌های چسبیده)
    S = f'{R}/p5_enemies/sheet_ch01_enemies_v1.png'
    bx = reading_order(comps(S, 40, 5, 9000), [(0,470),(470,1060),(1060,1536)])
    assert len(bx) == 23, len(bx)
    b6a, b6b = (1896,116,2140,419), (2145,116,2425,419)
    g = [(1264,537,1555,1039),(1555,537,1845,1039),(1845,537,2130,1039),(2130,537,2400,1039)]
    boxes = bx[:6] + [b6a, b6b, bx[7]] + bx[8:12] + g + [bx[13]] + bx[14:]
    nm = ['shadow_cat_idle','shadow_cat_attack','shadow_cat_released','shadow_moth_idle','shadow_moth_attack','shadow_moth_released',
          'thorn_mushroom_idle','thorn_mushroom_attack','thorn_mushroom_released',
          'stump_idle','stump_attack','stump_released','stone_guard_idle','stone_guard_attack','stone_guard_released',
          'old_bear_idle','old_bear_attack','old_bear_released',
          'trap_spikes_idle','trap_spikes_active','trap_spikes_cleared','trap_rock_idle','trap_rock_falling','trap_rock_released',
          'trap_fog_idle','trap_fog_active','trap_fog_cleared']
    assert len(boxes) == len(nm), (len(boxes), len(nm))
    for b, n in zip(boxes, nm): save(S, b, 'p5_enemies', f'p5_concept_ch01_{n}', 35)
    # ── P2 همراه‌ها (ترتیب خواندن؛ ۱۵ قطعه، قطعهٔ ۱۱ ضایعات است)
    S = f'{R}/p2_companions/sheet_companions_v1.png'
    bx = comps(S, 40, 6, 12000); assert len(bx) == 15, len(bx)
    bx = sorted(bx, key=lambda b: (b[0] > 1850, b[0] // 700 if b[0] <= 1850 else 0, b[1]))
    names = ['pilo_walk','pilo_sit_open','pilo_idle','pilo_walk_b','pilo_happy','pilo_sleep','pilo_stand','pilo_jump','pilo_dash','fx_pilo_clock',None,
             'bargak_form0_egg','bargak_form1','bargak_form2','bargak_form3']
    for b, n in zip(bx, names):
        if n: save(S, b, 'p2_companions', f'p2_companion_{n}_concept', 35)
    # ── P1 آرسام
    S = f'{R}/p1_heroes/sheet_arsam_poses_v1.png'
    bx = reading_order(comps(S, 40, 6, 20000), [(0,740),(740,1536)]); print('arsam comps', len(bx))
    pn = ['run','jump','crouch','roll','aim','special_shot','hurt','victory']
    for b, n in zip(bx, pn): save(S, b, 'p1_heroes', f'p1_hero_arsam_{n}_concept', 35)
    print(len(made), 'files')

if __name__ == '__main__': main()
