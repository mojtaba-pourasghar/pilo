#!/usr/bin/env python3
"""فهرست دارایی‌های هنری (manifest) را می‌سازد: assets/manifest/assets.csv
اجرا: python3 tools/art/build_asset_manifest.py
هر ردیف = یک فایل نهایی که باید در assets/art/<part>/... قرار گیرد. ستون status: todo|draft|final.
نام‌گذاری: <پارت>_<دسته>_<نام>_<حالت>[_<شکل/سطح>]  (ASCII، حروف کوچک، زیرخط)
"""
import csv, os
OUT = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'manifest', 'assets.csv')
rows = []
def add(part, aid, fa, cat, spec, size, note=''):
    rows.append(dict(id=aid, part=part, name_fa=fa, category=cat, spec=spec, size=size,
                     path=f'assets/art/{part}/{aid}.png', status='todo', note=note))

HEROES = [('arsam','آرسام'),('mahak','ماهک'),('golnar','گل‌نار'),('simin','سیمین'),('ghobarak','غبارک'),
 ('arash','آرش'),('nava','نوا'),('saatak','ساعتک'),('shahsaye','شاه‌سایه'),('azar','آذر'),('setare','ستاره'),('zarvan','زروان')]
HERO_STATES = ['idle','walk','run','jump_up','jump_peak','land','slide','dodge','attack1','attack2','attack3','charge','air_attack',
 'special','hurt','down','win','tired','idle2','idle3','lens','ride_companion','sit_bench']
HERO_UNIQUE = {'arsam':['look_short','hug_bow'],'mahak':['swim','dive'],'golnar':['ribbon_spin','sand_slide'],'simin':['ice_dash','wall_claw'],
 'ghobarak':['fly','scatter'],'arash':['wall_jump','hook'],'nava':['listen','dark_sight'],'saatak':['roll','repair'],
 'shahsaye':['shadow_step','cloak'],'azar':['ground_pound','smash'],'setare':['float','star_path'],'zarvan':['gravity_flip','time_stop']}
# پارت ۱: قهرمان‌ها (حالت‌ها + افکت + چهره/پرتره)
for h,fa in HEROES:
    for s in HERO_STATES + HERO_UNIQUE[h]:
        add('p1_heroes', f'p1_hero_{h}_{s}', f'{fa} — {s}', 'hero_state', 'spritesheet 6-12 frames', '256x256')
    for e in ['portrait_neutral','portrait_happy','portrait_sad','portrait_surprised','portrait_angry','portrait_tired','icon','card','turnaround_front','turnaround_side','turnaround_back']:
        add('p1_heroes', f'p1_hero_{h}_{e}', f'{fa} — {e}', 'hero_sheet', 'single image', '512x512')
    add('p1_heroes', f'p1_fx_power_{h}', f'افکت توان {fa}', 'hero_fx', 'spritesheet 8-12 frames', '512x512')

COMP = [('pilo','پیلو'),('bargak','برگک'),('habbabak','حبابک'),('shenijan','شنی‌جان'),('barfak','برفک'),('abrak','ابرک'),('sekkehkhor','سکه‌خور'),
 ('tupoli','توپولی'),('gandomak','گندمک'),('charkhi','چرخی'),('johark','جوهرک'),('sayejan','سایه‌جان'),('shoolejan','شعله‌جان'),('setarejan','ستاره‌جان'),('varunak','وارونک'),('qalbak','قلب‌ک')]
COMP_STATES = ['idle','walk','jump','command','happy','tired','sleep','eat','follow_hero','fight_assist','hatch','evolve']
for c,fa in COMP:
    for form in (1,2,3):
        for s in COMP_STATES:
            add('p2_companions', f'p2_comp_{c}_f{form}_{s}', f'{fa} شکل {form} — {s}', 'companion_state', 'spritesheet 6-8 frames', '192x192')
        add('p2_companions', f'p2_comp_{c}_f{form}_card', f'{fa} شکل {form} — کارت', 'companion_sheet', 'single', '512x512')
    add('p2_companions', f'p2_fx_cmd_{c}', f'افکت فرمان {fa}', 'companion_fx', 'spritesheet 6 frames', '384x384')
    add('p2_companions', f'p2_comp_{c}_egg', f'تخم {fa}', 'companion_sheet', 'single', '256x256')
    for slot in ['hat','necklace','wing_tail','badge']:
        add('p2_companions', f'p2_gear_{c}_{slot}', f'تجهیز {fa} — {slot}', 'companion_gear', 'overlay', '192x192')
    add('p2_companions', f'p2_comp_{c}_harmony', f'هم‌نوایی {fa}', 'companion_state', 'spritesheet 8 frames', '256x256')

TOOLS = [('quiver','تیرکمان‌پشتی'),('mirror','آینه'),('rope','طناب'),('smoke','بمب دودی'),('lantern','فانوس'),('shield','سپر کوچک'),
 ('hook','قلاب'),('ice_orb','مهرهٔ یخ'),('flame_orb','مهرهٔ شعله'),('wind_key','کوک'),('map','نقشهٔ راهنما'),('pocketwatch','ساعت جیبی')]
for t,fa in TOOLS:
    for lv in range(1,6):
        add('p3_tools', f'p3_tool_{t}_icon_l{lv}', f'{fa} — آیکون سطح {lv}', 'tool_icon', 'icon', '128x128')
    add('p3_tools', f'p3_tool_{t}_use', f'{fa} — استفاده', 'tool_anim', 'spritesheet 6-8', '256x256')
    add('p3_tools', f'p3_tool_{t}_world', f'{fa} — در دنیا', 'tool_world', 'single', '128x128')
    add('p3_tools', f'p3_fx_tool_{t}', f'افکت {fa}', 'tool_fx', 'spritesheet 6-8', '384x384')

BASE_W = [('bow','تیرکمان'),('wood_sword','شمشیر چوبی'),('club','چماق'),('spear','نیزه'),('sling','فلاخن')]
SPEC_W = [('lens_bow','کمان لنز'),('coral_spear','نیزهٔ مرجانی'),('wind_ribbon','روبان باد'),('dawn_blade','تیغهٔ سپیده'),('dust_bag','کیسهٔ غبار'),
 ('trap_kit','کیف تله'),('crystal_flute','نای بلور'),('toolbox','جعبه‌ابزار'),('night_sword','شمشیر شب'),('azar_hammer','چکش آذر'),('star_thrower','ستاره‌پران'),('reverse_hand','عقربهٔ وارونه')]
for w,fa in BASE_W:
    for lv in (1,2,3):
        add('p4_weapons', f'p4_wpn_{w}_l{lv}_icon', f'{fa} سطح {lv} — آیکون', 'weapon_icon', 'icon', '256x256')
        add('p4_weapons', f'p4_wpn_{w}_l{lv}_held', f'{fa} سطح {lv} — در دست', 'weapon_held', 'overlay', '256x256')
    add('p4_weapons', f'p4_fx_wpn_{w}', f'افکت {fa}', 'weapon_fx', 'spritesheet 6', '384x384')
for w,fa in SPEC_W:
    for lv in range(1,6):
        add('p4_weapons', f'p4_wpn_{w}_l{lv}_icon', f'{fa} سطح {lv} — آیکون', 'weapon_icon', 'icon', '256x256')
        add('p4_weapons', f'p4_wpn_{w}_l{lv}_held', f'{fa} سطح {lv} — در دست', 'weapon_held', 'overlay', '256x256')
    for a in ('swing','charged','air'):
        add('p4_weapons', f'p4_fx_wpn_{w}_{a}', f'افکت {fa} — {a}', 'weapon_fx', 'spritesheet 6-8', '512x512')
for m in ['arrow_star','arrow_feather','arrow_heart','arrow_clock','arrow_meteor','mod_slow','mod_chain','mod_return','mod_two_times','mod_reflect','mod_seek','mod_light','mod_heartly']:
    add('p4_weapons', f'p4_mod_{m}', f'مود {m}', 'mod_icon', 'icon', '128x128')

ENEMIES = ['saye_panje','parvane_dud','ghareh_khar','khorchang_dar','arousak_khab','sadaf_paran','aghrab_sheni','saye_sarab','nakhl_raghas',
 'penguin_leez','ghandil_oftade','gorg_meh','abr_raadi','badbadak_khashen','sakku_shabah','tarazu_ban','dozdak','ghofl_zard','bolur_khor','khofash_bolur',
 'saye_ghar','mosh_charkh','tasme_kaj','avang_tiz','harf_parvane','johar_leez','safhe_tigh','saye_velgard','zanjir_negahban','parcham_khan',
 'zob_pare','chakosh_kuchak','jaragheh_khar','shahab_paran','setare_khofte','saye_shab','vareneh_pa','saat_shekaste','ayene_paran','pazhvak_zaman','dast_aghrabe','ghobar_saat']
for e in ENEMIES:
    for s in ['idle','walk','alert','attack_tell','attack','hurt','release','spawn']:
        add('p5_enemies', f'p5_enemy_{e}_{s}', f'دشمن {e} — {s}', 'enemy_state', 'spritesheet 4-8', '192x192')
for k in range(1,13):
    for s in ['idle','alert','tell','attack','vulnerable','hurt','release','secret_sign']:
        add('p5_enemies', f'p5_keeper_k{k}_{s}', f'پاسدار K{k} — {s}', 'keeper_state', 'spritesheet 6-8', '256x256')
GUARDS = ['old_bear','big_octopus','sand_worm','ice_giant','storm_eagle','lock_keeper','crystal_spider','village_statue','grandpa_cursed',
 'librarian','shadow_king','fire_furnace','clock_crow','zarvan_battle1','zarvan_final']
for g in GUARDS:
    for s in ['idle','walk','phase1_attack_a','phase1_attack_b','phase2_attack_a','phase2_attack_b','phase3_attack_a','phase3_attack_b','phase_change','weak_point','hurt','flashback','release','portrait']:
        add('p5_enemies', f'p5_boss_{g}_{s}', f'نگهبان {g} — {s}', 'boss_state', 'spritesheet 8-12', '512x512')
for t in ['spikes','hidden_spikes','pendulum','fire_vent','gear','falling_rock','ice_slick','poison_water','fog','time_trap','two_time_trap']:
    add('p5_enemies', f'p5_trap_{t}', f'دام {t}', 'trap', 'spritesheet 4-8', '192x192')

CH = [('ch01','forest','جنگل رنگارستان'),('ch02','coast','ساحل مرجانی'),('ch03','desert','بیابان طلایی'),('ch04','mountain','کوهستان برفی'),('ch05','sky','جزیره‌های آسمانی'),
 ('ch06','bazaar','بازار قدیم'),('ch07','crystal_cave','غارهای بلور'),('ch08','sabzdare','سبزدره'),('ch09','clock_factory','کارخانهٔ ساعت'),('ch10','library','کتابخانه'),
 ('ch11','shadow_castle','قلعهٔ سایه'),('ch12','fire_forge','کارگاه آتش'),('ch13','star_sea','دریای ستارگان'),('ch14','inverted','سرزمین وارونه'),('ch15','clock_heart','قلب ساعت')]
for cid,en,fa in CH:
    pri = 'v1' if cid in ('ch01',) else 'later'
    for t in ('past','present'):
        for layer in ('far','mid','near','sky'):
            add('p6_scenes', f'p6_{cid}_{en}_{t}_{layer}', f'{fa} — {t} — لایه {layer}', 'scene_layer', 'parallax 2048x720', '2048x720', pri)
        add('p6_scenes', f'p6_{cid}_{en}_{t}_tiles', f'{fa} — {t} — کاشی', 'tileset', 'tileset 64px', '1024x1024', pri)
    add('p6_scenes', f'p6_{cid}_{en}_card', f'{fa} — کارت فصل', 'chapter_card', 'single', '1280x720', pri)
    for i in range(1,9):
        add('p6_scenes', f'p6_{cid}_{en}_l{i}_background', f'{fa} — مرحله {i} پس‌زمینه', 'level_bg', 'single', '1280x720', pri)
for sname in ['hub_village','hub_workshop','hub_nest','hub_shop','hub_library','hub_bench','memory_room','keeper_arena_generic']:
    add('p6_scenes', f'p6_{sname}', f'صحنه {sname}', 'scene', 'single/layers', '1280x720')

LIVING_CH1 = ['leaf_fall','bird_fly','butterfly','waterfall_flow','water_ripple','mushroom_glow','grass_sway','tree_sway','firefly','cloud_move','sun_rays','squirrel','fish_jump','vine_swing','dust_motes','stream_flow','flower_bloom','sleeping_bear_breath','pilo_nest','signpost_glow']
for l in LIVING_CH1:
    for t in ('past','present'):
        add('p7_living', f'p7_ch01_{l}_{t}', f'زنده فصل ۱ — {l} — {t}', 'living_loop', 'loop spritesheet 8-16', '256x256', 'v1')
for cid,en,fa in CH[1:]:
    add('p7_living', f'p7_{cid}_{en}_living_list', f'فهرست زنده‌ها {fa}', 'living_list', 'doc', '-', 'later')

FX_GROUPS = ['time','key','element','hero_power','companion_cmd','weapon','tool','enemy','keeper','boss','environment_ch01','ui']
FX_IDS = {'time':['lens','ghost','soft_return','block','charge','clock_small','key_pick','key_hint','gate_open','ghost_race','station','echo','butterfly','flashback'],
 'key':['past_key','present_key','gate_lock'],'element':['fire','water','plant','wind','light','shadow','weak','resist'],
 'enemy':['tell','hit','release'],'keeper':['secret','release'],'boss':['phase','weak','release'],
 'ui':['coin','gem','heart','star','chest','reward','upgrade','mod','hatch','evolve','harmony','level_up','button','unlock','ending']}
for g,ids in FX_IDS.items():
    for i in ids:
        add('p8_fx', f'p8_fx_{g}_{i}', f'افکت {g}/{i}', 'fx', 'spritesheet', '512x512')
for h,fa in HEROES:
    pass  # افکت توان قهرمان‌ها در p1
for o in ['door','gate','key_pedestal','chest','coin','gem','heart','star','egg','clock_small','bench','lens_pickup','checkpoint','sign','crate','switch','bridge','platform','spring','vine','crystal','torch','banner','mirror_world','memory_orb','heart_piece']:
    add('p8_fx', f'p8_obj_{o}', f'شیء صحنه {o}', 'scene_object', 'sprites + states', '256x256')

SCREENS = ['title','name_entry','hub','chapter_map','chapter_preview','level_list','level_prep','hud_level','hud_boss','result','memory_room','hero_hall','nest','workshop','shop','chest','daily','rivals','midtime_door','tribe','endless_tower','rifts','library','endings','settings','pause_lose','weapon_warning']
for s in SCREENS:
    add('p9_ui', f'p9_screen_{s}', f'صفحه {s}', 'screen_design', 'mockup 1280x720 + اجزا', '1280x720', 'wait_owner')
for u in ['button_primary','button_secondary','button_icon','panel','ribbon','frame_card','heart_bar','coin_pill','gem_pill','tab','toggle','slider','badge','star_icon','lock','arrow','close','popup','toast','progress_bar','lens_charge_bar','key_slot','companion_slot','tool_slot']:
    add('p9_ui', f'p9_kit_{u}', f'کیت رابط {u}', 'ui_kit', 'nine-slice/sprite', 'varies', 'wait_owner')

for cid,en,fa in CH:
    add('p10_preview', f'p10_preview_{cid}', f'انیمیشن پیش‌نمایش {fa}', 'chapter_preview', 'video/anim 8-12s 1280x720', '1280x720', 'v1' if cid=='ch01' else 'later')
    add('p10_preview', f'p10_story_{cid}_storyboard', f'استوری‌بورد داستان {fa}', 'storyboard', '6-12 panels', '1280x720', 'v1' if cid=='ch01' else 'later')

# اولویت: P0 = برش عمودی فصل ۱؛ P1 = پردهٔ ۱ (فصل ۱–۵)؛ P2 = بقیه
P0_HERO={'arsam'}; P1_HERO={'arsam','mahak','golnar','simin','ghobarak'}
P0_COMP={'pilo','bargak'}; P1_COMP={'pilo','bargak','habbabak','shenijan','barfak','abrak'}
P0_TOOL={'quiver','lantern','shield'}; P1_TOOL={'quiver','lantern','shield','rope','mirror','flame_orb','ice_orb','smoke'}
P0_W={'bow','sling','wood_sword','lens_bow'}; P1_W=P0_W|{'club','spear','coral_spear','wind_ribbon','dawn_blade','dust_bag'}
P0_EN={'saye_panje','parvane_dud','ghareh_khar'}; P1_EN=P0_EN|{'khorchang_dar','arousak_khab','sadaf_paran','aghrab_sheni','saye_sarab','nakhl_raghas','penguin_leez','ghandil_oftade','gorg_meh','abr_raadi','badbadak_khashen','sakku_shabah'}
P0_K={1,2,4,8,11,12}; P1_K=set(range(1,13)); P0_B={'old_bear'}; P1_B={'old_bear','big_octopus','sand_worm','ice_giant','storm_eagle'}
def prio(r):
    i=r['id']; part=r['part']
    if part=='p9_ui': return 'P0' if r['category']=='ui_kit' or any(x in i for x in ('title','name_entry','hub','chapter_map','level_list','level_prep','hud_level','hud_boss','result','pause_lose')) else 'P1'
    if part=='p1_heroes':
        h=i.split('_')[2]; return 'P0' if h in P0_HERO else ('P1' if h in P1_HERO else 'P2')
    if part=='p2_companions':
        c=i.split('_')[2]; return 'P0' if c in P0_COMP else ('P1' if c in P1_COMP else 'P2')
    if part=='p3_tools':
        t=i.split('_',2)[2].rsplit('_',1)[0] if '_fx_' not in i else i.split('p3_fx_tool_')[-1]
        for k in P0_TOOL:
            if k in i: return 'P0'
        for k in P1_TOOL:
            if k in i: return 'P1'
        return 'P2'
    if part=='p4_weapons':
        for k in P0_W:
            if f'_{k}_' in i or i.endswith('_'+k): return 'P0'
        for k in P1_W:
            if f'_{k}_' in i or i.endswith('_'+k): return 'P1'
        return 'P2'
    if part=='p5_enemies':
        if '_enemy_' in i:
            e=i.split('p5_enemy_')[1].rsplit('_',1)[0]
            for k in P0_EN:
                if e.startswith(k): return 'P0'
            for k in P1_EN:
                if e.startswith(k): return 'P1'
            return 'P2'
        if '_keeper_k' in i:
            k=int(i.split('keeper_k')[1].split('_')[0]); return 'P0' if k in P0_K else 'P1'
        if '_boss_' in i:
            for k in P0_B:
                if k in i: return 'P0'
            for k in P1_B:
                if k in i: return 'P1'
            return 'P2'
        return 'P0' if any(x in i for x in ('spikes','falling_rock','fog')) else 'P1'
    if part in ('p6_scenes','p7_living','p10_preview','p11_story'):
        if '_ch01_' in i or i.startswith('p10_') and 'ch01' in i or i.startswith('p6_hub') or i.startswith('p6_memory'): return 'P0'
        for c in ('ch02','ch03','ch04','ch05'):
            if f'_{c}_' in i or i.endswith(c): return 'P1'
        return 'P2'
    if part=='p8_fx':
        return 'P0' if any(x in i for x in ('time_','element_','key_','_obj_','ui_coin','ui_heart','ui_star','enemy_','keeper_','boss_')) else 'P1'
    return 'P2'
# پارت ۱۱: صحنه‌ها و انیمیشن داستان‌سرایی (کات‌سین‌ها)
for cid,en,fa in CH:
    n = 14 if cid=='ch01' else 8
    for i in range(1,n+1):
        add('p11_story', f'p11_story_{cid}_scene{i:02d}', f'صحنهٔ داستان {fa} — {i}', 'story_scene', 'illustration 1280x720 (+layers)', '1280x720', 'v1' if cid=='ch01' else 'later')
    add('p11_story', f'p11_story_{cid}_anim', f'انیمیشن داستان {fa}', 'story_anim', 'frames/tween sheet', '1280x720', 'v1' if cid=='ch01' else 'later')
for r in rows: r['priority']=prio(r)
os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT,'w',encoding='utf-8',newline='') as f:
    w = csv.DictWriter(f, fieldnames=['id','part','priority','name_fa','category','spec','size','path','status','note'])
    w.writeheader(); w.writerows(rows)
from collections import Counter
c = Counter(r['part'] for r in rows)
print(len(rows), dict(c)); print(Counter(r['priority'] for r in rows))
