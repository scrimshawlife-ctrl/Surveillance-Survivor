# Dayton audio receipt — Batch 7

| Field | Value |
| --- | --- |
| City | **Dayton** — *Gateway City: Every Camera Counts* |
| District authority | The Director of Gateway Optimization |
| Date (UTC) | 2026-07-27 |
| Generation | ElevenLabs **Music** (bed/loops) and **Sound Effects** (cue), owner account |
| Assets delivered | **4 / 4** |
| Status | `derived_delivery` — masters + CAF exist, not integrated |
| Tooling | `scripts/audio_intake.py` |

## Delivered

| Asset | Category | Duration | Target | LUFS | dBTP | Crossfade | Seam |
| --- | --- | ---: | --- | ---: | ---: | ---: | ---: |
| `amb_dayton_city_identity_loop.wav` | ambience | 69.80s | 28-75s | -27.0 | -14.9 | 200 ms | 1.93 |
| `music_dayton_run_loop.wav` | music | 59.10s | 58-120s | -20.0 | -5.6 | 900 ms | 1.44 |
| `sfx_dayton_gateway_chain.wav` | combat | 1.00s | 1-2s | -14.1 | -3.6 | — | — |
| `music_dayton_boss_loop.wav` | music | 59.03s | 58-120s | -20.0 | -7.8 | 900 ms | 0.08 |

Every master carries **0 full-scale samples**, and all three loops wrap below a 1.93 seam
ratio against an audibility threshold of 3.

## Source window — `amb_dayton_city_identity_loop`

The export ran 140 s (129.22 s of content) against a 28-75 s target, and its level envelope
showed a 5 s fade-in and a 22 s fade-out with a stable body between.

Rather than take the head arbitrarily, the most level-consistent 70 s window was selected by
sliding a window across the one-second RMS envelope and minimising its standard deviation:
**37-107 s, std 1.07 dB**, against 3.92 dB across the whole file. That window sits inside the
body and excludes both fades. It is recorded per row as `source_window_s`.

The export arrived titled `Golden_Watchman_Loop_...` — Tulsa's boss — because ElevenLabs
reuses project titles across generations. Identity was confirmed by drop order and by
acoustic character: 140 s at -37.0 LUFS is an ambience bed, not the 58-120 s tonal boss loop
its filename implied. Two exports shared that title with differing SHA-256 digests; the newer
was used at owner direction.

## Candidate selection — `sfx_dayton_gateway_chain`

| Candidate | Duration | LUFS | dBTP | Overs | Assessment |
| --- | ---: | ---: | ---: | ---: | --- |
| `Chained_gateway_acti_#2` | 1.00s | -14.1 | -3.6 | 0 | **selected** — centred in the -16..-12 band with headroom |
| `Chained_gateway_acti_#3` | 1.00s | -12.9 | -1.3 | 0 | in band but at the top, little headroom |
| `Chained_gateway_acti_#4` | 1.00s | -13.3 | -6.4 | 0 | in band, most headroom |

Unusually for this campaign, all three arrived clean — no clipping in any candidate.

## Level corrections

Both music loops arrived 7 dB hot with peaks over the ceiling (-5.6 and -0.5 dBTP before
correction) and were reduced to -20.0 LUFS. The bed was raised from -37.0 LUFS with pure
gain; 22.2 dB of peak headroom made limiting unnecessary.

## Reuse audit

No shared or prior-city master was regenerated or imitated. Dayton adds only city-identity
material and its own mechanic cue.

## Not verified

- **No listening check by the agent.** Selection and correction were measurement-led.
- Loop seams verified numerically, not by ear over repeated cycles.
- The chosen 37-107 s window is level-consistent by measurement; whether it is the most
  *musically* representative stretch is unverified.
- iPhone-speaker translation and device evidence outstanding.

## Validation

```
python3 scripts/audio_intake.py --picks picks.json --src DIR --dest DIR
4 processed, 0 failing
make audio-check
audio manifest valid: 68 assets, 17 runtime-required stems
```
