# Tulsa audio receipt — Batch 6
> **Historical production receipt.** Status rows below record the asset state when this receipt was written. The current manifest marks all 68 assets `runtime_integrated`; physical-device listening and rights confirmation remain open.


| Field | Value |
| --- | --- |
| City | **Tulsa** — *The Petroleum Panopticon* |
| District authority | The Golden Watchman |
| Date (UTC) | 2026-07-26 |
| Generation | ElevenLabs **Music** (bed/loops) and **Sound Effects** (cue), owner account |
| Assets delivered | **4 / 4** |
| Status | `derived_delivery` — masters + CAF exist, not integrated |

## Delivered

| Asset | Category | Duration | Target | LUFS | dBTP | Wrap crossfade | Seam ratio |
| --- | --- | ---: | --- | ---: | ---: | ---: | ---: |
| `amb_tulsa_city_identity_loop.wav` | ambience | 28.18s | 28-75s | -27.0 | -15.5 | 200 ms | 0.30 |
| `music_tulsa_run_loop.wav` | music | 59.10s | 58-120s | -20.0 | -7.2 | 900 ms | 0.08 |
| `sfx_tulsa_behavioral_crude_extract.wav` | combat | 1.00s | 1-2.2s | -15.2 | -1.0 | — | — |
| `music_tulsa_boss_loop.wav` | music | 58.87s | 58-120s | -20.0 | -8.8 | 900 ms | 0.15 |

All three loops wrap at a seam ratio at or below 0.30 — far inside the inaudible band
(ratio = wrap step / RMS adjacent-sample delta; 3 is the audibility threshold).

## Clipping assessment — method corrected

All three `sfx_tulsa_behavioral_crude_extract` candidates contained full-scale samples, and a
naive count would have rejected two of them. Counting total overs is the wrong test. What
matters is **run length**: isolated one- and two-sample overs are inaudible and disappear
under the gain reduction needed to reach the loudness band, whereas a run of three or more is
flat-topped waveform that no gain change can undo.

| Candidate | Overs | Regions | Longest run | Duration | Assessment |
| --- | ---: | ---: | ---: | ---: | --- |
| `Behavioral_crude_ext_#2` | 13 | 11 | 2 samples (0.04 ms) | 1.00s | **selected** |
| `Behavioral_crude_ext_#3` | 22 | 17 | 3 samples (0.06 ms) | 1.00s | usable, 4.4 dB hotter |
| `sucking_sounds_#2` | 12 | 9 | 2 samples (0.04 ms) | 0.93s | rejected — under the 1.0s floor |

The selected master measures **0 full-scale samples** after processing.

## Level corrections

The bed arrived at -39.3 LUFS, 12 dB below the ambience band, with 26.8 dB of peak headroom,
so it was raised with pure gain and no limiting. Both music loops arrived 7-11 dB *hot* with
peaks over the ceiling (-0.4 and +0.2 dBTP) and were reduced to reach -20.0 LUFS, which also
brought peaks to -7.2 and -8.8 dBTP.

## Reuse audit

No shared or prior-city master was regenerated or imitated. Tulsa adds only city-identity
material and its own mechanic cue.

## Not verified

- **No listening check by the agent.** Selection and correction were measurement-led.
- Loop seams verified numerically, not by ear over repeated cycles.
- iPhone-speaker translation and device evidence outstanding.

## Validation

```
make audio-check
audio manifest valid: 68 assets, 17 runtime-required stems
```
