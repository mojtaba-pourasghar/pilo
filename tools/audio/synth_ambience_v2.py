#!/usr/bin/env python3
"""Ambience built from the events that make each sound, for the loops that won a listening test
against the older synthesised ones (tools/audio/synth_ambience.py):

  rain    dense soft patter on leaves and ground over a dark bed, a few close drops
  desert  warm wind: a low-pass that opens and closes with slow gusts, a faint whistle and sand
  cave    clear water drips with a long, soft cave echo over quiet air

    python3 tools/audio/synth_ambience_v2.py            # all three
    python3 tools/audio/synth_ambience_v2.py cave

Needs numpy and scipy (pip install numpy scipy) and ffmpeg. Each loop is seamless (the same
cross-fade and loudness handling as synth_ambience.py) and written over assets/audio/ambient.
The others stay as they are: their older versions sounded better in the test.
"""
import sys
from pathlib import Path

import numpy as np
from scipy import signal

sys.path.insert(0, str(Path(__file__).resolve().parent))
from synth_ambience import write_loop  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SR = 44100
rng = np.random.default_rng(1404)


def pink(n):
    """1/f noise: much softer than white noise (Voss–McCartney via FFT shaping)."""
    spec = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1 / SR)
    f[0] = f[1]
    spec /= np.sqrt(f)
    x = np.fft.irfft(spec, n)
    return x / np.abs(x).max()

def brown(n):
    spec = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1 / SR)
    f[0] = f[1]
    spec /= f
    x = np.fft.irfft(spec, n)
    return x / np.abs(x).max()

def band(x, lo=None, hi=None, order=4):
    if lo and hi:
        sos = signal.butter(order, [lo, hi], "bandpass", fs=SR, output="sos")
    elif lo:
        sos = signal.butter(order, lo, "highpass", fs=SR, output="sos")
    else:
        sos = signal.butter(order, hi, "lowpass", fs=SR, output="sos")
    return signal.sosfiltfilt(sos, x)

def moving_band(x, centre, q, block=512):
    """A resonant band-pass whose centre frequency follows `centre` (an array): the whistle and
    roar of wind. Filtered block by block with carried state."""
    y = np.zeros_like(x)
    zi = np.zeros((1, 2))
    for s in range(0, len(x), block):
        fc = float(np.clip(centre[s], 40, SR / 2.5))
        b, a = signal.iirpeak(fc, q, fs=SR)
        sos = np.concatenate([b, a])[None, :]
        y[s:s + block], zi = signal.sosfilt(sos, x[s:s + block], zi=zi)
    return y

def slow(n, points, lo, hi, smooth=True):
    """A slow random curve between lo and hi whose ends meet (for the loop)."""
    xs = np.linspace(0, n - 1, points)
    ys = rng.uniform(lo, hi, points)
    ys[-1] = ys[0]
    if smooth:
        from scipy.interpolate import CubicSpline
        return np.clip(CubicSpline(xs, ys, bc_type="periodic")(np.arange(n)), min(lo, hi), max(lo, hi))
    return np.interp(np.arange(n), xs, ys)

def add(buf, clip, at, gain=1.0):
    """Adds a clip at sample `at`, wrapping round the end so the loop has no seam."""
    at %= len(buf)
    end = min(len(buf), at + len(clip))
    buf[at:end] += clip[: end - at] * gain
    rest = len(clip) - (end - at)
    if rest > 0:
        buf[:rest] += clip[end - at:] * gain

def bubble(freq, dur, rise=0.4):
    """A bubble or water drop (Minnaert resonance): a sine whose pitch rises as it decays."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = freq * (1 + rise * t / dur)
    phase = 2 * np.pi * np.cumsum(f) / SR
    env = np.exp(-t / (dur / 4.5)) * (1 - np.exp(-t * 3000))
    return np.sin(phase) * env

def click(dur, lo, hi):
    n = int(dur * SR)
    t = np.arange(n) / SR
    return band(rng.standard_normal(n), lo, hi, 2) * np.exp(-t / (dur / 5))

def room(x, seconds, decay, wet, tone=4000):
    """Convolution with a soft noise tail; the tail wraps onto the start (seamless loop)."""
    n = int(seconds * SR)
    tail = band(rng.standard_normal(n), 80, tone, 2) * np.exp(-np.arange(n) / SR * decay)
    tail /= np.sqrt((tail ** 2).sum())
    size = len(x) + n
    y = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(tail, size), size)
    wetsig = y[: len(x)].copy()
    wetsig[:n] += y[len(x): len(x) + n]
    return x * (1 - wet) + wetsig * wet * 3

def norm(x):
    return x / max(1e-9, np.abs(x).max())

def moving_lowpass(x, cutoff, block=256):
    y = np.zeros_like(x)
    zi = np.zeros((2, 2))
    for s in range(0, len(x), block):
        fc = float(np.clip(cutoff[s], 60, SR / 2.5))
        sos = signal.butter(4, fc, "lowpass", fs=SR, output="sos")
        if s == 0:
            zi = signal.sosfilt_zi(sos) * 0
        y[s:s + block], zi = signal.sosfilt(sos, x[s:s + block], zi=zi)
    return y


def _rain_patter(seconds):
    n = int(seconds * SR)
    bed = band(pink(n), 400, 7000) * slow(n, int(seconds / 3), 0.85, 1.0)
    patter = np.zeros(n)
    for _ in range(int(seconds * 1800)):              # dense patter on leaves and ground
        d = rng.uniform(0.0015, 0.004)
        c = click(d, rng.uniform(1200, 3000), rng.uniform(4000, 9000))
        add(patter, c, rng.integers(n), rng.uniform(0.2, 1.0) ** 2)
    near = np.zeros(n)
    for _ in range(int(seconds * 6)):                 # a few soft close drops
        add(near, click(rng.uniform(0.01, 0.02), 300, 2500), rng.integers(n), rng.uniform(0.3, 0.6))
    out = norm(bed) * 0.6 + norm(patter) * 0.55 + norm(near) * 0.25
    return norm(band(out, 150, 8000))


def rain(seconds):
    return norm(band(_rain_patter(seconds), 120, 4500, 2))


def wind(seconds, low, high, gust_lo, gust_hi, whistle, hiss):
    n = int(seconds * SR)
    gust = slow(n, int(seconds / 3), gust_lo, gust_hi) ** 1.5
    cutoff = low + (high - low) * (gust - gust.min()) / (gust.max() - gust.min() + 1e-9)
    body = moving_lowpass(pink(n), cutoff) * gust
    out = norm(band(body, 60, None, 2))
    if whistle:
        w = moving_band(rng.standard_normal(n), cutoff * 2.2, 30) * np.clip(gust - gust.mean(), 0, None)
        out += norm(w) * whistle
    if hiss:
        out += band(pink(n), 2000, 6000) * gust * hiss
    return norm(out)


def desert(seconds):
    return wind(seconds, 180, 700, 0.2, 1.0, 0.05, 0.05)


def cave(seconds):
    n = int(seconds * SR)
    air = band(pink(n), 200, 1200) * 0.025
    drips = np.zeros(n)
    t = 0.0
    while t < seconds:
        f = rng.choice([780, 880, 990, 1110, 1320]) * rng.uniform(0.98, 1.02)
        add(drips, bubble(f, rng.uniform(0.025, 0.04), 0.35), int(t * SR), rng.uniform(0.4, 0.9))
        t += rng.uniform(0.9, 2.8)
    wet = room(norm(drips), 3.0, 1.8, 0.75, tone=3500)
    return norm(band(air + wet, 150, 9000))


LOOPS = {"rain": (rain, 30, -22), "desert": (desert, 40, -25), "cave": (cave, 40, -24)}

if __name__ == "__main__":
    for name in sys.argv[1:] or list(LOOPS):
        make, seconds, lufs = LOOPS[name]
        audio = make(seconds)
        if len(audio) < int((seconds + 2) * SR):        # the cross-fade needs two seconds past the end
            audio = np.concatenate([audio, audio[: int(2 * SR)]])
        dst = ROOT / "assets/audio/ambient" / f"{name}.ogg"
        write_loop(audio, seconds, lufs, dst)
        print(f"{name}: {dst.relative_to(ROOT)}")
