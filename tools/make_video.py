"""Turn the recorded animation frames into an MP4 with physically driven sound.

    NODE_PATH=$(npm root -g) node animation/record.cjs          # frames + rpm_log.json in build/frames
    python3 tools/make_video.py                                # -> media/longhaul520_takeoff_landing.mp4

The sound is synthesised from the simulation log (per-motor RPM, camera distance,
altitude): 2-blade blade-pass tone + harmonics, blade-chopped broadband rotor
noise, motor magnetic whine (11 pole pairs), ground-wash rumble near the ground,
inverse-distance loudness, light ambient wind and a few birds.
"""
import json
import os
import subprocess
import sys
import wave

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
FRAMES = os.path.join(ROOT, "build", "frames")
OUT = os.path.join(ROOT, "media", "longhaul520_takeoff_landing.mp4")
FS = 48000
FPS = 30
HOVER_RPM = 5290
rng = np.random.default_rng(7)


def lowpass(x, fc):
    a = np.exp(-2 * np.pi * fc / FS)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):            # one-pole IIR (fast enough for ~1.6 M samples)
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def lowpass_fast(x, fc):
    # same one-pole filter, vectorised via scipy if available
    try:
        from scipy.signal import lfilter
        a = np.exp(-2 * np.pi * fc / FS)
        return lfilter([1 - a], [1, -a], x)
    except ImportError:
        return lowpass(x, fc)


def synth(log):
    log = np.array(log, dtype=float)
    t_log = log[:, 0]
    dur = t_log[-1] + 1 / FPS
    n = int(dur * FS)
    t = np.arange(n) / FS
    rpm = np.stack([np.interp(t, t_log, log[:, 1 + i]) for i in range(4)])
    dist = np.interp(t, t_log, log[:, 5])
    alt = np.interp(t, t_log, log[:, 6])

    out = np.zeros(n)
    base_noise = rng.standard_normal(n)
    rotor_noise = lowpass_fast(base_noise, 1400) - lowpass_fast(base_noise, 90)
    for i in range(4):
        r = rpm[i] * (1 + 0.004 * i)                     # tiny detune -> natural beating
        f_bp = r / 60 * 2
        ph = 2 * np.pi * np.cumsum(f_bp) / FS
        load = (r / HOVER_RPM) ** 2
        tone = sum((1 / h ** 1.15) * np.sin(h * ph + 0.7 * h * i) for h in range(1, 9))
        chop = 1 + 0.45 * np.sin(ph)                      # blade passage modulates the noise
        f_el = r / 60 * 11
        whine = np.sin(2 * np.pi * np.cumsum(f_el) / FS) + 0.4 * np.sin(2 * 2 * np.pi * np.cumsum(f_el) / FS)
        out += 0.10 * load * tone + 0.16 * load ** 1.2 * rotor_noise * chop + 0.018 * (r / HOVER_RPM) * whine
    # ground wash: low rumble when the rotors blow onto the pad
    wash = np.clip(1 - (alt - 0.0) / 1.6, 0, 1) * np.clip((rpm.mean(0) - 2500) / 2800, 0, 1.2)
    out += 0.22 * wash * lowpass_fast(rng.standard_normal(n), 220)
    # distance: inverse-distance law, reference 2.5 m
    out *= np.clip(2.5 / np.maximum(dist, 0.5), 0, 2.0)

    # ambience: soft wind + birds
    amb = 0.012 * lowpass_fast(rng.standard_normal(n), 400) * (1 + 0.5 * np.sin(2 * np.pi * 0.07 * t))
    for tc in [0.6, 1.4, 9.7, 15.3, 22.8, 30.6, 31.3]:
        L = int(0.12 * FS)
        s0 = int(tc * FS)
        if s0 + L >= n:
            continue
        tt = np.arange(L) / FS
        f = 3200 + 1400 * np.sin(2 * np.pi * 9 * tt) + 1500 * tt / 0.12
        env = np.sin(np.pi * tt / 0.12) ** 2
        amb[s0:s0 + L] += 0.03 * env * np.sin(2 * np.pi * np.cumsum(f) / FS)
    left = out + amb
    right = out + np.roll(amb, 311)
    st = np.stack([left, right], axis=1)
    st *= 0.89 / np.max(np.abs(st))
    return st


def write_wav(path, st):
    data = (st * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(FS)
        w.writeframes(data.tobytes())


def main():
    log = json.load(open(os.path.join(FRAMES, "rpm_log.json")))
    wav = os.path.join(FRAMES, "audio.wav")
    write_wav(wav, synth(log))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-framerate", str(FPS), "-i", os.path.join(FRAMES, "f%05d.jpg"),
           "-i", wav, "-c:v", "libx264", "-preset", "slow", "-crf", "20", "-pix_fmt", "yuv420p",
           "-c:a", "aac", "-b:a", "160k", "-shortest", "-movflags", "+faststart", OUT]
    subprocess.run(cmd, check=True)
    print("video:", OUT, f"{os.path.getsize(OUT) / 1e6:.1f} MB")


if __name__ == "__main__":
    sys.exit(main())
