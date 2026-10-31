import sys, wave, subprocess, os
import numpy as np
R = sys.argv[1]; TMP = sys.argv[2]
SR = 22050
rng = np.random.default_rng(7)
def t(d): return np.arange(int(SR*d))/SR
def env(n, a=0.01, r=0.1):
    e = np.ones(n); na=int(SR*a); nr=int(SR*r)
    if na: e[:na]=np.linspace(0,1,na)
    if nr: e[-nr:]*=np.linspace(1,0,nr)
    return e
def tone(f, d, kind='sine', a=0.005, r=None, vol=0.5):
    x = t(d)
    ph = 2*np.pi*np.cumsum(np.broadcast_to(f, x.shape))/SR if np.ndim(f) else 2*np.pi*f*x
    if kind=='sine': y=np.sin(ph)
    elif kind=='tri': y=2/np.pi*np.arcsin(np.sin(ph))
    elif kind=='sq': y=np.sign(np.sin(ph))*0.5
    elif kind=='bell': y=np.sin(ph)+0.4*np.sin(2.76*ph)+0.2*np.sin(5.4*ph)
    elif kind=='marimba': y=np.sin(ph)+0.3*np.sin(4*ph)
    y = y*env(len(x), a, r if r is not None else d*0.9)
    if kind in ('bell','marimba'): y*=np.exp(-x*(6 if kind=='marimba' else 3))
    return y*vol
def cat(*ys): return np.concatenate(ys)
def mix(*ys):
    n=max(len(y) for y in ys); o=np.zeros(n)
    for y in ys: o[:len(y)]+=y
    return o
def at(y, off, n=None):
    o=np.zeros(int(SR*off)+len(y) if n is None else n); s=int(SR*off); o[s:s+len(y)]+=y[:len(o)-s]; return o
ONLY = set(filter(None, os.environ.get("ONLY", "").split(",")))   # ONLY=a,b: write just these
def write(name, y, folder):
    if ONLY and name not in ONLY:
        return
    y = y/ max(1e-6, np.max(np.abs(y))) * 0.85
    w = os.path.join(TMP, name+'.wav')
    with wave.open(w,'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(SR); f.writeframes((y*32767).astype(np.int16).tobytes())
    subprocess.run(['ffmpeg','-y','-loglevel','error','-i',w,'-c:a','libvorbis','-q:a','4',f'{R}/assets/audio/{folder}/{name}.ogg'],check=True)
def noise(d): return rng.uniform(-1,1,int(SR*d))
def lowpass(y, k):
    return np.convolve(y, np.ones(k)/k, mode='same')
sfx = {}
sfx['jump'] = tone(np.linspace(380,760,int(SR*0.16)), 0.16, 'tri', r=0.08)
sfx['land'] = lowpass(noise(0.09),30)*env(int(SR*0.09),0.002,0.08)*1.5 + tone(np.linspace(160,90,int(SR*0.09)),0.09,'sine',vol=0.6)
sfx['star'] = mix(*[at(tone(f,0.25,'bell',vol=0.4),i*0.07) for i,f in enumerate((988,1319,1568,1976))])
sfx['shift'] = mix(lowpass(noise(0.6),12)*np.sin(np.linspace(0,np.pi,int(SR*0.6)))*0.8,
                   tone(np.concatenate([np.linspace(300,900,int(SR*0.3)),np.linspace(900,450,int(SR*0.3))]),0.6,'sine',vol=0.35),
                   at(tone(1760,0.4,'bell',vol=0.25),0.25))
sfx['reject'] = cat(tone(220,0.12,'tri',vol=0.5), np.zeros(int(SR*0.04)), tone(175,0.18,'tri',vol=0.5))
sfx['key'] = mix(at(tone(1175,0.3,'bell',vol=0.4),0), at(tone(1568,0.4,'bell',vol=0.4),0.1))
sfx['door'] = cat(tone(np.linspace(140,300,int(SR*0.35)),0.35,'tri',vol=0.4), tone(600,0.3,'bell',vol=0.3))
sfx['respawn'] = mix(*[at(tone(f,0.3,'sine',vol=0.35),i*0.09) for i,f in enumerate((660,523,440))])
sfx['win'] = mix(*[at(tone(f,0.45 if i<5 else 0.9,'marimba',vol=0.5),i*0.12) for i,f in enumerate((523,659,784,1047,784,1047))], at(tone(1568,1.0,'bell',vol=0.2),0.6))
sfx['click'] = tone(880,0.06,'sine',r=0.05,vol=0.4)
sfx['bounce'] = tone(200+200*np.abs(np.sin(np.linspace(0,9,int(SR*0.35))))*np.linspace(1.5,0.5,int(SR*0.35)),0.35,'tri',vol=0.5)
sfx['rescue'] = mix(*[at(tone(f,0.35,'bell',vol=0.35),i*0.08) for i,f in enumerate((784,988,1175,1568,1976))])
sfx['splash'] = lowpass(noise(0.4),6)*env(int(SR*0.4),0.005,0.35)

# --- environment & character effects (separate RNG so the sounds above stay identical) ---
rng2 = np.random.default_rng(21)
def noise2(d): return rng2.uniform(-1, 1, int(SR*d))
def bp(y, lo_k, hi_k):  # crude band-pass: low-passed minus a wider low-pass
    return lowpass(y, lo_k) - lowpass(y, hi_k)
def decay(n, rate): return np.exp(-np.arange(n)/SR*rate)
# soft footstep on grass: short filtered noise thump + tiny crunch
n = int(SR*0.12)
sfx['step'] = (lowpass(noise2(0.12), 18)*decay(n, 40)*1.4 + bp(noise2(0.12), 3, 9)*decay(n, 70)*0.6) * env(n, 0.003, 0.05)
# vines growing: rising rustle with leafy flutter
n = int(SR*0.7)
flutter = 0.6 + 0.4*np.sin(2*np.pi*np.linspace(6, 22, n).cumsum()/SR)
sfx['grow'] = mix(bp(noise2(0.7), 2, 7)*flutter*np.linspace(0.2, 1, n)*env(n, 0.05, 0.25),
                  tone(np.linspace(300, 900, n), 0.7, 'sine', vol=0.12))
# leaves rustling away (vines folding back into seeds)
n = int(SR*0.5)
sfx['rustle'] = bp(noise2(0.5), 2, 6)*(0.5+0.5*np.sin(np.linspace(0, 30, n)))*np.linspace(1, 0.2, n)*env(n, 0.01, 0.2)
# rocks: low rumble with a few knocks
n = int(SR*0.8)
rumble = lowpass(noise2(0.8), 120)*decay(n, 4)*6
knocks = mix(*[at(lowpass(noise2(0.06), 10)*decay(int(SR*0.06), 60)*1.5, t0) for t0 in (0.05, 0.22, 0.41)])
sfx['rumble'] = mix(rumble, knocks, tone(np.linspace(70, 45, n), 0.8, 'sine', vol=0.35)*decay(n, 3))
# wooden bridge creak: slow pitch-wobbling sawtooth-ish groan, band-limited
n = int(SR*0.6)
f = 140 + 40*np.sin(np.linspace(0, 7, n)) + rng2.uniform(-8, 8, n)
ph = 2*np.pi*np.cumsum(f)/SR
creak = (np.sign(np.sin(ph))*0.5 + 0.5*np.sin(3*ph)) * (0.4 + 0.6*np.abs(np.sin(np.linspace(0, 9, n))))
sfx['creak'] = lowpass(creak, 6)*env(n, 0.03, 0.2)*0.7
# Ghubarak giggle: quick descending hee-hee-hee with vibrato
parts = []
for i, f0 in enumerate((980, 900, 820, 760, 700)):
    d = 0.09
    m = int(SR*d)
    vib = f0*(1 + 0.03*np.sin(2*np.pi*28*np.arange(m)/SR))
    parts.append(at(tone(vib, d, 'tri', a=0.005, r=0.05, vol=0.45) + bp(noise2(d), 2, 5)*0.08, i*0.11))
sfx['giggle'] = mix(*parts)
# squirrel chatter: fast high chirps
sfx['chatter'] = mix(*[at(tone(np.linspace(2200, 1500, int(SR*0.05)), 0.05, 'sine', vol=0.35), i*0.065 + (0.02 if i % 3 == 0 else 0)) for i in range(9)])
# bubble pop (time bubble around the friend)
n = int(SR*0.18)
sfx['pop'] = mix(tone(np.linspace(500, 1400, n), 0.18, 'sine', a=0.002, r=0.12, vol=0.5)*decay(n, 18), bp(noise2(0.18), 1, 4)*decay(n, 60)*0.5)
# checkpoint flag: two cloth flaps
flap = lambda: bp(noise2(0.12), 2, 10)*env(int(SR*0.12), 0.01, 0.08)*1.2
sfx['flag'] = mix(at(flap(), 0), at(flap(), 0.16))
# --- platformer effects (own RNG so the sounds above stay identical) ---
rng3 = np.random.default_rng(33)
def noise3(d): return rng3.uniform(-1, 1, int(SR*d))
sfx['coin'] = cat(tone(988, 0.06, 'sq', a=0.002, r=0.01, vol=0.3), tone(1319, 0.28, 'sq', a=0.002, r=0.25, vol=0.3)*decay(int(SR*0.28), 9))
sfx['diamond'] = mix(*[at(tone(f, 0.35, 'bell', vol=0.35), i*0.05) for i, f in enumerate((1568, 2093, 2637, 3136, 2637))])
n = int(SR*0.22)
sfx['stomp'] = mix(tone(np.linspace(520, 180, n), 0.22, 'tri', a=0.002, r=0.1, vol=0.55), lowpass(noise3(0.22), 8)*decay(n, 30)*0.8)
n = int(SR*0.45)
sfx['hurt'] = tone(np.linspace(620, 260, n)*(1 + 0.05*np.sin(np.linspace(0, 60, n))), 0.45, 'tri', a=0.005, r=0.2, vol=0.5)
n = int(SR*0.35)
sfx['brick'] = mix(*[at(bp(noise3(0.12), 2, 9)*decay(int(SR*0.12), 25)*1.4, t0) for t0 in (0.0, 0.05, 0.11, 0.2)], tone(np.linspace(220, 120, n), 0.35, 'sine', vol=0.3)*decay(n, 8))
n = int(SR*0.12)
sfx['bump'] = mix(tone(np.linspace(240, 140, n), 0.12, 'sine', a=0.002, r=0.08, vol=0.7), lowpass(noise3(0.12), 14)*decay(n, 40))
n = int(SR*0.3)
sfx['dash'] = bp(noise3(0.3), 2, 12)*np.sin(np.linspace(0, np.pi, n))**2*1.6
n = int(SR*0.55)
sfx['pipe'] = tone(np.linspace(700, 180, n)*(1 + 0.12*np.sign(np.sin(np.linspace(0, 70, n)))), 0.55, 'sq', a=0.005, r=0.1, vol=0.25)
sfx['heart'] = mix(*[at(tone(f, 0.3, 'marimba', vol=0.5), i*0.08) for i, f in enumerate((659, 880, 1047, 1319))])
n = int(SR*0.5)
sfx['cannon'] = mix(lowpass(noise3(0.5), 40)*decay(n, 9)*5, tone(np.linspace(110, 50, n), 0.5, 'sine', vol=0.6)*decay(n, 7))
n = int(SR*0.4)
sfx['thud'] = mix(lowpass(noise3(0.4), 90)*decay(n, 12)*6, tone(np.linspace(80, 40, n), 0.4, 'sine', vol=0.7)*decay(n, 10))
sfx['free'] = mix(*[at(tone(f, 0.4, 'bell', vol=0.3), i*0.06) for i, f in enumerate((1047, 1319, 1568, 2093))], at(bp(noise3(0.3), 1, 3)*decay(int(SR*0.3), 12)*0.3, 0.0))
# --- impacts, weather and body effects (own RNG so the sounds above stay identical) ---
rng4 = np.random.default_rng(47)
def noise4(d): return rng4.uniform(-1, 1, int(SR*d))
# heavy hit: deep punch, a cracking click and a short tail
n = int(SR*0.45)
sfx['impact'] = mix(tone(np.linspace(150, 45, n), 0.45, 'sine', a=0.001, r=0.3, vol=0.9)*decay(n, 7),
                    lowpass(noise4(0.45), 25)*decay(n, 14)*2.0, bp(noise4(0.05), 1, 4)*decay(int(SR*0.05), 80)*1.2)
# swish of air (dash, swings, gusts)
n = int(SR*0.35)
sfx['whoosh'] = bp(noise4(0.35), 3, 18)*np.sin(np.linspace(0, np.pi, n))**3*2.2
# catching fire: a whoomp, then crackles
n = int(SR*1.2)
crackle = np.zeros(n)
for _ in range(60):
    m = int(SR*rng4.uniform(0.003, 0.012)); o = int(rng4.uniform(0, n - m))
    crackle[o:o+m] += rng4.uniform(-1, 1, m)*rng4.uniform(0.3, 1.0)
sfx['fire'] = mix(lowpass(noise4(1.2), 30)*np.concatenate([np.linspace(0, 1, int(SR*0.08)), np.linspace(1, 0.3, n - int(SR*0.08))])*1.5,
                  crackle*decay(n, 1.5)*0.8)
# thunder: a sharp crack rolling into a long low rumble
n = int(SR*2.6)
roll = lowpass(lowpass(noise4(2.6), 150), 60)*(decay(n, 1.2)*(0.6 + 0.4*np.sin(np.linspace(0, 9, n))**2))*14
sfx['thunder'] = mix(bp(noise4(0.25), 1, 6)*decay(int(SR*0.25), 12)*2.5, roll)
# tired panting: two soft breaths
breath = lambda d: bp(noise4(d), 4, 30)*np.sin(np.linspace(0, np.pi, int(SR*d)))**2*1.4
sfx['pant'] = mix(at(breath(0.22), 0.0), at(breath(0.18)*0.8, 0.3))
# hiss of a flame going out
n = int(SR*0.6)
sfx['sizzle'] = bp(noise4(0.6), 1, 3)*decay(n, 5)*0.9
for k,v in sfx.items(): write(k,v,'sfx')
def song(scale, prog, kind, bpm, bars, seed, bass_kind='sine'):
    r = np.random.default_rng(seed); beat = 60/bpm; L = bars*4*beat
    n = int(SR*L); o = np.zeros(n+SR)
    for b in range(bars):
        root = prog[b%len(prog)]
        # bass
        for q in (0,2):
            o += at(tone(root/2, beat*1.8, bass_kind, r=beat, vol=0.35), (b*4+q)*beat, len(o))
        # chord pad
        for f in (root, root*1.25 if b%2==0 else root*1.2, root*1.5):
            o += at(tone(f, beat*4, 'sine', a=0.3, r=1.0, vol=0.06), b*4*beat, len(o))
        # melody
        for e in range(8):
            if r.random() < 0.7:
                f = scale[r.integers(len(scale))]
                o += at(tone(f, beat*0.9, kind, vol=0.28), (b*4+e*0.5)*beat, len(o))
    # wrap tail for seamless loop
    tail = o[n:]; o = o[:n]; o[:len(tail)] += tail
    return o
pent = lambda base: [base*m for m in (1,9/8,5/4,3/2,5/3,2)]
write('forest', song(pent(523), [262,349,392,262,220,349,392,262], 'marimba', 104, 16, 1), 'music')
write('sky', song(pent(587), [294,392,440,330,294,392,440,294], 'tri', 92, 16, 2), 'music')
write('cave', song([440,494,587,659,740,880], [220,294,330,247,220,294,330,220], 'bell', 80, 12, 3), 'music')
# one tune per new world, plus the guardian fights
write('beach', song(pent(659), [330,440,494,330,294,440,494,330], 'marimba', 112, 16, 4), 'music')
write('desert', song([440,466,554,587,659,698,831], [220,233,220,196,220,233,262,220], 'tri', 96, 16, 5), 'music')
write('snow', song(pent(698), [349,466,523,392,349,466,523,349], 'bell', 84, 16, 6), 'music')
write('factory', song([392,440,466,523,587,622,698], [196,233,262,175,196,233,262,196], 'sq', 116, 16, 7, 'tri'), 'music')
write('castle', song([392,415,466,523,554,622,698], [196,207,233,175,196,207,156,196], 'bell', 76, 12, 8), 'music')
write('inverted', song(pent(784), [392,523,587,440,392,523,587,392], 'tri', 88, 16, 9), 'music')
write('boss', song([440,466,523,554,622,659,740], [220,233,262,208,220,233,277,220], 'sq', 136, 16, 10, 'tri'), 'music')
