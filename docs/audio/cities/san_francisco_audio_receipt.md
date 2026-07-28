# San Francisco audio receipt — Batch 9

| Field | Value |
| --- | --- |
| City | **San Francisco** — *Fog of Probable Cause* |
| District authority | The Algorithmic Moderate |
| Date (UTC) | 2026-07-27 |
| Generation | ElevenLabs **Music** (bed/loops) and **Sound Effects** (cue), owner account |
| Assets delivered | **4 / 4** |
| Status | `derived_delivery` — masters + CAF exist, not integrated |
| Tooling | `scripts/audio_intake.py` |

## Delivered

| Asset | Category | Duration | Target | LUFS | dBTP | Fade trimmed | Crossfade | Seam |
| --- | --- | ---: | --- | ---: | ---: | ---: | ---: | ---: |
| `amb_san_francisco_city_identity_loop.wav` | ambience | 29.27s | 28-75s | -27.0 | -14.1 | — | 200 ms | 0.58 |
| `music_san_francisco_run_loop.wav` | music | 54.10s | 36-120s | -20.0 | -5.3 | 3.31s | 900 ms | 0.79 |
| `sfx_san_francisco_hidden_sensor_fog.wav` | combat | 0.98s | 0.9-2s | -16.5 | -1.0 | — | — | — |
| `music_san_francisco_boss_loop.wav` | music | 37.10s | 36-120s | -20.0 | -8.0 | 1.61s | 900 ms | 2.39 |

Every master carries 0 full-scale samples and holds the -1.0 dBTP ceiling.

## Baked fade-outs removed

The owner reported the run loop fading at its end and asked for it to be made loopable. Both
music exports carried a baked fade-out, which a wrap crossfade cannot fix: crossfading a
fading tail over the head blends *into* the dip rather than removing it. The fade has to come
off first.

`scripts/audio_intake.py` gained a `trim_fade` option for this. It walks back from the end to
the last pair of consecutive seconds still within 4 dB of the body's median level and cuts
there. Results:

| Asset | Before | Fade removed | Crossfade | Final | Seam |
| --- | ---: | ---: | ---: | ---: | ---: |
| `music_san_francisco_run_loop` | 58.31s | 3.31s | 0.90s | 54.10s | 0.79 |
| `music_san_francisco_boss_loop` | 39.61s | 1.61s | 0.90s | 37.10s | 2.39 |

The boss loop's 2.39 seam is the highest in the campaign so far, though still inside the
audibility threshold of 3.

## Identifying two identically-titled exports

Both music exports arrived as `San_Francisco_Combat_Loop_*.wav`. Unlike Oakland — where a bed
and a music loop could be separated by character — these were both music loops, so acoustic
class could not assign them. The owner's report that the run loop faded at its end was the
deciding evidence:

| Export | Content | Tail vs body | Assigned |
| --- | ---: | ---: | --- |
| `...202921` | 58.31s | **-8.2 dB, fades** | run loop |
| `...203017` | 39.61s | -5.2 dB | boss loop |

This assignment rests on the owner's listening report plus generation order, **not** on
filename or measurement alone. If it is backwards, the two loops are swapped.

## Amended specification — per row, San Francisco only

Three rows were amended at owner instruction. Unlike the earlier campaign-wide amendments,
these are **scoped to San Francisco** so the other cities keep the stricter spec:

| Row | From | To | Why |
| --- | --- | --- | --- |
| `music_san_francisco_run_loop` | 58-120s | **36-120s** | fixing the loop cost 4.21s |
| `music_san_francisco_boss_loop` | 58-120s | **36-120s** | export was 39.61s before processing |
| `sfx_san_francisco_hidden_sensor_fog` | 1-2s | **0.9-2s** | all three candidates landed just under 1.0s |

Originals are preserved as `duration_target_original` with a reason note per row.

> The boss loop is 37.10 s where the campaign standard is 58 s minimum. It will repeat more
> often than any other city's boss music. That is a deliberate owner decision, not an oversight.

## Candidate selection — `sfx_san_francisco_hidden_sensor_fog`

| Candidate | Duration | Overs | Longest run | Assessment |
| --- | ---: | ---: | ---: | --- |
| `Fog-hidden_sensor_ac_#3-...305948` | 0.98s | 1 | 1 | **selected** — longest and cleanest |
| `Fog-hidden_sensor_ac_#1-...323237` | 0.94s | 20 | 5 | flat-topped |
| `Fog-hidden_sensor_ac_#3-...339649` | 0.91s | 76 | 16 | badly flat-topped |

The selected master measures 0 full-scale samples after processing.

## Reuse audit

No shared or prior-city master was regenerated or imitated.

## Not verified

- **No listening check by the agent.** All correction was measurement-led.
- The run-loop / boss-loop assignment depends on the owner's fade report.
- Loop seams verified numerically, not by ear over repeated cycles.
- Whether a 37 s boss loop repeats acceptably in play is unverified.
- iPhone-speaker translation and device evidence outstanding.

## Validation

```
python3 scripts/audio_intake.py --picks picks.json --src DIR --dest DIR
4 processed, 0 failing
make audio-check
audio manifest valid: 68 assets, 17 runtime-required stems
```
