# Audio work receipt — Batch 2/3 (shared system bank and district beds)
> **Historical production receipt.** Status rows below record the asset state when this receipt was written. The current manifest marks all 68 assets `runtime_integrated`; physical-device listening and rights confirmation remain open.


| Field | Value |
| --- | --- |
| Batch | **2/3** — shared system bank + five reusable district beds |
| Date (UTC) | 2026-07-26 |
| Agent | Claude Opus (interactive session with owner) |
| Generation | **ElevenLabs Music** (beds) and **Sound Effects** (cues), owner account |
| Assets delivered | **7 / 7** shared entries |
| Status set | `derived_delivery` — masters + CAF exist, deliberately NOT integrated |

## Integration status — none, by design

`AUDIO_AGENT_EXECUTION.md` requires reserved assets stay unintegrated until a deterministic
source event, catalog entry, playback mapping, cooldown/priority policy, tests, and evidence
all exist. `audio_events.json` holds 17 cues and **none** of them corresponds to an ambience
bed, a camera scan sweep, or the Blind Spot field loop. These seven are produced and cataloged
only. Wiring them would require new deterministic events, which is out of scope here.

## Amended specification (owner instruction)

ElevenLabs Music returned 30 s and 45 s beds against a `45-75s` target. The owner accepted the
delivered lengths and directed that the spec be amended rather than regenerating. For the five
`amb_shared_*` beds, `duration_target` is now **`28-75s`**, with the original value preserved as
`duration_target_original` and the reason recorded in `duration_target_amended_note` on each row.

This is a deliberate spec change, not a silent tolerance. Shortest delivered content: 28.82 s.

## Processing applied

One-shots follow the Batch 1 pipeline. **Loops differ in two ways that matter:**

1. **No tail fade.** A fade at the end of a loop is what makes the wrap audibly thump, so loops
   receive none.
2. **Wrap crossfade.** Each loop has its tail crossfaded over its head across 20 ms, giving
   sample continuity at the loop point. Cost is 20 ms of length.

Seam quality is reported as the level of the discontinuity a player would hear at the wrap.
Anything at or below roughly -70 dB is inaudible.

| Asset | Loop | Duration | LUFS | dBTP | Wrap before | Wrap after |
| --- | :-: | ---: | ---: | ---: | ---: | ---: |
| `amb_shared_retail_security_zone_loop.wav` | yes | 59.04s | -27.0 | -13.6 | -240 dB | -76 dB |
| `amb_shared_smart_downtown_loop.wav` | yes | 44.09s | -27.0 | -3.2 | -44 dB | -240 dB |
| `amb_shared_gated_serenity_loop.wav` | yes | 29.15s | -27.0 | -8.3 | -75 dB | -82 dB |
| `amb_shared_civic_innovation_campus_loop.wav` | yes | 29.02s | -27.0 | -15.7 | -44 dB | -84 dB |
| `amb_shared_evidence_warehouse_loop.wav` | yes | 28.82s | -27.0 | -9.7 | -82 dB | -96 dB |
| `sfx_camera_scan_sweep.wav` | no | 1.00s | -15.7 | -1.1 | — | — |
| `sfx_blind_spot_field_loop.wav` | yes | 14.98s | -16.0 | -3.5 | -21 dB | -90 dB |

The Blind Spot field loop improved most: a -21 dB wrap step (clearly audible as a click) became
-90 dB. Every loop now wraps at or below -76 dB.

## Loudness basis

Beds are long enough that **integrated** LUFS is the meaningful figure, and all five were
normalised to -27.0 LUFS, the centre of the bible's `-30 to -24` ambience band. They arrived
8-20 dB below that band but with 19-29 dB of peak headroom, so the correction was pure gain
with no limiting. Short cues use max momentary as in Batch 1.

## Provenance

| Asset | Source export | Generator |
| --- | --- | --- |
| `amb_shared_retail_security_zone_loop.wav` | `Suburban_Retail_Ambience_2026-07-27T040357.wav` | ElevenLabs Music |
| `amb_shared_smart_downtown_loop.wav` | `Smart_Downtown_Ambience_2026-07-27T042248.wav` | ElevenLabs Music |
| `amb_shared_gated_serenity_loop.wav` | `CHOPPED_20_gated_serenity.wav` | ElevenLabs Music |
| `amb_shared_civic_innovation_campus_loop.wav` | `song_2026-07-27T042652.wav` | ElevenLabs Music |
| `amb_shared_evidence_warehouse_loop.wav` | `Evidence_Warehouse_Ambience_2026-07-27T042754.wav` | ElevenLabs Music |
| `sfx_camera_scan_sweep.wav` | `Directional_license-_#2-1785126554656.wav` | ElevenLabs Sound Effects |
| `sfx_blind_spot_field_loop.wav` | `Low-pass_filtered_so_#4-1785126764004.wav` | ElevenLabs Sound Effects |

Music-model exports arrive with generated titles rather than manifest stems
(`song_2026-07-27T042401.wav`). Mapping to manifest rows was by owner-confirmed save order,
corroborated for the gated-serenity bed by its 15.43 s blank lead. Raw exports are preserved
outside the repo, separate from masters.

### Editing note

`amb_shared_gated_serenity_loop` was cut to the 15-45 s window at owner instruction; the first
15.43 s of that export was silence and the usable material ended near 45 s.

### Hashes

| Asset | Master SHA-256 | Delivery SHA-256 |
| --- | --- | --- |
| `amb_shared_retail_security_zone_loop.wav` | `746b9831af274a35…` | `220079cf8fee33ad…` |
| `amb_shared_smart_downtown_loop.wav` | `ee0d5228c95389d9…` | `12032d7bc674f41d…` |
| `amb_shared_gated_serenity_loop.wav` | `0b995ec474b0dca5…` | `95e430d908834848…` |
| `amb_shared_civic_innovation_campus_loop.wav` | `6870fa5a922f69c9…` | `8f451e7360bf9b2b…` |
| `amb_shared_evidence_warehouse_loop.wav` | `d756c14aa1f1a42f…` | `170c83a6837564a7…` |
| `sfx_camera_scan_sweep.wav` | `9128e5b662b916fe…` | `b156b0016193084c…` |
| `sfx_blind_spot_field_loop.wav` | `8c380dd29d174e23…` | `247ae03c3d2feb7a…` |

Full digests are per-row in `docs/AUDIO_ASSET_MANIFEST.json`.

## Not verified

- **No listening check of any kind by the agent.** Selection and processing were measurement-led.
- Loop seams are verified numerically, **not by ear over repeated cycles**.
- Bed suitability under gameplay, layering behaviour with city ambience, and iPhone-speaker
  translation are all unverified.
- No physical-device evidence.

## Validation

```
make audio-check
audio manifest valid: 68 assets, 17 runtime-required stems
```
