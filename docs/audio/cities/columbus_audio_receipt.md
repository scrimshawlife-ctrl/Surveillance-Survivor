# Columbus audio receipt — Batch 10

| Field | Value |
| --- | --- |
| City | **Columbus** — *The Six-Hundred-Eye Statehouse* |
| District authority | The Mayor of Meaningful Review |
| Date (UTC) | 2026-07-27 |
| Generation | ElevenLabs **Music** (bed/loops) and **Sound Effects** (cue), owner account |
| Assets delivered | **4 / 4** |
| Status | `derived_delivery` — masters + CAF exist, not integrated |
| Tooling | `scripts/audio_intake.py` |

## Delivered

| Asset | Duration | Target | LUFS | dBTP | Seam |
| --- | ---: | --- | ---: | ---: | ---: |
| `amb_columbus_city_identity_loop.wav` | 27.47s | 27-75s | -31.7 | -1.0 | 0.13 |
| `music_columbus_run_loop.wav` | 49.28s | 48-120s | -20.0 | -6.1 | 0.44 |
| `sfx_columbus_statewide_share.wav` | 1.00s | 1-2.2s | -16.0 | -6.3 | — |
| `music_columbus_boss_loop.wav` | 52.26s | 48-120s | -20.0 | -4.7 | 1.49 |

## Beat-aligned loop points

The owner asked for the run loop to be cut where it fades **and to loop on rhythm**. A
level-based trim alone is not enough: it produces a click-free seam that still stumbles the
beat, because the cut can land mid-bar.

`scripts/audio_intake.py` gained `loop_on_beat` for this. It estimates the beat period from
the autocorrelation of the onset envelope (positive spectral flux), then shortens the loop to a
whole number of four-beat bars. It runs after `trim_fade`, so the fade comes off first and the
bar alignment is computed on the surviving body.

| Asset | Export | Fade removed | Bar align | Detected | Bars | Final | Seam |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `music_columbus_run_loop` | 58.59s | 7.59s | 0.82s | 114.8 BPM | 24 | 49.28s | 0.44 |
| `music_columbus_boss_loop` | 59.04s | 3.04s | 2.84s | 63.2 BPM | 14 | 52.26s | 1.49 |

Both exports ended on heavy fades — tails 35.4 dB and 29.7 dB below their body level, the
worst seen in the campaign.

> The boss loop's 63.2 BPM reading may be a half-tempo detection of roughly 126 BPM. This does
> not compromise the result: a whole number of bars at half tempo is also a whole number of bars
> at true tempo, so the pulse still survives the wrap. It does mean `detected_bpm` should not be
> read as authoritative musical tempo.

## Peak-limited bed level

`amb_columbus_city_identity_loop` sits at **-31.7 LUFS**, 1.7 dB below the -30..-24 ambience
band. The export arrived at -38.2 LUFS with only 6.5 dB of peak headroom, so reaching the band
would have required 11.2 dB and pushed peaks over the ceiling. Level was capped to hold
-1.0 dBTP instead. Holding the ceiling takes precedence over hitting the band.

## Candidate selection — `sfx_columbus_statewide_share`

| Candidate | LUFS | dBTP | Assessment |
| --- | ---: | ---: | --- |
| `Statewide_sharing_ac_#1` | -4.9 | -2.7 | 11 dB hot |
| `Statewide_sharing_ac_#2` | -26.5 | -12.9 | 10 dB quiet |
| `Statewide_sharing_ac_#4` | -19.6 | -9.9 | **selected** — closest to the -18..-14 band |

All three were clipping-free and exactly 1.00s.

## Amended specification — per row, Columbus only

| Row | From | To |
| --- | --- | --- |
| `amb_columbus_city_identity_loop` | 28-75s | **27-75s** |
| `music_columbus_run_loop` | 58-120s | **48-120s** |
| `music_columbus_boss_loop` | 58-120s | **48-120s** |

Scoped to Columbus so other cities keep the stricter spec. Originals preserved as
`duration_target_original` with a per-row reason.

## Reuse audit

No shared or prior-city master was regenerated or imitated.

## Not verified

- **No listening check by the agent.** All correction was measurement-led.
- Loop seams and bar alignment are verified numerically, **not by ear over repeated cycles** —
  the rhythmic continuity the owner asked for is inferred from tempo estimation, not heard.
- iPhone-speaker translation and device evidence outstanding.

## Validation

```
python3 scripts/audio_intake.py --picks picks.json --src DIR --dest DIR
4 processed, 0 failing
make audio-check
audio manifest valid: 68 assets, 17 runtime-required stems
```
