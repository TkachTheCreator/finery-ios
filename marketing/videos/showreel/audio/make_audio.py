"""
Finery showreel — original soundtrack + sound design, synthesized from scratch.
No samples, no third-party audio: 100% generated here, so no copyright issues.

120 BPM, D minor. 1 beat = 0.5 s = 30 frames at 60 fps.
Every event below is placed on the same beat grid as the video (src/timeline.ts).

Run:  python3 audio/make_audio.py  ->  public/audio/finery_showreel_raw.wav
"""
import numpy as np
from scipy import signal
import wave, os

SR = 48000
BPM = 120
BEAT = 60 / BPM
TOTAL = 29.0
N = int(SR * TOTAL)
rng = np.random.default_rng(7)

L = np.zeros(N)
R = np.zeros(N)
send = np.zeros((2, N))  # reverb send


def b(x):  # beats -> seconds
    return x * BEAT


def place(sig, t, gain=1.0, pan=0.0, rev=0.0):
    """mix a mono or stereo signal at time t (seconds)"""
    i = int(t * SR)
    if i >= N:
        return
    if sig.ndim == 1:
        l = sig * np.sqrt(0.5 * (1 - pan)) * gain
        r = sig * np.sqrt(0.5 * (1 + pan)) * gain
    else:
        l, r = sig[0] * gain, sig[1] * gain
    n = min(len(l), N - i)
    L[i:i + n] += l[:n]
    R[i:i + n] += r[:n]
    if rev:
        send[0, i:i + n] += l[:n] * rev
        send[1, i:i + n] += r[:n] * rev


def tt(d):
    return np.arange(int(d * SR)) / SR


def lp(x, fc, order=2):
    sos = signal.butter(order, min(fc, SR / 2 - 100), 'low', fs=SR, output='sos')
    return signal.sosfilt(sos, x)


def hp(x, fc, order=2):
    sos = signal.butter(order, fc, 'high', fs=SR, output='sos')
    return signal.sosfilt(sos, x)


def bp(x, lo, hi, order=2):
    sos = signal.butter(order, [lo, hi], 'band', fs=SR, output='sos')
    return signal.sosfilt(sos, x)


def sweep_filter(x, f0, f1, kind='low', q=0.9, curve=2.0):
    """time-varying SVF (Chamberlin) — for risers / filter sweeps"""
    n = len(x)
    fc = f0 + (f1 - f0) * (np.linspace(0, 1, n) ** curve)
    f = 2 * np.sin(np.pi * np.clip(fc, 20, SR / 6) / SR)
    low = band = 0.0
    out = np.zeros(n)
    damp = 1 / q
    for k in range(n):
        high = x[k] - low - damp * band
        band += f[k] * high
        low += f[k] * band
        out[k] = low if kind == 'low' else (band if kind == 'band' else high)
    return out


def saw(freq, d, detune=0.0, phase=None):
    t = tt(d)
    ph = rng.random() if phase is None else phase
    return 2 * ((t * freq * (1 + detune) + ph) % 1) - 1


def env_ad(d, a=0.005, dec=0.2, curve=4.0):
    t = tt(d)
    e = np.where(t < a, t / max(a, 1e-6), np.exp(-(t - a) / dec * (curve / 4)))
    return e


def note(n):  # midi -> hz
    return 440 * 2 ** ((n - 69) / 12)


# ---------------------------------------------------------------- instruments
def kick(power=1.0):
    d = 0.5
    t = tt(d)
    f = 45 + 140 * np.exp(-t * 38)
    ph = 2 * np.pi * np.cumsum(f) / SR
    body = np.sin(ph) * np.exp(-t * 6.5)
    click = hp(rng.standard_normal(len(t)), 3000) * np.exp(-t * 400) * 0.35
    x = np.tanh((body + click) * 1.6 * power)
    return x


def clap():
    d = 0.35
    t = tt(d)
    nz = rng.standard_normal(len(t))
    e = np.zeros(len(t))
    for k, off in enumerate([0, 0.011, 0.022]):
        e += np.where(t >= off, np.exp(-(t - off) * (180 if k < 2 else 22)), 0)
    return bp(nz, 900, 4200) * e * 0.9


def hat(open_=False):
    d = 0.3 if open_ else 0.06
    t = tt(d)
    x = hp(rng.standard_normal(len(t)), 7500, 4)
    return x * np.exp(-t * (14 if open_ else 90)) * (0.5 if open_ else 0.45)


def snare_roll_hit():
    d = 0.18
    t = tt(d)
    x = bp(rng.standard_normal(len(t)), 1200, 6000) * np.exp(-t * 28)
    tone = np.sin(2 * np.pi * 190 * t) * np.exp(-t * 40) * 0.5
    return (x + tone) * 0.6


def bass_note(n, d, cutoff=420):
    x = saw(note(n), d, phase=0) * 0.6 + np.sin(2 * np.pi * note(n) * tt(d)) * 0.8
    x = lp(x, cutoff, 2)
    e = env_ad(d, 0.004, d * 0.55)
    e[-int(0.01 * SR):] *= np.linspace(1, 0, int(0.01 * SR))
    return np.tanh(x * e * 1.5) * 0.8


def supersaw(notes, d, cutoff=2600, a=0.004, dec=0.22, voices=5, width=0.6):
    l = np.zeros(int(d * SR))
    r = np.zeros(int(d * SR))
    for n in notes:
        for v in range(voices):
            det = (v - (voices - 1) / 2) * 0.006
            s = saw(note(n), d, det)
            pan = (v / (voices - 1) * 2 - 1) * width
            l += s * np.sqrt(0.5 * (1 - pan))
            r += s * np.sqrt(0.5 * (1 + pan))
    e = env_ad(d, a, dec)
    k = 1 / (len(notes) * voices) * 2.2
    return np.stack([lp(l, cutoff) * e * k, lp(r, cutoff) * e * k])


def pad(notes, d, cutoff=900):
    x = supersaw(notes, d, cutoff, a=0.25, dec=99, voices=4, width=0.9)
    fade = int(0.3 * SR)
    x[:, -fade:] *= np.linspace(1, 0, fade)
    return x * 0.55


def pluck(n, d=0.22, cutoff=5000):
    t = tt(d)
    x = saw(note(n), d) * 0.5 + np.sign(np.sin(2 * np.pi * note(n) * t)) * 0.25
    x = sweep_filter(x, cutoff, 300, 'low', q=1.4, curve=0.4)
    return x * np.exp(-t * 14) * 0.7


def ping(n1, n2):  # notification "pling" — original two-tone
    d = 0.35
    t = tt(d)
    x = (np.sin(2 * np.pi * note(n1) * t) * np.exp(-t * 18) +
         0.7 * np.where(t > 0.06, np.sin(2 * np.pi * note(n2) * (t - 0.06)) * np.exp(-(t - 0.06) * 14), 0) +
         0.15 * np.sin(2 * np.pi * note(n1) * 2.76 * t) * np.exp(-t * 40))
    return x * 0.38


def tap():
    d = 0.06
    t = tt(d)
    x = hp(rng.standard_normal(len(t)), 2500) * np.exp(-t * 600) * 0.6
    x += np.sin(2 * np.pi * 1800 * t) * np.exp(-t * 160) * 0.5
    x += np.sin(2 * np.pi * 220 * t) * np.exp(-t * 90) * 0.5
    return x


def knock():  # back-tap on phone glass: woody knock
    d = 0.15
    t = tt(d)
    x = np.sin(2 * np.pi * (300 + 500 * np.exp(-t * 80)) * t) * np.exp(-t * 45)
    x += hp(rng.standard_normal(len(t)), 1500) * np.exp(-t * 350) * 0.5
    return np.tanh(x * 1.5) * 0.8


def key_tick():
    d = 0.03
    t = tt(d)
    x = bp(rng.standard_normal(len(t)), 2500, 9000) * np.exp(-t * 500)
    return x * 0.5


def ding():
    d = 1.2
    t = tt(d)
    x = np.zeros(len(t))
    for n, g, dly in [(88, 1.0, 0), (95, 0.8, 0.07)]:
        f = note(n)
        tt_ = np.clip(t - dly, 0, None)
        on = (t >= dly)
        x += on * g * (np.sin(2 * np.pi * f * tt_) + 0.3 * np.sin(2 * np.pi * f * 2.0 * tt_) * np.exp(-tt_ * 6)) * np.exp(-tt_ * 4.5)
    return x * 0.28


def pop(pitch=1.0):
    d = 0.09
    t = tt(d)
    f = (600 + 900 * np.exp(-t * 60)) * pitch
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 50)
    return x * 0.4


def whoosh(d=0.6, up=True, f0=300, f1=6000):
    n = int(d * SR)
    nz = rng.standard_normal(n)
    x = sweep_filter(nz, f0 if up else f1, f1 if up else f0, 'band', q=1.6, curve=1.4)
    t = np.linspace(0, 1, n)
    e = np.sin(np.pi * t) ** 1.6
    st = np.stack([x * e * (0.6 + 0.4 * t), x * e * (1.0 - 0.4 * t)])
    return st * 0.9


def riser(d):
    n = int(d * SR)
    t = np.linspace(0, 1, n)
    nz = rng.standard_normal(n)
    x = sweep_filter(nz, 200, 9000, 'band', q=2.0, curve=2.2) * t ** 1.5
    f = 110 * 2 ** (t * 3)
    tone = np.sin(2 * np.pi * np.cumsum(f) / SR) * t ** 2 * 0.25
    return (x * 0.9 + tone)


def impact(size=1.0):
    d = 2.2
    t = tt(d)
    f = 30 + 70 * np.exp(-t * 9)
    sub = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 2.2)
    nz = lp(rng.standard_normal(len(t)), 2500) * np.exp(-t * 9) * 0.6
    return np.tanh((sub + nz) * 1.4) * 0.9 * size


def page_flip():
    d = 0.05
    t = tt(d)
    return bp(rng.standard_normal(len(t)), 1500, 7000) * np.exp(-t * 120) * 0.35


def tick():
    d = 0.02
    t = tt(d)
    return np.sin(2 * np.pi * 3200 * t) * np.exp(-t * 400) * 0.25


def reverse_cymbal(d=1.0):
    n = int(d * SR)
    t = np.linspace(0, 1, n)
    x = hp(rng.standard_normal(n), 5000) * t ** 3
    return x * 0.5


def tape_stop(sig_len=0.6):
    pass


# --------------------------------------------------------------- arrangement
DM = [62, 65, 69]        # Dm
BB = [58, 62, 65]        # Bb
FM = [60, 65, 69]        # F  (C F A voicing)
CM = [60, 64, 67]        # C
PROG = [DM, BB, FM, CM]
ROOT = [38, 34, 41, 36]  # D2 Bb1 F2 C2

duck = np.ones(N)


def sidechain(t, depth=0.65, rel=0.22):
    i = int(t * SR)
    n = int(rel * SR)
    if i >= N:
        return
    n = min(n, N - i)
    curve = 1 - depth * (1 - np.linspace(0, 1, n) ** 0.6)
    duck[i:i + n] = np.minimum(duck[i:i + n], curve)


music_L = np.zeros(N)
music_R = np.zeros(N)


def mplace(sig, t, gain=1.0, pan=0.0, rev=0.0):
    """music bus (gets sidechained)"""
    global L, R
    sL, sR = L, R
    L, R = music_L, music_R
    place(sig, t, gain, pan, rev)
    L, R = sL, sR


# --- HOOK bar 0 (beats 0-3): 4otf kick, offbeat hats, pumping bass, plings each 8th
for k in range(4):
    place(kick(), b(k), 0.95)
    sidechain(b(k))
    place(hat(), b(k + 0.5), 0.5, 0.2)
    place(hat(), b(k + 0.25), 0.18, -0.3)
    place(hat(), b(k + 0.75), 0.18, -0.3)
    if k in (1, 3):
        place(clap(), b(k), 0.55, 0, 0.15)
for k in range(8):
    mplace(bass_note(ROOT[0] + (12 if k % 2 else 0), b(0.5) * 0.9, 700), b(k * 0.5), 0.55)
ping_notes = [(81, 88), (84, 91), (79, 86), (86, 93), (81, 88), (88, 95), (84, 91), (89, 96)]
for k, (n1, n2) in enumerate(ping_notes):
    place(ping(n1, n2), b(k * 0.5), 0.9, (-0.5 if k % 2 else 0.5), 0.25)
    place(pop(1.0 + 0.1 * k), b(k * 0.5), 0.45)
mplace(supersaw(DM, b(3.9), 1800, 0.004, 0.6), 0, 0.35)

# --- QUESTION (beats 4-7): music drops out, hard hits on words
place(impact(0.9), b(4), 0.9, 0, 0.3)
place(kick(1.2), b(4), 0.9)
place(clap(), b(4), 0.4, 0, 0.5)
place(kick(1.1), b(5), 0.85)
place(snare_roll_hit(), b(5), 0.6, 0, 0.3)
place(impact(1.0), b(6), 0.8, 0, 0.35)
place(kick(1.3), b(6), 0.9)
mplace(supersaw([50, 57, 62, 65], b(2), 1100, 0.004, 0.9), b(6), 0.55, 0, 0.4)
place(reverse_cymbal(b(1)), b(7), 0.8)
mplace(pad([50, 53, 57], b(4)), b(4), 0.35)

# --- PAIN beats 8-13: half-time, ticking clock, dissonance
for k in [8, 9.5, 10, 11, 12.5, 13]:
    place(kick(0.9), b(k), 0.85)
    sidechain(b(k), 0.5)
for k in [9, 11, 13]:
    place(clap(), b(k), 0.5, 0, 0.3)
for k in range(int(6 / 0.25)):
    tk = 8 + k * 0.25
    place(tick(), b(tk), 0.7 if k % 4 == 0 else 0.35, 0.4 if k % 2 else -0.4)
mplace(pad([50, 51, 57], b(3)), b(8), 0.45)              # D Eb A — tense
mplace(pad([46, 49, 53, 56], b(3)), b(11), 0.45)          # Bb Db F Ab — tenser
for k in range(12):
    mplace(bass_note(ROOT[0] if k < 6 else ROOT[1], b(0.25) * 0.9, 300), b(8 + k * 0.5), 0.5)
# spreadsheet cell flips
for k in range(10):
    place(page_flip(), b(8.2 + k * 0.27), 0.6, rng.uniform(-0.6, 0.6))
# calendar flips 1 -> 28, accelerating, from beat 11 to 12.75
flip_times = 11 + 1.75 * (np.linspace(0, 1, 27) ** 0.7)
for ft in flip_times:
    place(page_flip(), b(ft), 0.9, rng.uniform(-0.3, 0.3))
place(impact(0.8), b(13), 0.75, 0, 0.3)
mplace(supersaw([46, 53, 58, 61], b(1), 2200, 0.003, 0.35), b(13), 0.5, 0, 0.3)
place(clap(), b(13), 0.6, 0, 0.4)

# --- TURN beats 14-16: riser + snare roll, gap, DROP
place(riser(b(1.85)), b(14), 0.55, 0, 0.2)
roll = [14, 14.5, 15, 15.25, 15.5, 15.625, 15.75]
for k, rt in enumerate(roll):
    place(snare_roll_hit(), b(rt), 0.25 + 0.06 * k, 0, 0.2)
place(whoosh(b(1.5), True, 200, 8000), b(14.3), 0.5)

# --- DROP + GROOVE beats 16-50
DROP, END = 16, 50
for k in range(DROP, END):
    bar = (k - DROP) // 4
    chord = PROG[bar % 4]
    root = ROOT[bar % 4]
    place(kick(), b(k), 0.95)
    sidechain(b(k))
    if k % 2 == 1:
        place(clap(), b(k), 0.6, 0, 0.18)
    place(hat(True), b(k + 0.5), 0.35, 0.25)
    for s in (0.25, 0.75):
        place(hat(), b(k + s), 0.22, -0.25)
    # offbeat bass + octave
    mplace(bass_note(root, b(0.45), 520), b(k + 0.5), 0.62)
    mplace(bass_note(root + 12, b(0.2), 900), b(k + 0.75), 0.25)
    # stabs on bar start and syncopation
    if (k - DROP) % 4 == 0:
        mplace(pad([n - 12 for n in chord] + chord, b(4)), b(k), 0.4)
    if (k - DROP) % 4 in (0, 1, 3) or k >= 44:
        mplace(supersaw([n + 12 for n in chord], b(0.4), 3200, 0.003, 0.12), b(k + (0 if (k - DROP) % 4 == 0 else 0.75 if (k - DROP) % 4 == 1 else 0.5)), 0.32, 0, 0.25)
    # 16th arp (sits under the quick-input scene a bit lower)
    arp = chord + [chord[0] + 12]
    if k >= 18:
        for s in range(4):
            n = arp[(k * 4 + s) % 4] + 12
            g = 0.16 if 20 <= k < 28 else 0.22
            mplace(pluck(n, 0.18), b(k + s * 0.25), g, 0.5 if s % 2 else -0.5, 0.25)

# drop moment
place(impact(1.2), b(16), 1.0, 0, 0.35)
place(hat(True), b(16), 0.6, 0, 0.5)
# Finery letters on 8ths (beats 16-18.5)
for k in range(6):
    place(pop(1.6 + 0.12 * k), b(16 + k * 0.5), 0.55, (k - 2.5) / 3)
place(whoosh(b(1.2), True, 300, 9000), b(18.6), 0.7)           # zoom into icon
place(impact(0.6), b(19.8), 0.5)

# QUICK INPUT beats 20-28
place(whoosh(b(1.1), False, 200, 4000), b(19.9), 0.55)          # phone flips to back
place(knock(), b(22), 1.0, 0, 0.2)
place(knock(), b(22.5), 1.0, 0, 0.2)
place(whoosh(b(0.9), True, 400, 7000), b(22.9), 0.5)            # flip to front
place(pop(1.2), b(23.25), 0.6)                                  # sheet appears
typing = 'Реклама 30 000'
for k in range(len(typing)):
    place(key_tick(), b(23.5) + k * (b(2) / len(typing)), 0.9, rng.uniform(-0.3, 0.3))
place(tap(), b(26), 0.9)
place(ding(), b(26.5), 1.0, 0, 0.35)

# COUNTERS / TAX beats 28-36
place(whoosh(b(0.8), True, 300, 9000), b(27.4), 0.65)            # zoom-through
place(impact(0.7), b(28), 0.6)
for k in range(18):
    place(tick(), b(28) + k * b(1.5) / 18, 0.8, rng.uniform(-0.4, 0.4))
place(clap(), b(30), 0.5, 0, 0.4)
place(whoosh(b(0.5), True, 800, 9000), b(30.75), 0.75)           # whip pan
for k in range(10):
    place(tick(), b(32) + k * b(1) / 10, 0.7)
place(pop(1.5), b(33.5), 0.7)
place(ding(), b(33.5), 0.45, 0, 0.3)
place(whoosh(b(0.6), True, 500, 9000), b(33.6), 0.55)            # gold flash
for k in range(12):
    place(tick(), b(34) + k * b(1.5) / 12, 0.45)

# ONE SCREEN beats 36-44
place(whoosh(b(1.0), False, 200, 5000), b(35.7), 0.6)
for k in range(7):
    place(pop(0.9 + 0.1 * k), b(36.5 + k * 0.5), 0.5, (k % 3 - 1) * 0.5)
place(whoosh(b(0.8), True, 300, 6000), b(39.3), 0.6)
place(impact(0.9), b(40), 0.8, 0, 0.3)
place(reverse_cymbal(b(0.5)), b(43.5), 0.6)

# MONTAGE beats 44-50: hit each beat, stutter 8ths at 48-49.5
for k in range(44, 48):
    place(snare_roll_hit(), b(k), 0.35, 0, 0.2)
    place(whoosh(b(0.35), True, 1000, 9000), b(k - 0.15), 0.3)
for k in range(4):
    place(pop(1.3 + k * 0.15), b(48 + k * 0.5), 0.6)
    place(kick(0.9), b(48 + k * 0.5), 0.5)
place(riser(b(1.0)), b(49), 0.4)

# OUTRO beat 50+: final hit, chord ring out, gentle pad
place(impact(1.2), b(50), 1.0, 0, 0.4)
place(kick(1.2), b(50), 0.9)
place(hat(True), b(50), 0.6, 0, 0.6)
mplace(supersaw(DM + [74], b(5), 2400, 0.003, 1.4), b(50), 0.6, 0, 0.5)
mplace(pad([38, 50, 57, 62, 65, 69], b(8)), b(50), 0.5)
mplace(bass_note(38, b(4), 300), b(50), 0.7)
place(pop(1.4), b(51), 0.5)
place(pop(1.7), b(52), 0.4)
place(ding(), b(53), 0.5, 0, 0.5)
place(whoosh(b(1.2), True, 2000, 10000), b(54), 0.25)  # shimmer pass
for k, n in enumerate([74, 77, 81, 86]):                # last soft arp
    mplace(pluck(n, 0.5, 3000), b(54 + k * 0.5), 0.18, 0, 0.5)

# ---------------------------------------------------------------- mixdown
music = np.stack([music_L * duck, music_R * duck])
dry = np.stack([L, R]) + music

# reverb: stereo exponentially-decaying noise IR (plate-ish)
ir_len = int(2.2 * SR)
ti = np.arange(ir_len) / SR
irL = rng.standard_normal(ir_len) * np.exp(-ti * 3.2)
irR = rng.standard_normal(ir_len) * np.exp(-ti * 3.2)
irL = lp(irL, 6000); irR = lp(irR, 6000)
irL /= np.sqrt(np.sum(irL ** 2)); irR /= np.sqrt(np.sum(irR ** 2))
musend = np.stack([music_L, music_R]) * 0.12
wet = np.stack([signal.fftconvolve(send[0] + musend[0], irL)[:N],
                signal.fftconvolve(send[1] + musend[1], irR)[:N]])
mix = dry + wet * 0.5
mix = hp(mix, 28)

# glue: soft clip bus
mix = np.tanh(mix * 0.9) / 0.9
fade = int(1.2 * SR)
mix[:, -fade:] *= np.linspace(1, 0, fade) ** 1.5
mix /= np.max(np.abs(mix)) * 1.05

out = os.path.join(os.path.dirname(__file__), '..', 'public', 'audio')
os.makedirs(out, exist_ok=True)
pcm = (mix.T * 32767).astype(np.int16)
with wave.open(os.path.join(out, 'finery_showreel_raw.wav'), 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(pcm.tobytes())
print('ok', mix.shape)
