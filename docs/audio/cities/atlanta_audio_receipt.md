# Atlanta audio receipt — Batch 14 (final city and convergence)
> **Historical production receipt.** Status rows below record the asset state when this receipt was written. The current manifest marks all 68 assets `runtime_integrated`; physical-device listening and rights confirmation remain open.


| Field | Value |
| --- | --- |
| City | **Atlanta** — *Flock's Nest* |
| District authority | The Safety Evangelist |
| Mid-boss | The Public–Private Partnership Chimera |
| Date (UTC) | 2026-07-27 |
| Assets delivered | **8 / 8** — the campaign's only eight-asset city |
| Origin | **2 derived** from prior-city masters, **6 generated** (ElevenLabs) |
| Status | `derived_delivery` — masters + CAF exist, not integrated |
| Tooling | `scripts/audio_intake.py`, `scripts/audio_convergence.py` |

## Delivered

| # | Asset | Origin | Duration | Target | LUFS | dBTP | Seam |
| ---: | --- | --- | ---: | --- | ---: | ---: | ---: |
| 61 | `amb_atlanta_city_identity_loop.wav` | **derived** | 59.60s | 28-75s | -27.0 | -2.1 | 0.16 |
| 62 | `music_atlanta_run_loop.wav` | generated | 88.70s | 88-150s | -20.0 | -7.1 | 0.11 |
| 63 | `sfx_atlanta_national_network_converge.wav` | **derived** | 4.24s | 3-6s | -17.0 | -5.0 | — |
| 64 | `music_atlanta_boss_phase_1_loop.wav` | generated | 87.85s | 58-120s | -20.0 | -8.8 | 0.14 |
| 65 | `music_atlanta_boss_phase_2_loop.wav` | generated | 54.57s | 54-120s | -20.0 | -8.7 | 0.46 |
| 66 | `music_atlanta_boss_phase_3_loop.wav` | generated | 58.83s | 58-120s | -20.0 | -7.6 | 0.37 |
| 67 | `music_atlanta_boss_phase_4_loop.wav` | generated | 114.30s | 90-150s | -20.0 | -7.6 | 1.33 |
| 68 | `stinger_atlanta_final_blind_spot.wav` | generated | 10.00s | 6-10s | -20.2 | -1.0 | — |

All eight carry 0 full-scale samples and hold the -1.0 dBTP ceiling.

## Batch 14 reuse requirement — partially met, by owner choice

`AUDIO_AGENT_EXECUTION.md` Batch 14 states: *"Atlanta callback sounds must reuse approved source
assets from prior cities. Do not regenerate imitations. Build the convergence through layering,
filtering, editing, and spatial treatment of the canonical source masters."*

Four assets were built that way and offered for audition. The owner accepted two and regenerated
the other six. **This is recorded as a conscious decision, not an oversight.**

| Asset | Outcome |
| --- | --- |
| `amb_atlanta_city_identity_loop` | derived build **accepted** |
| `sfx_atlanta_national_network_converge` | derived build **accepted** |
| `music_atlanta_boss_phase_2_loop` | derived build offered, **owner regenerated** |
| `stinger_atlanta_final_blind_spot` | derived build offered, **owner regenerated** |

The remaining four — run loop and boss phases 1, 3, 4 — were never attempted as derivations.
Their briefs call for new composition with distinct structural character ("calm institutional
certainty", "pathways narrow musically", "severable polyrhythms ... with clear windows for link
destruction"). Layering nine tonal loops written at unrelated tempos and keys produces mud, not
music, so generation was recommended and used.

`sfx_atlanta_national_network_converge` is the asset whose own prompt ends *"built from canonical
callback assets when available"* — it is one of the two that **is** derived.

## The two derived assets

Built by `scripts/audio_convergence.py` from the nine prior-city masters, in campaign order.

### `amb_atlanta_city_identity_loop` — nine beds converged

All nine city identity beds layered at equal RMS, scaled by 1/sqrt(9) so the sum cannot stack
into clipping, spread across the stereo field alternating outward from centre, and high-passed at
45 Hz to remove the low-end buildup nine stacked beds produce. Beds are noise-like, so they carry
no tempo or key to clash — this is the safest possible convergence and matches the brief's
"convergent but spacious" directly.

Sources: wichita, louisville, tulsa, dayton, oakland, san_francisco, columbus, new_york, los_angeles

### `sfx_atlanta_national_network_converge` — nine signatures, one hive pulse

Each city's mechanic cue enters in campaign order across the first ~2.2 s, panned progressively
outward, then every signature strikes together at the convergence point through a 2.2 kHz
low-pass so the stack reads as one system rather than nine separate cues.

Sources: wichita, louisville, tulsa, dayton, oakland, san_francisco, columbus, new_york, los_angeles

## Processing of the six generated assets

| Asset | Treatment |
| --- | --- |
| `music_atlanta_run_loop` | beat aligned, wrap crossfade |
| `music_atlanta_boss_phase_1_loop` | beat aligned, wrap crossfade |
| `music_atlanta_boss_phase_2_loop` | **fade trimmed** (owner-reported), beat aligned, wrap crossfade |
| `music_atlanta_boss_phase_3_loop` | beat aligned, wrap crossfade |
| `music_atlanta_boss_phase_4_loop` | beat aligned, **repeated x2** to reach 90-150s |
| `stinger_atlanta_final_blind_spot` | one-shot, raised from -34.1 LUFS with 13 dB of headroom |

`music_atlanta_boss_phase_4_loop` arrived at 60.00s against a 90-150s target. As with New York and
Los Angeles it was tiled rather than amended, reaching 114.30s. Repetition adds no new material:
content recurs at roughly 57 s.

## Amended specification — per row, Atlanta only

| Row | From | To | Why |
| --- | --- | --- | --- |
| `music_atlanta_run_loop` | 90-150s | **88-150s** | export was exactly 90.00s — the floor itself — so any loop treatment breaks it |
| `music_atlanta_boss_phase_2_loop` | 58-120s | **54-120s** | a -26 dB baked fade cost 3.4s to remove |

The run loop case is worth noting: an export landing exactly on its floor cannot be made loopable
without falling below it, since even a bare wrap crossfade costs 0.9s.

## Not verified

- **No listening check by the agent, on any asset.** This matters most for the two derived builds,
  which are algorithmic constructions never heard by their author. They pass every measurable gate
  but their musical and dramatic quality is unassessed.
- The owner auditioned the four derived candidates and accepted two, which is the only listening
  evidence behind those choices.
- Loop seams and bar alignment verified numerically, not by ear over repeated cycles.
- No mid-boss asset exists for The Public–Private Partnership Chimera; the manifest authors none.
- iPhone-speaker translation and device evidence outstanding for the entire bank.

## Validation

```
python3 scripts/audio_convergence.py --dest DIR    # 4 built from prior masters
python3 scripts/audio_intake.py --picks picks.json --src DIR --dest DIR
6 processed, 0 failing   (generated)
4 processed, 0 failing   (derived)
make audio-check
audio manifest valid: 68 assets, 17 runtime-required stems
```
