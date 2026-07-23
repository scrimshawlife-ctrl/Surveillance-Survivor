# Audio Event Map (v1)

Specification for mapping authoritative simulation events to runtime audio cues.
This document and the bundled `audio_events.json` catalog are the gate that
`docs/CONTINUATION_PLAN.md` requires **before** product audio assets ship.

## Principles

1. Simulation owns event truth (`RunEvent`). Audio only **projects** events.
2. No system beeps, no placeholder UI sounds in product builds.
3. If an asset is missing from the bank, the cue is skipped (silent).
4. No file or network I/O on the fixed-step path — resolution is in-memory.

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

## Required asset bank (not yet attached)

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

Delivery format (when approved): CAF or AAC in an Xcode asset catalog or `.bundle`,
one file per stem, loudness-normalized, no speech that requires localization for MVP.

## Intake gate

1. Owner approves this event map (or a revised schema version).
2. Attach binary assets matching every `assetName`.
3. Register stems with `AudioCuePlayer.setAvailableAssets`.
4. Device-test audio route interruption per `RELEASE_READINESS.md`.

Until then, the emulator suite validates **mapping only**.
