# Audio work receipt — Batch 1 (runtime bank)

| Field | Value |
| --- | --- |
| Batch | **1** — current runtime bank |
| Date (UTC) | 2026-07-26 |
| Agent | Claude Opus (interactive session with owner) |
| Generation | **ElevenLabs Sound Effects**, owner account |
| Assets delivered | **17 / 17** `runtime_required` stems |
| Status set | `derived_delivery` — masters + CAF derivatives exist, playback NOT wired |

## Scope and honest limits

This receipt covers **generation, selection, mastering, delivery derivation, and hashing only**.

- `Game/Feedback/AudioCuePlayer.swift` remains a **dry-run stub**: it resolves cues and checks
  `availableAssets` by name but never loads or plays a file. Nothing is audible in the app yet.
- No status is `runtime_integrated`. Per `AUDIO_PLAN.md` rule 7 that requires catalog + app
  wiring + tests + evidence, none of which this change adds.
- **No physical-device evidence.** iPhone-speaker translation, headphone/Bluetooth balance,
  silent-mode policy, ducking, and dense-combat clipping all remain unverified.
- Selection was **measurement-led**, then owner-confirmed. The agent could not listen to any
  candidate. Gameplay readability in a full-density mix is still unverified by ear.

## Deviation from the preferred export spec

The protocol asks for 48 kHz / 24-bit WAV *when supported*. ElevenLabs exported **48 kHz /
16-bit stereo** for every candidate, so all masters are 16-bit. Recorded as `bit_depth: 16`
rather than implying the preferred depth was met.

## Processing applied

Per `AUDIO_AGENT_EXECUTION.md` steps 5, 6, 9:

1. leading/trailing silence trimmed at a -50 dBFS floor;
2. over-length content trimmed to the manifest maximum with a 12 ms tail fade;
3. loudness-normalised toward the production-bible band for the asset's category;
4. held at or below **-1.0 dBTP** true peak in every case;
5. triangular dither on requantisation to 16-bit;
6. `.caf` delivery derived with `afconvert -f caff -d LEI16@48000`;
7. untouched ElevenLabs exports preserved outside the repo, separate from masters;
8. SHA-256 computed for every master and delivery derivative.

### Loudness basis

The bible's bands are **short-term (3 s)** targets. Integrated LUFS over a sub-second one-shot
reads far below perceived level, so normalisation used **max momentary (400 ms)** for anything
shorter than the short-term window. Two assets are shorter than the 400 ms momentary window
itself (`sfx_suspicion_tier_up` 0.354 s, `sfx_weapon_fire` 0.350 s); loudness metering returns
nothing usable for those, so they are **true-peak aligned** instead and flagged
`lufs_basis: true_peak_aligned`. Their level relative to the rest of the bank is unverified by ear.

## Delivered assets

| Asset | Category | Duration | Target | LUFS | Basis | dBTP |
| --- | --- | ---: | --- | ---: | --- | ---: |
| `sfx_boss_activated.wav` | stinger | 3.560s | 2-5s | -17.0 | momentary | -3.4 |
| `sfx_build_synergy_changed.wav` | ui | 0.880s | 0.4-1.2s | -16.0 | momentary | -9.0 |
| `sfx_city_state_changed.wav` | feedback | 0.845s | 0.4-1.2s | -16.0 | momentary | -5.0 |
| `sfx_coordination_changed.wav` | feedback | 0.880s | 0.4-1.2s | -17.1 | momentary | -1.0 |
| `sfx_countermeasure_hit.wav` | combat | 0.480s | 0.2-0.6s | -17.0 | momentary | -1.0 |
| `sfx_director_decision.wav` | ui | 0.626s | 0.4-1.2s | -20.0 | momentary | -1.0 |
| `sfx_extraction_completed.wav` | stinger | 4.480s | 3-6s | -17.0 | momentary | -5.4 |
| `sfx_extraction_opened.wav` | stinger | 2.759s | 1.5-3s | -19.5 | momentary | -1.0 |
| `sfx_interactable_activate.wav` | combat | 0.631s | 0.4-1.2s | -14.0 | momentary | -3.5 |
| `sfx_landmark_pressure.wav` | feedback | 0.800s | 0.4-1.2s | -16.0 | momentary | -9.0 |
| `sfx_lpr_destroyed.wav` | combat | 1.280s | 0.8-1.6s | -14.0 | momentary | -4.6 |
| `sfx_player_damaged.wav` | feedback | 0.800s | 0.35-0.8s | -16.0 | momentary | -6.6 |
| `sfx_player_defeated.wav` | feedback | 2.680s | 1.5-3s | -16.0 | momentary | -2.4 |
| `sfx_suspicion_tier_up.wav` | feedback | 0.354s | 0.35-0.7s | — | true peak | -1.0 |
| `sfx_upgrade_offered.wav` | ui | 0.880s | 0.6-1.2s | -16.0 | momentary | -5.2 |
| `sfx_upgrade_selected.wav` | ui | 0.800s | 0.35-0.8s | -16.0 | momentary | -3.6 |
| `sfx_weapon_fire.wav` | combat | 0.350s | 0.12-0.35s | — | true peak | -1.0 |

### Hashes

| Asset | Master SHA-256 | Delivery SHA-256 |
| --- | --- | --- |
| `sfx_boss_activated.wav` | `46fd32ab3fea105f…` | `c724600ade8d5d05…` |
| `sfx_build_synergy_changed.wav` | `19b1dff3f2859d09…` | `fbe38e284752a452…` |
| `sfx_city_state_changed.wav` | `1f8001cf4934ae55…` | `a3a9c05a1918d900…` |
| `sfx_coordination_changed.wav` | `4786eb1bb46a71b6…` | `9f9c9045d3c8e73c…` |
| `sfx_countermeasure_hit.wav` | `d118a17bfee9903a…` | `e53e6f194c9edb73…` |
| `sfx_director_decision.wav` | `3e6e6083bdc9d2c4…` | `44b46b6e026ee199…` |
| `sfx_extraction_completed.wav` | `4b12a37d81e61def…` | `89f08682e5822697…` |
| `sfx_extraction_opened.wav` | `08635cc18919949a…` | `c34afa63017379d9…` |
| `sfx_interactable_activate.wav` | `7def6210c9d9b993…` | `f2a11ac096394a95…` |
| `sfx_landmark_pressure.wav` | `a8eda6ee9ab1e34a…` | `9217bd74d46b0bc8…` |
| `sfx_lpr_destroyed.wav` | `3ad095194aaae95c…` | `e0aa3408e2d06f8e…` |
| `sfx_player_damaged.wav` | `78385ed1f1bad65d…` | `7519c9f11714ed1d…` |
| `sfx_player_defeated.wav` | `283d4b8531bde29a…` | `fa349aa9178f1df1…` |
| `sfx_suspicion_tier_up.wav` | `4999df2bc73c4fcf…` | `2d46ca1776dda84a…` |
| `sfx_upgrade_offered.wav` | `fe848f84e2531cd3…` | `a8be19a46f966f3a…` |
| `sfx_upgrade_selected.wav` | `d1ce38f419093236…` | `65caef38aa656e4a…` |
| `sfx_weapon_fire.wav` | `efb64adf3c45273b…` | `5cf3464bc30cd782…` |

Full digests are recorded per row in `docs/AUDIO_ASSET_MANIFEST.json`.

## Regenerations required during this batch

| Asset | First attempt | Resolution |
| --- | --- | --- |
| `sfx_upgrade_selected` | all 3 variants 0.242–0.340 s, under the 0.35 s floor | regenerated; new set 0.800 s, keeper clean |
| `sfx_player_damaged` | all 3 clipped (37/49/111 full-scale samples), 3–7 dB hot | regenerated; keeper had 1 isolated sample, resolved by -6.6 dB |
| `sfx_landmark_pressure` | passed gates but -33.7 LUFS over a -52 dB floor; +18 dB would expose hiss | regenerated 17 dB hotter at source, clean |
| `sfx_extraction_opened` | owner-rejected replacement had 725 clipped samples across 450 regions | kept the clean original, owner chose the limited +11.8 dB variant |

## Observed generator behaviour

- **Clipping is the dominant failure mode**: 12 of ~40 candidates contained full-scale samples.
- **Durations quantise to a grid** (0.48 / 0.68 / 0.80 / 0.88 / 1.28 / 2.68 / 3.56 / 4.48 s).
  Nothing shorter than 0.48 s was obtainable, so `sfx_weapon_fire`'s 0.12–0.35 s target required
  trimming. This matters in play: kinetic fire reaches 12 shots/sec at its upgraded cadence floor,
  so an untrimmed 0.48 s sample would overlap six deep.
- **Output level varies widely between prompts** — one asset arrived 7 dB hot while another from
  the same session arrived 12 dB quiet.

## Validation

```
make audio-check
audio manifest valid: 68 assets, 17 runtime-required stems
```

Mechanical verification across all 17 masters: 48 kHz / 16-bit / stereo, 0 clipped samples,
true peak <= -1.0 dBTP, duration inside the manifest target.

## Next

1. Owner ear-check of the bank against a full-density mix.
2. Implement real playback in the app layer (engine, session category, bus gains,
   `setAvailableAssets`), with tests — only then may any row become `runtime_integrated`.
3. Physical-iPhone audio evidence per `RELEASE_READINESS.md`.
