#!/usr/bin/env python3
"""Intake ElevenLabs exports into approved masters and delivery derivatives.

Implements the mechanical half of `docs/AUDIO_AGENT_EXECUTION.md` steps 5, 6, 9:
trim silence, clean fades, loudness-normalise by category, hold the true-peak
ceiling, derive CAF, and hash. Creative selection stays with a human — this tool
only processes the candidate it is pointed at.

    python3 scripts/audio_intake.py --picks picks.json --src DIR --dest DIR

`picks.json` maps a manifest `logical_stem` to the chosen export:

    {"amb_dayton_city_identity_loop": {"file": "x.wav", "window": [37, 107]}}

`window` takes a start/end in seconds from the first non-silent sample.
`trim_fade` cuts a baked fade-out so a loop does not dip at its wrap point.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import wave

import numpy as np

# Production bible section 3, target loudness by category.
LOUDNESS = {
    "ui": (-18.0, -14.0), "feedback": (-18.0, -14.0), "combat": (-16.0, -12.0),
    "ambience": (-30.0, -24.0), "music": (-22.0, -18.0), "stinger": (-20.0, -14.0),
}
TP_CEILING = -1.0
FLOOR_DB = -50.0
# Tonal material needs a far longer wrap crossfade than noise-like ambience:
# 20 ms left a music loop with an audible step.
WRAP_CROSSFADE_MS = {"music": 900, "ambience": 200}
WRAP_CROSSFADE_DEFAULT_MS = 20
ONESHOT_FADE_MS = 12
# A wrap only clicks if it is large relative to the waveform's own motion.
SEAM_AUDIBLE_RATIO = 3.0


def measure(path):
    out = subprocess.run(
        ["ffmpeg", "-nostats", "-hide_banner", "-i", path, "-af",
         "ebur128=peak=true", "-f", "null", "-"], capture_output=True, text=True).stderr
    tail = out.split("Summary")[-1]

    def best(tag):
        vals = [float(v) for v in re.findall(rf"{tag}:\s*(-?[\d.]+)", out) if float(v) > -70]
        return max(vals) if vals else None

    integrated = re.search(r"I:\s+(-?[\d.]+)", tail)
    peak = re.search(r"Peak:\s+(-?[\d.]+)", tail)
    with wave.open(path) as handle:
        duration = handle.getnframes() / handle.getframerate()
    integrated = float(integrated.group(1)) if integrated else None
    # Compare like with like: short-term needs 3 s, momentary needs 400 ms.
    if duration >= 10:
        perceived, basis = integrated, "integrated"
    else:
        perceived, basis = best("M"), "max_momentary"
    if perceived is None:
        basis = "true_peak_aligned"
    return {"integrated": integrated,
            "true_peak": float(peak.group(1)) if peak else None,
            "perceived": perceived, "basis": basis, "duration": duration}


def read(path):
    with wave.open(path) as handle:
        frames, rate, channels = handle.getnframes(), handle.getframerate(), handle.getnchannels()
        data = np.frombuffer(handle.readframes(frames), dtype="<i2")
    return data.astype(np.float64).reshape(-1, channels) / 32768.0, rate, channels


def write(path, samples, rate):
    samples = np.clip(samples, -1.0, 1.0)
    dither = (np.random.random(samples.shape) + np.random.random(samples.shape) - 1.0) / 32768.0
    quantised = np.round((samples + dither) * 32767.0).astype(np.int16)
    with wave.open(path, "wb") as handle:
        handle.setnchannels(samples.shape[1])
        handle.setsampwidth(2)
        handle.setframerate(rate)
        handle.writeframes(quantised.tobytes())


def trim_silence(samples):
    mono = samples.mean(axis=1)
    voiced = np.where(np.abs(mono) > 10 ** (FLOOR_DB / 20))[0]
    return samples[voiced[0]:voiced[-1] + 1] if len(voiced) else samples


def trim_baked_fade(samples, rate, tolerance_db=4.0):
    """Cut a baked fade-out so a loop does not dip at its wrap point.

    ElevenLabs Music often ends on a fade. Crossfading a fading tail over the
    head blends *into* the dip rather than removing it, so the fade has to come
    off first. Walks back from the end to the last pair of consecutive seconds
    still within `tolerance_db` of the body's median level.

    Returns (trimmed samples, seconds removed).
    """
    mono = samples.mean(axis=1)
    if len(mono) < 4 * rate:
        return samples, 0.0
    env = np.array([
        20 * np.log10(np.sqrt((mono[i:i + rate] ** 2).mean()) + 1e-12)
        for i in range(0, len(mono) - rate, rate)
    ])
    floor = float(np.median(env)) - tolerance_db
    keep = None
    for i in range(len(env) - 1, 0, -1):
        if env[i] >= floor and env[i - 1] >= floor:
            keep = i + 1
            break
    if keep is None or keep >= len(env):
        return samples, 0.0
    cut = keep * rate
    return samples[:cut], (len(mono) - cut) / rate


def loopify(samples, rate, category):
    """Crossfade the tail over the head so the wrap point is continuous."""
    span = int(WRAP_CROSSFADE_MS.get(category, WRAP_CROSSFADE_DEFAULT_MS) / 1000 * rate)
    if len(samples) <= 4 * span:
        return samples, 0.0
    ramp = np.linspace(0.0, 1.0, span)[:, None]
    blended = samples[-span:] * (1.0 - ramp) + samples[:span] * ramp
    return np.concatenate([blended, samples[span:-span]]), span / rate


def seam_ratio(samples):
    """Wrap discontinuity relative to the signal's own sample-to-sample motion.

    An absolute dB figure is misleading: loud music naturally moves several
    hundredths of full scale between adjacent samples, so a wrap that looks
    large in dB can be inaudible.
    """
    mono = samples.mean(axis=1)
    deltas = np.abs(np.diff(mono))
    typical = float(np.sqrt((deltas ** 2).mean()))
    return abs(float(mono[0] - mono[-1])) / typical if typical > 0 else 0.0


def clip_runs(path):
    """Total full-scale samples and the longest consecutive run.

    Run length is what matters. Isolated one- and two-sample overs are inaudible
    and vanish under gain reduction; a run of three or more is flat-topped
    waveform that no gain change can undo.
    """
    with wave.open(path) as handle:
        data = np.frombuffer(handle.readframes(handle.getnframes()), dtype="<i2")
        data = data.astype(np.int32).reshape(-1, handle.getnchannels())
    at_scale = np.abs(data).max(axis=1) >= 32767
    runs, current = [], 0
    for flag in at_scale:
        if flag:
            current += 1
        elif current:
            runs.append(current)
            current = 0
    if current:
        runs.append(current)
    return int(at_scale.sum()), (max(runs) if runs else 0)


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1 << 16), b""):
            digest.update(block)
    return digest.hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", default="docs/AUDIO_ASSET_MANIFEST.json")
    parser.add_argument("--picks", required=True)
    parser.add_argument("--src", required=True)
    parser.add_argument("--dest", required=True)
    parser.add_argument("--report", default=None)
    args = parser.parse_args()

    rows = {r["logical_stem"]: r for r in json.load(open(args.manifest))["assets"]}
    picks = json.load(open(args.picks))
    raw_dir = os.path.join(args.dest, "_raw_exports")
    os.makedirs(raw_dir, exist_ok=True)

    results = []
    for stem, pick in picks.items():
        row = rows[stem]
        source = os.path.join(args.src, pick["file"])
        if not os.path.exists(source):
            print(f"  MISSING SOURCE {stem}: {pick['file']}", file=sys.stderr)
            continue
        scope = row.get("city") or ("Runtime" if row["scope"] == "runtime_required" else "Shared")
        folder = f"Cities/{scope}" if row.get("city") else scope
        masters = os.path.join(args.dest, "Masters", folder)
        delivery = os.path.join(args.dest, "Delivery", folder)
        os.makedirs(masters, exist_ok=True)
        os.makedirs(delivery, exist_ok=True)
        shutil.copy2(source, os.path.join(raw_dir, f"{stem}__{pick['file']}"))

        samples, rate, channels = read(source)
        samples = trim_silence(samples)
        if pick.get("window"):
            start, end = pick["window"]
            samples = samples[int(start * rate):int(end * rate)]

        is_loop = bool(row.get("loop"))
        fade_trimmed = 0.0
        if pick.get("trim_fade"):
            samples, fade_trimmed = trim_baked_fade(samples, rate)
        crossfade = 0.0
        if is_loop:
            samples, crossfade = loopify(samples, rate, row["category"])
        else:
            span = min(int(ONESHOT_FADE_MS / 1000 * rate), len(samples) // 4)
            if span:
                samples[-span:] *= np.linspace(1.0, 0.0, span)[:, None]

        target = sum(LOUDNESS[row["category"]]) / 2
        master = os.path.join(masters, row["filename"])
        write(master, samples, rate)
        for _ in range(3):
            m = measure(master)
            headroom = TP_CEILING - m["true_peak"]
            step = headroom if m["perceived"] is None else min(target - m["perceived"], headroom)
            if abs(step) < 0.15:
                break
            samples = samples * (10 ** (step / 20))
            write(master, samples, rate)

        # The corrective loop exits on small deltas, which can park a file just
        # above the ceiling. Enforce it outright.
        m = measure(master)
        if m["true_peak"] is not None and m["true_peak"] > TP_CEILING:
            samples = samples * (10 ** ((TP_CEILING - m["true_peak"] - 0.1) / 20))
            write(master, samples, rate)
            m = measure(master)

        caf = os.path.join(delivery, row["filename"].replace(".wav", ".caf"))
        subprocess.run(["afconvert", "-f", "caff", "-d", "LEI16@48000", master, caf],
                       check=True, capture_output=True)
        overs, longest = clip_runs(master)
        low, high = [float(x) for x in row["duration_target"].replace("s", "").split("-")]
        ratio = seam_ratio(samples) if is_loop else None

        failures = []
        if not low <= m["duration"] <= high:
            failures.append(f"duration {m['duration']:.2f}s outside {row['duration_target']}")
        if longest >= 3:
            failures.append(f"clip run of {longest} samples")
        if m["true_peak"] > TP_CEILING + 1e-9:
            failures.append(f"true peak {m['true_peak']:+.1f} dBTP")
        if ratio is not None and ratio > SEAM_AUDIBLE_RATIO:
            failures.append(f"seam ratio {ratio:.2f}")
        if rate != 48000 or channels != 2:
            failures.append(f"{rate} Hz / {channels}ch")

        results.append({
            "stem": stem, "filename": row["filename"], "category": row["category"],
            "loop": is_loop, "duration": round(m["duration"], 3),
            "target": row["duration_target"], "lufs": m["perceived"],
            "lufs_basis": m["basis"], "true_peak": m["true_peak"],
            "crossfade_s": round(crossfade, 3), "fade_trimmed_s": round(fade_trimmed, 3),
            "seam_ratio": round(ratio, 2) if ratio is not None else None,
            "clipped_samples": overs, "longest_clip_run": longest,
            "sample_rate": rate, "bit_depth": 16, "channels": channels,
            "master_sha256": sha256(master), "delivery_sha256": sha256(caf),
            "master": os.path.relpath(master, args.dest),
            "delivery": os.path.relpath(caf, args.dest),
            "source_export": pick["file"], "window": pick.get("window"),
            "failures": failures,
        })

    header = f"{'asset':40} {'dur':>8} {'target':>10} {'LUFS':>7} {'dBTP':>6} {'seam':>5} {'clip':>5}"
    print(header)
    print("-" * len(header))
    for r in results:
        lufs = f"{r['lufs']:7.1f}" if r["lufs"] is not None else f"{'peak':>7}"
        seam = f"{r['seam_ratio']:5.2f}" if r["seam_ratio"] is not None else f"{'—':>5}"
        print(f"{r['stem'][:40]:40} {r['duration']:7.2f}s {r['target']:>10} {lufs} "
              f"{r['true_peak']:6.1f} {seam} {r['clipped_samples']:5d}"
              + ("   " + "; ".join(r["failures"]) if r["failures"] else ""))
    failed = sum(1 for r in results if r["failures"])
    print(f"\n{len(results)} processed, {failed} failing")
    if args.report:
        json.dump(results, open(args.report, "w"), indent=2)
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
