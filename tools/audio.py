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
def write(name, y, folder):
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
