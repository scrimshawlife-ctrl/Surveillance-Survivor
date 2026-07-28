# Oakland audio receipt — Batch 8

| Field | Value |
| --- | --- |
| City | **Oakland** — *The Sanctuary Scanner* |
| District authority | The Contract Renewal Hydra |
| Date (UTC) | 2026-07-27 |
| Generation | ElevenLabs **Music** (bed/loops) and **Sound Effects** (cue), owner account |
| Assets delivered | **4 / 4** |
| Status | `derived_delivery` — masters + CAF exist, not integrated |
| Tooling | `scripts/audio_intake.py` |

## Delivered

| Asset | Category | Duration | Target | LUFS | dBTP | Crossfade | Seam |
| --- | --- | ---: | --- | ---: | ---: | ---: | ---: |
| `amb_oakland_city_identity_loop.wav` | ambience | 29.14s | 28-75s | -27.0 | -7.5 | 200 ms | 0.06 |
| `music_oakland_run_loop.wav` | music | 119.10s | 58-120s | -20.0 | -3.6 | 900 ms | 0.20 |
| `sfx_oakland_borrowed_jurisdiction.wav` | feedback | 1.00s | 1-2s | -16.0 | -4.4 | — | — |
| `music_oakland_boss_loop.wav` | music | 58.40s | 58-120s | -20.0 | -6.5 | 900 ms | 0.03 |

Every master carries **0 full-scale samples**. Loop seams are 0.03-0.20 against an audibility
threshold of 3 — the cleanest set in the campaign so far.

## Identifying two identically-titled exports

The bed and the run loop both arrived as `Oakland_Ambience_*.wav`, differing only by
timestamp, because ElevenLabs reuses project titles across generations. Filename could not
assign them, so acoustic character did:

| Export | Content | LUFS | Reads as |
| --- | ---: | ---: | --- |
| `Oakland_Ambience_...185051` | 29.34s | -34.2 | ambience bed — short and quiet |
| `Oakland_Ambience_...185217` | 120.00s | -17.3 | run loop — long, loud, tonal |

The bed target is 28-75 s at -30..-24 LUFS and the music target is 58-120 s at -22..-18 LUFS,
so the two exports fall unambiguously on either side. Drop order agreed with that reading.

`music_oakland_run_loop` arrived at exactly 120.00 s, the ceiling of its target; after the
900 ms wrap crossfade it is 119.10 s and still inside.

## Candidate selection — `sfx_oakland_borrowed_jurisdiction`

| Candidate | LUFS | dBTP | Assessment |
| --- | ---: | ---: | --- |
| `Borrowed_jurisdictio_#1` | -4.6 | -0.7 | 10 dB hot, peak over the ceiling |
| `Borrowed_jurisdictio_#3` | -14.7 | -3.1 | **selected** — already inside the -18..-14 band with headroom |
| `garbled_filtered_mod_#1` | -9.7 | -0.6 | 5 dB hot, peak over the ceiling |

All three were free of clipping; selection came down to level discipline.

## Level corrections

Both music loops arrived roughly 3-7 dB hot with the boss loop peaking over the ceiling at
+0.1 dBTP, and were reduced to -20.0 LUFS. The bed was raised from -34.2 LUFS with pure gain.

## Reuse audit

No shared or prior-city master was regenerated or imitated. Oakland adds only city-identity
material and its own mechanic cue.

## Not verified

- **No listening check by the agent.** Selection and correction were measurement-led.
- Loop seams verified numerically, not by ear over repeated cycles.
- The bed/run-loop assignment rests on acoustic character and drop order, not on filename.
- iPhone-speaker translation and device evidence outstanding.

## Validation

```
python3 scripts/audio_intake.py --picks picks.json --src DIR --dest DIR
4 processed, 0 failing
make audio-check
audio manifest valid: 68 assets, 17 runtime-required stems
```
