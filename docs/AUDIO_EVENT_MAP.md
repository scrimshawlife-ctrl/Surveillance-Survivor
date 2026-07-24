# Audio Event Map (v1)

Specification for mapping authoritative simulation events to runtime audio cues.
This document and the bundled `audio_events.json` catalog are the gate that
`docs/CONTINUATION_PLAN.md` requires **before** product audio assets ship.

The canonical production inventory, ElevenLabs prompts, ten-city sound packages,
reuse policy, loudness targets, and intake workflow live in
[`AUDIO_ASSET_PRODUCTION_BIBLE.md`](AUDIO_ASSET_PRODUCTION_BIBLE.md).
That document describes required and reserved assets; this event map remains the
authority for cues that are currently runtime-addressable.

## Principles

1. Simulation owns event truth (`RunEvent`). Audio only **projects** events.
2. No system beeps, no placeholder UI sounds in product builds.
3. If an asset is missing from the bank, the cue is skipped (silent).
4. No file or network I/O on the fixed-step path — resolution is in-memory.
5. Do not treat a production-bible entry as integrated until its deterministic event, catalog entry, app projection, and tests exist.
6. Reuse/hash-audit existing audio before generation; do not attach duplicate semantic cues under new stems.

## Catalog

| Field | Meaning |
|---|---|
| `id` | Stable cue identity (`AudioCueID`) |
| `assetName` | Future bundle/filename stem (not required to exist yet) |
| `category` | `combat` / `feedback` / `ui` / `stinger` |
| `priority` | Higher wins when multiple cues fire the same tick |
| `cooldownTicks` | Minimum ticks between plays of the same cue |
| `gain` | Linear gain 0…1.5 |
| `bus` | `sfx` / `ui` / `music` mix bus |
| `triggers` | One or more `RunEvent.Kind` matchers (+ optional message substring) |

Bundled file: `Sources/SurveillanceCore/Resources/Content/audio_events.json`  
Resolver: `AudioCueResolver` in `AudioEventCatalog.swift`  
App dry-run player: `Game/Feedback/AudioCuePlayer.swift` (silent until assets attach)

## Required runtime asset bank (not yet attached)

| Cue ID | Asset stem | Trigger |
|---|---|---|
| `suspicion_tier_up` | `sfx_suspicion_tier_up` | `tierChanged` |
| `upgrade_offered` | `sfx_upgrade_offered` | `upgradeOffered` |
| `upgrade_selected` | `sfx_upgrade_selected` | `upgradeSelected` |
| `lpr_destroyed` | `sfx_lpr_destroyed` | `entityDestroyed` + message contains `cameraPole` |
| `weapon_fire` | `sfx_weapon_fire` | `weaponFired` |
| `countermeasure_hit` | `sfx_countermeasure_hit` | `countermeasureHit` |
| `player_damaged` | `sfx_player_damaged` | `playerDamaged` |
| `player_defeated` | `sfx_player_defeated` | `playerDefeated` |
| `boss_activated` | `sfx_boss_activated` | `bossActivated` |
| `extraction_opened` | `sfx_extraction_opened` | `extractionOpened` |
| `extraction_completed` | `sfx_extraction_completed` | `extractionCompleted` |

ElevenLabs prompts for these exact stems are in the production bible. Preserve
these names unless the event catalog and all dependent tests are deliberately
migrated together.

Delivery format after approval: archived 48 kHz / 24-bit WAV masters plus CAF
or AAC/M4A delivery assets in an Xcode asset catalog or `.bundle`, one logical
stem per cue, loudness-normalized, with no speech requiring localization for MVP.

## Intake gate

1. Audit existing audio and reject semantic duplicates.
2. Generate or source assets using the approved production-bible prompt and metadata.
3. Owner approves this event map and the candidate masters.
4. Attach binary assets matching every current `assetName`.
5. Register stems with `AudioCuePlayer.setAvailableAssets`.
6. Add or update catalog/mapping tests.
7. Device-test audio route interruption, silent-mode policy, Bluetooth, speaker translation, and mixing per `RELEASE_READINESS.md`.
8. Record provenance, license, format, loudness, and validation results.

Until those gates pass, the emulator suite validates **mapping only** and the
application may remain silent for missing assets.
