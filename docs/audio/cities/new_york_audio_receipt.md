# New York City audio receipt — Batch 11

| Field | Value |
| --- | --- |
| City | **New York City** — *The Five-Borough Omnigaze* |
| District authority | The Five-Borough Data Baron |
| Date (UTC) | 2026-07-27 |
| Generation | ElevenLabs **Music** (bed/loops) and **Sound Effects** (stinger), owner account |
| Assets delivered | **4 / 4** |
| Status | `derived_delivery` — masters + CAF exist, not integrated |
| Tooling | `scripts/audio_intake.py` |

## Delivered

| Asset | Duration | Target | LUFS | dBTP | Seam |
| --- | ---: | --- | ---: | ---: | ---: |
| `amb_new_york_city_identity_loop.wav` | 29.50s | 28-75s | -27.0 | -11.5 | 0.09 |
| `music_new_york_run_loop.wav` | 113.79s | 90-150s | -20.0 | -7.6 | 0.06 |
| `sfx_new_york_five_borough_sync.wav` | 1.93s | 1.9-4s | -17.0 | -10.6 | — |
| `music_new_york_boss_loop.wav` | 83.58s | 83-150s | -20.0 | -7.3 | 1.27 |

Every master carries 0 full-scale samples and holds the -1.0 dBTP ceiling.

## New York is the first city with a stricter music spec

The final-trilogy cities specify **90-150 s** music where earlier cities used 58-120 s. The
generator did not reach it unaided, and two of the four assets needed intervention beyond
normal processing. Both interventions are lossy in ways worth stating plainly.

### `music_new_york_run_loop` — repeated to reach length

The export delivered 30.00 s, a third of the 90 s floor. Rather than amend the floor by 60 s
and abandon the longer-music intent for the campaign's largest city, the owner asked for the
loop to be repeated to fit.

| Stage | Result |
| --- | ---: |
| Export content | 30.00s |
| Beat alignment | 12 bars at 100.4 BPM = 28.45s |
| Repeated | **x4** |
| Wrap crossfade | 0.90s |
| Final | **113.79s**, seam 0.06 |

> **This adds no new musical material.** The content recurs every ~28 s within the file. It is
> functionally what the engine would do by looping a 28 s asset, so nothing is lost relative to
> that — but the file's length does not represent 114 s of distinct composition, and the row
> carries `loop_repeats: 4` and a note saying so.

### `sfx_new_york_five_borough_sync` — de-clipped

The sole candidate contained **221 full-scale samples across runs up to 18 long** — genuine
flat-topping, which gain reduction cannot undo. The owner asked for it to be fixed rather than
regenerated.

`scripts/audio_intake.py` gained a `declip` option: for each flat-topped run it fits a cubic
through the samples either side and evaluates across the gap, which overshoots and restores a
plausible peak instead of a plateau. **95 runs were repaired, the longest 18 samples**, and the
master now measures 0 full-scale samples.

> **The restored peaks are inferred, not recovered.** The original waveform above the clip
> ceiling was never captured, so this is a plausible reconstruction rather than the true signal.
> It removes the audible harshness of flat tops; it does not make the export undamaged. Recorded
> per row as `declip_runs_repaired` with a note.

## Amended specification — per row, New York only

| Row | From | To | Why |
| --- | --- | --- | --- |
| `music_new_york_boss_loop` | 90-150s | **83-150s** | owner accepted the export as-is; fade trim and beat alignment left 83.58s |
| `sfx_new_york_five_borough_sync` | 2-4s | **1.9-4s** | sole candidate was 1.93s |

`music_new_york_run_loop` **keeps its 90-150 s target**, satisfied by repetition rather than by
amendment. Originals preserved as `duration_target_original`.

## Identifying two identically-titled exports

Both the bed and the run loop arrived as `NYC_Identity_*.wav`. Character was ambiguous — 29.71 s
at -22.7 LUFS and 30.00 s at -13.2 LUFS — so drop order decided, with the louder export taken as
the run loop. Unlike Oakland, the two did not separate cleanly by length.

The bed also arrived **above** its band at -22.7 LUFS against -30..-24, the first city bed
needing gain reduction rather than a boost.

## Reuse audit

No shared or prior-city master was regenerated or imitated.

## Not verified

- **No listening check by the agent.** All correction was measurement-led.
- The de-clipped stinger has not been heard; reconstruction quality is unverified.
- Whether ~28 s recurrence inside a 114 s file is acceptable in play is unverified.
- The bed / run-loop assignment rests on drop order, not measurement.
- iPhone-speaker translation and device evidence outstanding.

## Validation

```
python3 scripts/audio_intake.py --picks picks.json --src DIR --dest DIR
4 processed, 0 failing
make audio-check
audio manifest valid: 68 assets, 17 runtime-required stems
```
