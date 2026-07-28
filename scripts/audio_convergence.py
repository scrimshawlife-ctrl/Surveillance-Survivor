#!/usr/bin/env python3
"""Build Atlanta convergence assets from approved prior-city masters.

`docs/AUDIO_AGENT_EXECUTION.md` Batch 14 requires Atlanta's callbacks to reuse
canonical masters rather than regenerate imitations: "Build the convergence
through layering, filtering, editing, and spatial treatment of the canonical
source masters."

This builds the assets whose briefs are genuinely assembly work. It deliberately
does **not** attempt the phases that call for new composition — layering nine
tonal loops written at unrelated tempos and keys produces mud, not music.

    python3 scripts/audio_convergence.py --masters DIR --dest DIR
"""
import argparse
import glob
import json
import os
import wave

import numpy as np

RATE = 48_000
CITY_ORDER = ["wichita", "louisville", "tulsa", "dayton", "oakland",
              "san_francisco", "columbus", "new_york", "los_angeles"]


def read(path):
    with wave.open(path) as handle:
        frames, channels = handle.getnframes(), handle.getnchannels()
        data = np.frombuffer(handle.readframes(frames), dtype="<i2")
    samples = data.astype(np.float32).reshape(-1, channels) / 32768.0
    if channels == 1:
        samples = np.repeat(samples, 2, axis=1)
    return samples


def write(path, samples):
    samples = np.clip(samples, -1.0, 1.0).astype(np.float64)
    dither = (np.random.random(samples.shape) + np.random.random(samples.shape) - 1.0) / 32768.0
    quantised = np.round((samples + dither) * 32767.0).astype(np.int16)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as handle:
        handle.setnchannels(2)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes(quantised.tobytes())


def rms(samples):
    return float(np.sqrt((samples.astype(np.float64) ** 2).mean()) + 1e-12)


def set_rms(samples, target):
    return samples * (target / rms(samples))


def fit_length(samples, frames):
    """Loop or trim a source to an exact length."""
    if len(samples) >= frames:
        return samples[:frames]
    copies = int(np.ceil(frames / len(samples)))
    return np.tile(samples, (copies, 1))[:frames]


def pan(samples, position):
    """Constant-power pan. -1 hard left, +1 hard right."""
    angle = (position + 1.0) * np.pi / 4.0
    return samples * np.array([np.cos(angle), np.sin(angle)], dtype=np.float32)


def one_pole_lowpass(samples, cutoff_hz):
    """Cheap single-pole filter, adequate for spectral shaping of layers."""
    alpha = float(np.exp(-2.0 * np.pi * cutoff_hz / RATE))
    out = np.empty_like(samples)
    state = np.zeros(samples.shape[1], dtype=np.float32)
    for i in range(len(samples)):
        state = (1.0 - alpha) * samples[i] + alpha * state
        out[i] = state
    return out


def highpass(samples, cutoff_hz):
    return samples - one_pole_lowpass(samples, cutoff_hz)


def swept_lowpass(samples, start_hz, end_hz, blocks=64):
    """Approximate a filter sweep by crossfading between block-wise filterings."""
    out = np.zeros_like(samples)
    edges = np.linspace(0, len(samples), blocks + 1).astype(int)
    for b in range(blocks):
        lo, hi = edges[b], edges[b + 1]
        if hi <= lo:
            continue
        cutoff = start_hz * (end_hz / start_hz) ** (b / max(blocks - 1, 1))
        out[lo:hi] = one_pole_lowpass(samples[lo:hi], cutoff)
    return out


def fade(samples, attack_s=0.0, release_s=0.0):
    out = samples.copy()
    a = int(attack_s * RATE)
    r = int(release_s * RATE)
    if a > 0:
        out[:a] *= np.linspace(0.0, 1.0, a, dtype=np.float32)[:, None]
    if r > 0:
        out[-r:] *= np.linspace(1.0, 0.0, r, dtype=np.float32)[:, None]
    return out


def wrap_crossfade(samples, seconds):
    span = int(seconds * RATE)
    if len(samples) <= 4 * span or span <= 0:
        return samples
    ramp = np.linspace(0.0, 1.0, span, dtype=np.float32)[:, None]
    blended = samples[-span:] * (1.0 - ramp) + samples[:span] * ramp
    return np.concatenate([blended, samples[span:-span]])


def sources(masters, pattern):
    """Canonical masters in campaign order, so callbacks enter as authored."""
    found = []
    for city in CITY_ORDER:
        hits = glob.glob(os.path.join(masters, "Cities", city, pattern))
        if hits:
            found.append((city, sorted(hits)[0]))
    return found


# --- builders ---------------------------------------------------------------

def build_identity_bed(masters, seconds=60.0):
    """Nine city beds layered and spread across the field: convergent, spacious.

    Beds are noise-like, so they carry no tempo or key to clash. Equal-RMS
    weighting keeps any single city from dominating, and 1/sqrt(N) scaling keeps
    the sum from stacking into clipping.
    """
    picks = sources(masters, "amb_*_city_identity_loop.wav")
    frames = int(seconds * RATE)
    mix = np.zeros((frames, 2), dtype=np.float32)
    share = 1.0 / np.sqrt(len(picks))
    for index, (_city, path) in enumerate(picks):
        layer = fit_length(read(path), frames)
        layer = set_rms(layer, 0.05) * share
        # Spread across the field, alternating outward from centre.
        position = ((index % 2) * 2 - 1) * (0.15 + 0.85 * (index / len(picks)))
        mix += pan(layer, position)
    # Trim low-end buildup from nine stacked beds.
    mix = highpass(mix, 45.0)
    return wrap_crossfade(mix, 0.2), [c for c, _ in picks]


def build_convergence_stinger(masters, seconds=5.0):
    """Nine prior mechanics entering in campaign order, then one unified pulse."""
    picks = sources(masters, "sfx_*.wav")
    frames = int(seconds * RATE)
    mix = np.zeros((frames, 2), dtype=np.float32)
    entry_span = seconds * 0.52
    for index, (_city, path) in enumerate(picks):
        cue = set_rms(read(path), 0.07) / np.sqrt(len(picks))
        start = int(index / len(picks) * entry_span * RATE)
        end = min(start + len(cue), frames)
        position = ((index % 2) * 2 - 1) * (0.2 + 0.8 * (index / len(picks)))
        mix[start:end] += pan(cue, position)[:end - start]
    # The hive pulse: every signature striking together, centred and filtered
    # so it reads as one system rather than nine.
    pulse_at = int(entry_span * RATE)
    for _city, path in picks:
        cue = set_rms(read(path), 0.06) / len(picks)
        cue = one_pole_lowpass(cue, 2200.0)
        end = min(pulse_at + len(cue), frames)
        mix[pulse_at:end] += cue[:end - pulse_at]
    return fade(mix, 0.005, 1.2), [c for c, _ in picks]


def build_blind_spot(masters, seconds=8.0):
    """The network falling silent from the edges inward, then powering down."""
    picks = sources(masters, "music_*_boss_loop.wav")
    frames = int(seconds * RATE)
    mix = np.zeros((frames, 2), dtype=np.float32)
    share = 1.0 / np.sqrt(len(picks))
    # Outermost layers are cut first, so silence arrives from the edges inward.
    for index, (_city, path) in enumerate(picks):
        layer = fit_length(read(path), frames)
        layer = set_rms(layer, 0.06) * share
        position = ((index % 2) * 2 - 1) * (0.15 + 0.85 * (index / len(picks)))
        # Later index == further out == cut sooner.
        survives = 0.8 + (1.0 - index / len(picks)) * (seconds * 0.45)
        gate = np.ones(frames, dtype=np.float32)
        cut = int(survives * RATE)
        release = int(0.12 * RATE)
        gate[cut:] = 0.0
        if cut - release > 0:
            gate[cut - release:cut] = np.linspace(1.0, 0.0, release, dtype=np.float32)
        mix += pan(layer, position) * gate[:, None]
    # Power-down: the cathedral losing its supply.
    mix = swept_lowpass(mix, 9000.0, 380.0)
    # A clean human-scale atmosphere returns underneath.
    calm_path = sources(masters, "amb_*_city_identity_loop.wav")[0][1]
    calm = fit_length(read(calm_path), frames)
    calm = set_rms(calm, 0.018)
    breathe = np.clip(np.linspace(-1.4, 1.0, frames, dtype=np.float32), 0.0, 1.0)
    mix += calm * breathe[:, None]
    return fade(mix, 0.01, 1.6), [c for c, _ in picks]


def build_boss_phase_2(masters, anchor_city="los_angeles"):
    """Ten-city interlock over a single harmonic anchor.

    Layering nine tonal loops directly would clash in tempo and key. Instead one
    city's boss loop holds harmony and pulse while the other cities' *mechanic*
    cues — short and percussive rather than tonal — enter on a regular grid, so
    each callback stays identifiable without fighting the anchor.
    """
    anchor_hits = glob.glob(os.path.join(masters, "Cities", anchor_city, "music_*_boss_loop.wav"))
    if not anchor_hits:
        return None, []
    anchor = read(anchor_hits[0])
    frames = len(anchor)
    mix = set_rms(anchor, 0.055)
    picks = [(c, p) for c, p in sources(masters, "sfx_*.wav") if c != anchor_city]
    # Spread entries across the loop so callbacks accumulate rather than collide.
    for index, (_city, path) in enumerate(picks):
        cue = set_rms(read(path), 0.045) / np.sqrt(len(picks))
        cue = highpass(cue, 320.0)
        period = frames / (len(picks) + 1)
        position = ((index % 2) * 2 - 1) * (0.25 + 0.7 * (index / len(picks)))
        placed = pan(cue, position)
        # Recur through the loop so every city is heard more than once.
        for repeat in range(3):
            start = int((index + 1) * period / 3 + repeat * period)
            start = int(start) % max(frames - len(cue) - 1, 1)
            end = start + len(placed)
            if end < frames:
                mix[start:end] += placed
    return wrap_crossfade(mix, 0.9), [anchor_city] + [c for c, _ in picks]


BUILDERS = {
    "amb_atlanta_city_identity_loop": build_identity_bed,
    "sfx_atlanta_national_network_converge": build_convergence_stinger,
    "stinger_atlanta_final_blind_spot": build_blind_spot,
    "music_atlanta_boss_phase_2_loop": build_boss_phase_2,
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--masters", default="Resources/Audio/Masters")
    parser.add_argument("--dest", required=True)
    parser.add_argument("--report", default=None)
    args = parser.parse_args()

    provenance = {}
    for stem, builder in BUILDERS.items():
        samples, cities = builder(args.masters)
        if samples is None:
            print(f"  SKIPPED {stem}: no anchor available")
            continue
        path = os.path.join(args.dest, f"{stem}.wav")
        write(path, samples)
        provenance[stem] = {"sources": cities, "duration": round(len(samples) / RATE, 3)}
        print(f"{stem:44} {len(samples)/RATE:7.2f}s  from {len(cities)} prior-city masters")
    if args.report:
        json.dump(provenance, open(args.report, "w"), indent=2)


if __name__ == "__main__":
    main()
