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
| **Media trees** | `Resources/Audio/` — Runtime populated, Shared/Cities empty |
| **Playback** | `Game/Feedback/AudioBank.swift` (engine) · `AudioCuePlayer.swift` (resolution) |
| **Gate** | `make audio-check` |

Also listed in root [`AGENTS.md`](../AGENTS.md) and [`README.md`](../README.md) documentation tables.

---

## Current status (do not invent binaries)

| Item | State |
| --- | --- |
| Batch **0** — inventory / hash / dedup / receipts | **Done** → [`audio/AUDIO_WORK_RECEIPT.md`](audio/AUDIO_WORK_RECEIPT.md) |
| Binaries in repo | **68** masters + 68 CAF derivatives (all batches) |
| Runtime-required stems | **63** (aligned with `audio_events.json` schema 2) |
| Batch **1** — generate 17 stems | **Done** → [`audio/AUDIO_WORK_RECEIPT_BATCH1.md`](audio/AUDIO_WORK_RECEIPT_BATCH1.md) |
| Product playback | **Live** — `AudioBank` loads 17/17 delivery cues and plays them (simulator-verified) |
| System-sound placeholders | **Forbidden** |

---

## Required work order

1. **Read** this file, then `AUDIO_AGENT_EXECUTION.md`, then `audio/AUDIO_INVENTORY.json`.
2. Run `make audio-check` before and after any audio change.
3. **Do not generate** until Batch 0 is present (it is) **and** owner licenses ElevenLabs for this product.
4. **Batch 1 only:** the 11 `scope: runtime_required` rows in the manifest — exact `logical_stem` / `filename`.
5. Put masters under `Resources/Audio/Masters/Runtime/`, delivery under `Resources/Audio/Delivery/Runtime/`.
6. Update manifest `status` + a new receipt under `docs/audio/` in the **same** change as binaries.
7. Never claim `runtime_integrated` without catalog + app wiring + tests + evidence.

Full batch ladder (0→14): see [`AUDIO_AGENT_EXECUTION.md`](AUDIO_AGENT_EXECUTION.md).

---

## The 11 runtime stems (Batch 1 target)

| asset_id | logical_stem |
| --- | --- |
| runtime.suspicion_tier_up | `sfx_suspicion_tier_up` |
| runtime.upgrade_offered | `sfx_upgrade_offered` |
| runtime.upgrade_selected | `sfx_upgrade_selected` |
| runtime.lpr_destroyed | `sfx_lpr_destroyed` |
| runtime.weapon_fire | `sfx_weapon_fire` |
| runtime.countermeasure_hit | `sfx_countermeasure_hit` |
| runtime.player_damaged | `sfx_player_damaged` |
| runtime.player_defeated | `sfx_player_defeated` |
| runtime.boss_activated | `sfx_boss_activated` |
| runtime.extraction_opened | `sfx_extraction_opened` |
| runtime.extraction_completed | `sfx_extraction_completed` |

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

## Runtime integration — how the 63 are addressed

Two mechanisms, deliberately separate:

| Mechanism | Assets | Driver |
| --- | ---: | --- |
| **Event cues** — `AudioCueResolver` | 29 | a `RunEvent` fires; cooldown and priority per cue |
| **State projection** — `AudioSceneProjector` | 34 | derived from `RunState` each tick; loops persist |

Ambience and music are **state, not events**: they persist across ticks and change
when the situation changes. `AudioSceneProjector.scene(for:catalog:)` is a pure
function of `RunState`, which is the "explicit scene-state projection" that
`AUDIO_AGENT_EXECUTION.md` permits for reserved assets. It adds no simulation
state and cannot alter gameplay.

- **City bed** follows `state.district`.
- **Music** is the district's run loop, or its boss loop while an authority lives.
- **Atlanta's four phases** are selected from the boss's remaining health fraction,
  so a phased fight steps forward without the deterministic core gaining a phase
  concept it does not have.
- **Blind Spot overlay** plays while `state.extractionOpen`.
- A completed run silences every loop; the completion stinger carries it.

### District-scoped cues

`AudioCueDefinition.districtId` lets a city contribute its own mechanic sound
without inventing a new event contract. A scoped cue **replaces** the generic one
for that event in its district, so exactly one plays rather than both.

### Still unintegrated — 5 assets, honestly

The five `amb_shared_*` district beds have no driver and are **not** integrated.
They are authored as reusable foundations for layering under city ambience, so
they need a mixing decision — how they combine with a city bed — that no event or
state currently expresses. Integrating them would mean inventing that policy.
