# Los Angeles audio receipt — Batch 12

| Field | Value |
| --- | --- |
| City | **Los Angeles** — *Thirty-Five Hundred Eyes, No One in Charge* |
| District authority | The Decentralized Accountability Producer |
| Date (UTC) | 2026-07-27 |
| Generation | ElevenLabs **Music** (bed/loops) and **Sound Effects** (cue), owner account |
| Assets delivered | **4 / 4** |
| Status | `derived_delivery` — masters + CAF exist, not integrated |
| Tooling | `scripts/audio_intake.py` |
| Spec amendments | **none** |

## Delivered

| Asset | Duration | Target | LUFS | dBTP | Seam |
| --- | ---: | --- | ---: | ---: | ---: |
| `amb_los_angeles_city_identity_loop.wav` | 73.62s | 28-75s | -27.0 | -8.2 | 0.41 |
| `music_los_angeles_run_loop.wav` | 118.57s | 90-150s | -20.0 | -9.2 | 0.24 |
| `sfx_los_angeles_private_network_persist.wav` | 2.48s | 1.5-3s | -16.0 | -5.6 | — |
| `music_los_angeles_boss_loop.wav` | 115.58s | 90-150s | -20.0 | -7.8 | 0.10 |

## The cleanest city pack in the campaign

Los Angeles is the first city since the shared bank to need **no specification amendment**.
Every asset landed inside its authored target and its loudness band:

- no clipping in any of the six candidates;
- no baked fade-out in any export;
- no de-clipping required;
- the bed arrived at 73.82 s, comfortably inside 28-75 s — the longest and best-fitting city
  bed so far, against a target that had to be amended downward for four other cities.

## Reaching the 90-150 s music spec by repetition

Both music exports were shorter than the final-trilogy target, as with New York, and the owner
asked for them to be looped to fit.

| Asset | Export | Beat alignment | Repeats | Final | Seam |
| --- | ---: | --- | ---: | ---: | ---: |
| `music_los_angeles_run_loop` | 30.00s | 20 bars at 160.7 BPM | **x4** | 118.57s | 0.24 |
| `music_los_angeles_boss_loop` | 60.00s | 21 bars at 86.5 BPM | **x2** | 115.58s | 0.10 |

> As with New York, **repetition adds no new musical material.** The run loop recurs about every
> 30 s and the boss loop about every 58 s. This is what the engine would do by looping a shorter
> asset, so nothing is lost relative to that, but the file lengths do not represent that much
> distinct composition. Both rows carry `loop_repeats` and a note.

> The 160.7 BPM reading is likely a double-tempo detection of roughly 80 BPM. As with Columbus,
> this does not compromise the result — a whole number of bars at double tempo is also a whole
> number at true tempo — but `detected_bpm` is not authoritative musical tempo.

## Candidate selection — `sfx_los_angeles_private_network_persist`

| Candidate | Duration | LUFS | dBTP | Assessment |
| --- | ---: | ---: | ---: | --- |
| `Public_surveillance__#1-...073591` | 2.05s | -15.5 | -9.7 | clean, in band |
| `Public_surveillance__#3-...078440` | 2.48s | -16.4 | -6.0 | **selected** — longest, in band, good headroom |
| `Public_surveillance__#3-...092401` | 2.46s | -16.1 | -5.6 | clean, in band |

All three were clipping-free and inside both the duration target and the loudness band, so
selection came down to length and headroom rather than to defects.

## Identifying stale export titles

The bed and the run loop both arrived titled `Five-Borough_Data_Baron_*.wav` — New York's boss —
because ElevenLabs carries project titles across generations. Character separated them cleanly:
73.82 s at -39.3 LUFS is a bed, 30.00 s at -11.4 LUFS is a music loop. Drop order agreed.

## Reuse audit

No shared or prior-city master was regenerated or imitated. Note that Atlanta's convergence
material is required to reuse approved masters from prior cities, so the Los Angeles masters
listed here are candidate sources for that work.

## Not verified

- **No listening check by the agent.** All correction was measurement-led.
- Loop seams and bar alignment verified numerically, not by ear over repeated cycles.
- Whether ~30 s and ~58 s recurrence inside the finished files is acceptable in play is
  unverified.
- iPhone-speaker translation and device evidence outstanding.

## Validation

```
python3 scripts/audio_intake.py --picks picks.json --src DIR --dest DIR
4 processed, 0 failing
make audio-check
audio manifest valid: 68 assets, 17 runtime-required stems
```
