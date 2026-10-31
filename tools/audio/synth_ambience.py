#!/usr/bin/env python3
"""Synthesised world ambience for Safar-e Pilo (numpy + ffmpeg, no recordings needed).

    python3 tools/audio/synth_ambience.py            # stream, sky, cave
    python3 tools/audio/synth_ambience.py cave

Used for the loops that are not (yet) real recordings; tools/audio/fetch_ambience.py replaces a
file with a Commons recording when one is picked and downloads succeed. Each loop is made
seamless with the same equal-power cross-fade as fetch_ambience.py and written as mono Ogg at a
quiet loudness so it sits under music and voice.

  stream  babbling brook: a soft water bed plus many small bubbling blips
  sky     high-altitude wind with slow gusts and a few distant wind chimes
  cave    big quiet cave: low hum, air, and water drips with a long echo
  rain    steady rain: hiss, patter on leaves and a few close drops
  waves   beach: waves rolling in and washing back, a gull now and then
  desert  hot dry wind with sand and a far buzzing in the heat
  factory clock factory: hum, ticking, steam hisses and clanks
  night   castle night: soft wind, crickets and an owl
"""
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
SR = 44100
FADE = 2.0
rng = np.random.default_rng(1404)


def lowpass(x, cutoff):
    """One-pole low-pass; cutoff may be an array (a moving filter)."""
    cutoff = np.broadcast_to(np.asarray(cutoff, dtype=np.float64), x.shape)
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):  # plain loop: clear and fast enough for a few loops
        acc = a[i] * acc + (1 - a[i]) * x[i]
        y[i] = acc
    return y


def fft_lowpass(x, cutoff, order=2.0):
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    spec *= 1 / np.sqrt(1 + (f / cutoff) ** (2 * order))
    return np.fft.irfft(spec, len(x))


def fft_band(x, lo, hi):
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    spec *= (f > lo) & (f < hi)
    return np.fft.irfft(spec, len(x))


def smooth_random(n, points, lo, hi):
    """A slow random curve between lo and hi (gusts, swells)."""
    xs = np.linspace(0, n, points)
    ys = rng.uniform(lo, hi, points)
    ys[-1] = ys[0]  # ends meet, which helps the loop
    return np.interp(np.arange(n), xs, ys)


def reverb(x, seconds, decay, wet):
    n = int(seconds * SR)
    tail = rng.standard_normal(n) * np.exp(-np.arange(n) / SR * decay)
    tail = fft_lowpass(tail, 3500)
    tail /= np.sqrt((tail ** 2).sum())
    size = len(x) + n
    y = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(tail, size), size)[: len(x) + n]
    # wrap the tail onto the start so the loop's echo continues across the seam
    out = x * (1 - wet) + y[: len(x)] * wet
    out[: n] += y[len(x):] * wet
    return out


def place(buf, clip, at):
    end = min(len(buf), at + len(clip))
    buf[at:end] += clip[: end - at]


def stream(seconds):
    n = int((seconds + FADE) * SR)
    bed = fft_band(rng.standard_normal(n), 300, 3500) * 0.10
    # turbulence: the water's loudness flutters several times a second
    bed *= smooth_random(n, int(seconds * 7), 0.45, 1.0) * smooth_random(n, 30, 0.7, 1.0)
    out = bed
    # bubbles: short sine blips that glide upward, the "plip" of water over stones
    for _ in range(int(seconds * 70)):
        dur = rng.uniform(0.012, 0.045)
        m = int(dur * SR)
        f0 = rng.uniform(450, 1700)
        f = f0 * np.linspace(1, rng.uniform(1.15, 1.6), m)
        clip = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-np.linspace(0, 6, m)) * np.hanning(m) ** 0.3
        place(out, clip * rng.uniform(0.06, 0.28), int(rng.uniform(0, n - m)))
    return reverb(out, 0.35, 12, 0.18)


def sky(seconds):
    n = int((seconds + FADE) * SR)
    noise = rng.standard_normal(n)
    gust = smooth_random(n, int(seconds / 3), 0.25, 1.0) ** 1.5
    cutoff = 250 + 900 * gust
    wind = lowpass(lowpass(noise, cutoff), cutoff) * (0.25 + 0.75 * gust)
    whistle = fft_band(noise, 700, 1300) * gust ** 3 * 0.15
    out = wind * 1.8 + whistle
    # a few distant wind chimes (pentatonic), only when a gust passes
    scale = [1046.5, 1174.7, 1318.5, 1568.0, 1760.0, 2093.0]
    for _ in range(int(seconds / 2.2)):
        at = int(rng.uniform(0, n - SR * 3))
        if gust[at] < 0.5:
            continue
        for k in range(rng.integers(2, 5)):
            f = scale[rng.integers(len(scale))]
            m = int(2.5 * SR)
            t = np.arange(m) / SR
            bell = (np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 2.76 * t)) * np.exp(-t * 2.2)
            place(out, bell * 0.035, at + int(k * rng.uniform(0.12, 0.3) * SR))
    return out


def cave(seconds):
    n = int((seconds + FADE) * SR)
    t = np.arange(n) / SR
    hum = (np.sin(2 * np.pi * 55 * t) * 0.6 + np.sin(2 * np.pi * 82.5 * t) * 0.3) * smooth_random(n, 12, 0.5, 1.0) * 0.05
    air = fft_lowpass(rng.standard_normal(n), 400) * 0.12 * smooth_random(n, 10, 0.6, 1.0)
    drips = np.zeros(n)
    for _ in range(int(seconds * 1.4)):
        m = int(0.09 * SR)
        f0 = rng.uniform(900, 2200)
        f = f0 * np.linspace(1, rng.uniform(1.6, 2.4), m)  # a falling drop rises in pitch
        tt = np.arange(m) / SR
        clip = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt * 45)
        place(drips, clip * rng.uniform(0.15, 0.4), int(rng.uniform(0, n - m)))
    return hum + air + reverb(drips, 2.5, 2.2, 0.55)


def rain(seconds):
    n = int((seconds + FADE) * SR)
    # a dense hiss of drops, a softer patter on leaves and a few close heavy drops
    hiss = fft_band(rng.standard_normal(n), 900, 9000) * 0.2 * smooth_random(n, int(seconds / 2), 0.75, 1.0)
    patter = fft_band(rng.standard_normal(n), 250, 1600) * 0.12
    out = hiss + patter
    for _ in range(int(seconds * 25)):
        m = int(0.02 * SR)
        clip = fft_band(rng.standard_normal(m), 1500, 6000) * np.exp(-np.linspace(0, 8, m))
        place(out, clip * rng.uniform(0.1, 0.35), int(rng.uniform(0, n - m)))
    return reverb(out, 0.6, 6, 0.2)


def waves(seconds):
    n = int((seconds + FADE) * SR)
    t = np.arange(n) / SR
    # waves rolling in every 6-9 seconds, a hiss as they wash back, gulls now and then
    swell = np.zeros(n)
    at = 0.0
    while at < seconds + FADE:
        period = rng.uniform(6, 9)
        k = (t - at) / period
        mask = (k >= 0) & (k < 1)
        swell[mask] += np.sin(np.pi * k[mask]) ** 3
        at += period
    out = fft_band(rng.standard_normal(n), 150, 2500) * (0.08 + 0.5 * swell) + fft_band(rng.standard_normal(n), 2500, 8000) * 0.12 * swell
    for _ in range(int(seconds / 9)):
        m = int(0.5 * SR)
        f = np.linspace(1700, 1100, m) * (1 + 0.04 * np.sin(np.linspace(0, 40, m)))
        clip = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.hanning(m) * 0.03
        place(out, clip, int(rng.uniform(0, n - m)))
    return out


def desert(seconds):
    n = int((seconds + FADE) * SR)
    noise = rng.standard_normal(n)
    gust = smooth_random(n, int(seconds / 4), 0.2, 1.0) ** 1.4
    wind = fft_band(noise, 120, 900) * (0.2 + 0.8 * gust) * 0.6
    sand = fft_band(rng.standard_normal(n), 3000, 9000) * gust ** 2 * 0.1
    # a far cicada-like buzz in the heat
    t = np.arange(n) / SR
    buzz = np.sin(2 * np.pi * 4200 * t) * (0.5 + 0.5 * np.sin(2 * np.pi * 38 * t)) * smooth_random(n, int(seconds / 3), 0.0, 1.0) ** 3 * 0.015
    return wind + sand + buzz


def factory(seconds):
    n = int((seconds + FADE) * SR)
    t = np.arange(n) / SR
    hum = (np.sin(2 * np.pi * 60 * t) * 0.5 + np.sin(2 * np.pi * 120 * t) * 0.2) * 0.05
    out = hum + fft_lowpass(rng.standard_normal(n), 300) * 0.05
    # ticking of big clocks and a clank, a hiss of steam now and then
    for k in range(int(seconds * 2)):
        m = int(0.03 * SR)
        clip = fft_band(rng.standard_normal(m), 1500, 5000) * np.exp(-np.linspace(0, 10, m))
        place(out, clip * 0.25, int(k * 0.5 * SR))
    for _ in range(int(seconds / 5)):
        m = int(1.2 * SR)
        clip = fft_band(rng.standard_normal(m), 2000, 8000) * np.sin(np.linspace(0, np.pi, m)) ** 2 * 0.12
        place(out, clip, int(rng.uniform(0, n - m)))
    for _ in range(int(seconds / 6)):
        m = int(0.4 * SR)
        f = rng.uniform(300, 600)
        tt = np.arange(m) / SR
        clip = (np.sin(2 * np.pi * f * tt) + 0.5 * np.sin(2 * np.pi * f * 2.7 * tt)) * np.exp(-tt * 9) * 0.1
        place(out, clip, int(rng.uniform(0, n - m)))
    return reverb(out, 1.2, 4, 0.3)


def night(seconds):
    n = int((seconds + FADE) * SR)
    t = np.arange(n) / SR
    wind = lowpass(rng.standard_normal(n), 300) * smooth_random(n, int(seconds / 4), 0.2, 1.0) * 0.5
    crickets = np.sin(2 * np.pi * 4600 * t) * (np.sin(2 * np.pi * 30 * t) > 0.3) * (np.sin(2 * np.pi * 0.7 * t) > 0) * 0.02
    out = wind + crickets
    for _ in range(int(seconds / 12)):
        m = int(0.9 * SR)
        tt = np.arange(m) / SR
        hoot = np.sin(2 * np.pi * 380 * tt) * (np.sin(np.pi * np.clip(tt / 0.3, 0, 1)) + np.sin(np.pi * np.clip((tt - 0.45) / 0.4, 0, 1)) * (tt > 0.45)) * 0.05
        place(out, hoot, int(rng.uniform(0, n - m)))
    return reverb(out, 1.5, 3, 0.3)


def write_loop(audio, seconds, lufs, dst):
    fade = int(FADE * SR)
    length = int(seconds * SR)
    t = np.linspace(0, np.pi / 2, fade)
    loop = audio[:length].copy()
    loop[:fade] = audio[:fade] * np.sin(t) + audio[length:length + fade] * np.cos(t)
    loop /= max(1e-6, np.abs(loop).max())
    with tempfile.TemporaryDirectory() as tmp:
        raw = Path(tmp) / "loop.raw"
        loop.astype(np.float32).tofile(raw)
        dst.parent.mkdir(parents=True, exist_ok=True)
        # loudness is measured on the whole loop and then applied as one gain, so the seam stays clean
        probe = subprocess.run(["ffmpeg", "-hide_banner", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", str(raw),
                                "-af", "ebur128", "-f", "null", "-"], capture_output=True, text=True).stderr
        measured = float(probe.rsplit("I:", 1)[1].split("LUFS")[0])
        gain = lufs - measured
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", str(raw),
                        "-af", f"volume={gain}dB,alimiter=limit=0.9", "-c:a", "libvorbis", "-q:a", "4", str(dst)],
                       check=True)


LOOPS = {
    "stream": (stream, 20, -22),
    "sky": (sky, 40, -25),
    "cave": (cave, 40, -24),
    "rain": (rain, 30, -22),
    "waves": (waves, 40, -24),
    "desert": (desert, 40, -25),
    "factory": (factory, 30, -25),
    "night": (night, 40, -26),
}

if __name__ == "__main__":
    names = sys.argv[1:] or list(LOOPS)
    for name in names:
        make, seconds, lufs = LOOPS[name]
        dst = ROOT / "assets/audio/ambient" / f"{name}.ogg"
        write_loop(make(seconds), seconds, lufs, dst)
        print(f"{name}: {dst.relative_to(ROOT)}")
