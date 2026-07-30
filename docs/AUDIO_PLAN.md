# Audio plan (agent entry point)

**Remote agents: start here for all product audio work.**

| Role | Path |
| --- | --- |
| **This plan** | `docs/AUDIO_PLAN.md` |
| **Execution order + batches** | [`AUDIO_AGENT_EXECUTION.md`](AUDIO_AGENT_EXECUTION.md) |
| **Machine work queue** | [`AUDIO_ASSET_MANIFEST.json`](AUDIO_ASSET_MANIFEST.json) |
| **Creative prompts / bible** | [`AUDIO_ASSET_PRODUCTION_BIBLE.md`](AUDIO_ASSET_PRODUCTION_BIBLE.md) |
| **Runtime event → cue map** | [`AUDIO_EVENT_MAP.md`](AUDIO_EVENT_MAP.md) |
| **Runtime catalog (code authority)** | `Sources/SurveillanceCore/Resources/Content/audio_events.json` |
| **Batch 0 receipts (inventory)** | [`audio/README.md`](audio/README.md) |
| **Media trees** | `Resources/Audio/` — Runtime, Shared, and all ten Cities populated with masters and CAF delivery assets |
| **Playback** | `Game/Feedback/AudioBank.swift` (engine) · `AudioCuePlayer.swift` (resolution) |
| **Gate** | `make audio-check` |

Also listed in root [`AGENTS.md`](../AGENTS.md) and [`README.md`](../README.md) documentation tables.

---

## Current status

| Item | State |
| --- | --- |
| Batch **0** — inventory / hash / dedup / receipts | **Done** → [`audio/AUDIO_WORK_RECEIPT.md`](audio/AUDIO_WORK_RECEIPT.md) |
| Binaries in repo | **68** masters + 68 CAF derivatives (all batches) |
| Runtime-required stems | **68** (aligned with `audio_events.json` schema 2) |
| Batch **1** — generate 17 stems | **Done** → [`audio/AUDIO_WORK_RECEIPT_BATCH1.md`](audio/AUDIO_WORK_RECEIPT_BATCH1.md) |
| Product playback | **Live** — `AudioBank` loads 68/68 delivery assets (simulator-verified) |
| System-sound placeholders | **Forbidden** |

---

## Required work order

1. **Read** this file, then `AUDIO_AGENT_EXECUTION.md`, then `audio/AUDIO_INVENTORY.json`.
2. Run `make audio-check` before and after any audio change.
3. **Do not generate** until Batch 0 is present (it is) **and** owner licenses ElevenLabs for this product.
4. **Batch 1 only:** the 17 `scope: runtime_required` rows in the manifest — exact `logical_stem` / `filename`.
5. Put masters under `Resources/Audio/Masters/Runtime/`, delivery under `Resources/Audio/Delivery/Runtime/`.
6. Update manifest `status` + a new receipt under `docs/audio/` in the **same** change as binaries.
7. Never claim `runtime_integrated` without catalog + app wiring + tests + evidence.

Full batch ladder (0→14): see [`AUDIO_AGENT_EXECUTION.md`](AUDIO_AGENT_EXECUTION.md).

---

## The original 17 event-cue stems (completed Batch 1 scope)

Every row below was part of the original event-cue batch and remains live in
`audio_events.json`. The catalog has since expanded to 29 event cues and 34
state-projected loop assignments plus five shared foundation beds. The manifest,
catalog, bundle, and tests are the current machine authorities; `make audio-check`
enforces their parity and complete 68-asset runtime coverage.

| asset_id | logical_stem | integration_target |
| --- | --- | --- |
| runtime.suspicion_tier_up | `sfx_suspicion_tier_up` | `tierChanged` |
| runtime.upgrade_offered | `sfx_upgrade_offered` | `upgradeOffered` |
| runtime.upgrade_selected | `sfx_upgrade_selected` | `upgradeSelected` |
| runtime.lpr_destroyed | `sfx_lpr_destroyed` | `entityDestroyed:cameraPole` |
| runtime.weapon_fire | `sfx_weapon_fire` | `weaponFired` |
| runtime.countermeasure_hit | `sfx_countermeasure_hit` | `countermeasureHit` |
| runtime.player_damaged | `sfx_player_damaged` | `playerDamaged` |
| runtime.player_defeated | `sfx_player_defeated` | `playerDefeated` |
| runtime.boss_activated | `sfx_boss_activated` | `bossActivated` |
| runtime.extraction_opened | `sfx_extraction_opened` | `extractionOpened` |
| runtime.extraction_completed | `sfx_extraction_completed` | `extractionCompleted` |
| runtime.landmark_pressure | `sfx_landmark_pressure` | `landmarkEncounterChanged` |
| runtime.director_decision | `sfx_director_decision` | `directorDecision` |
| runtime.interactable_activate | `sfx_interactable_activate` | `interactableActivated` |
| runtime.city_state_changed | `sfx_city_state_changed` | `cityStateChanged` |
| runtime.coordination_changed | `sfx_coordination_changed` | `coordinationChanged` |
| runtime.build_synergy_changed | `sfx_build_synergy_changed` | `buildSynergyChanged` |

Prompts: copy from [`AUDIO_ASSET_MANIFEST.json`](AUDIO_ASSET_MANIFEST.json) + universal negative prompt in the production bible.

---

## Product law (non-negotiable)

- Simulation owns events; audio only projects.
- Missing asset → **silent skip**, not a system beep.
- No media inside `Sources/SurveillanceCore`.
- No speech / lyrics / branded sonic logos / real police-radio recordings for MVP.
- Reuse-and-hash before generate; Atlanta callbacks use prior-city **approved** masters later.

---

## Quick commands

```bash
make audio-check
# after binary intake also:
make validate
```

---

## Runtime integration — how all 68 assets are addressed

Two mechanisms, deliberately separate:

| Mechanism | Assets | Driver |
| --- | ---: | --- |
| **Event cues** — `AudioCueResolver` | 29 | a `RunEvent` fires; cooldown and priority per cue |
| **State projection** — `AudioSceneProjector` | 39 | 34 city/music/overlay assignments plus 5 shared foundation beds, derived from `RunState` each tick; loops persist |

Ambience and music are **state, not events**: they persist across ticks and change
when the situation changes. `AudioSceneProjector.scene(for:catalog:)` is a pure
function of `RunState`, which is the "explicit scene-state projection" that
`AUDIO_AGENT_EXECUTION.md` permits for reserved assets. It adds no simulation
state and cannot alter gameplay.

- **City bed** follows `state.district`.
- **Music** is the district's run loop, or its boss loop while an authority lives.
- **Atlanta's four phases** are selected from the deterministic core's authoritative
  `state.bossPhase`. If phase identity is absent, playback starts at phase one and
  never infers simulation state from boss health.
- **Blind Spot overlay** plays while `state.extractionOpen`.
- A completed run silences every loop; the completion stinger carries it.

### District-scoped cues

`AudioCueDefinition.districtId` lets a city contribute its own mechanic sound
without inventing a new event contract. A scoped cue **replaces** the generic one
for that event in its district, so exactly one plays rather than both.

### Shared foundation beds

The five `amb_shared_*` beds are integrated as deterministic foundation layers.
`AudioSceneDefinition.foundationAsset` selects the approved reusable bed for each
district, and `AudioSceneProjector` layers it beneath the city identity ambience.
This is presentation-only state projection and does not alter simulation behavior.
