# Wichita audio receipt — Batch 4
> **Historical production receipt.** Status rows below record the asset state when this receipt was written. The current manifest marks all 68 assets `runtime_integrated`; physical-device listening and rights confirmation remain open.


| Field | Value |
| --- | --- |
| City | **Wichita** — *The Panopticon of the Plains* |
| District authority | The Aviation Security Commissioner |
| Date (UTC) | 2026-07-26 |
| Generation | ElevenLabs **Music** (beds/loops) and **Sound Effects** (cues), owner account |
| Assets delivered | **4 / 4** |
| Status | `derived_delivery` — masters + CAF exist, not integrated |

## Integration status — none

`audio_events.json` holds 17 runtime cues and none corresponds to a city ambience bed,
city music loop, or city mechanic cue. These are produced and cataloged only; integrating
them would require new deterministic events per `AUDIO_AGENT_EXECUTION.md`.

## Delivered

| Asset | Category | Duration | Target | LUFS | dBTP | Wrap crossfade |
| --- | --- | ---: | --- | ---: | ---: | ---: |
| `amb_wichita_city_identity_loop.wav` | ambience | 28.56s | 28-75s | -27.0 | -5.4 | 200 ms |
| `music_wichita_run_loop.wav` | music | 59.10s | 58-120s | -20.0 | -5.7 | 900 ms |
| `sfx_wichita_zoning_corridor_activate.wav` | combat | 1.00s | 1-2s | -14.0 | -2.6 | — |
| `music_wichita_boss_loop.wav` | music | 59.10s | 58-120s | -20.0 | -6.4 | 900 ms |

## Loop seam method and correction

Loops receive no tail fade and a tail-over-head wrap crossfade. Crossfade length is
category-dependent: **900 ms for music, 200 ms for ambience**. A 20 ms blend was tried
first and proved far too short for tonal material.

Seam quality is judged as the wrap step **relative to the signal's own RMS**
sample-to-sample delta, not as an absolute dB figure. An absolute figure is misleading:
loud music naturally moves several hundredths of full scale between adjacent samples, so a
wrap step that looks large in dB can be entirely inaudible.

| Asset | Ratio after correction | Verdict |
| --- | ---: | --- |
| `amb_wichita_city_identity_loop.wav` | 0.10 | inaudible (≤3) |
| `music_wichita_run_loop.wav` | 1.69 | inaudible (≤3) |
| `music_wichita_boss_loop.wav` | 1.64 | inaudible (≤3) |

`music_wichita_boss_loop` needed the longest correction: at a 400 ms crossfade its ratio
was **3.93** (borderline audible); at 900 ms it is **1.64**.

### Duration note

`sfx_wichita_zoning_corridor_activate` measures 0.999979 s against a `1-2s` floor — one
sample, 0.02 ms, short. This is a silence-trim rounding artifact, not a content shortfall,
and is recorded rather than corrected by padding.

## Amended specification

At owner instruction, ElevenLabs Music length limits are accommodated rather than fought:

- city identity beds: `45-75s` → **`28-75s`** (shortest delivered 28.44 s)
- music loops: `75-120s` → **`58-120s`** (shortest delivered 58.73 s)

Originals are preserved per row as `duration_target_original` with a reason note. The
amendment applies campaign-wide: 10 city beds and 17 music loops.

## Reuse audit

No shared or prior-city master was regenerated. Wichita is the first city pack, so no prior
city assets existed to reuse; Louisville reuses the Wichita boss render as noted above and
otherwise adds only city-identity material.

## Not verified

- **No listening check by the agent.** All selection and correction was measurement-led.
- Loop seams are verified numerically, not by ear over repeated cycles.
- iPhone-speaker translation and device evidence remain outstanding.

## Validation

```
make audio-check
audio manifest valid: 68 assets, 17 runtime-required stems
```
