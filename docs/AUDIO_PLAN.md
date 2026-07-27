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
| Binaries in repo | **17** runtime masters + 17 CAF derivatives (Batch 1) |
| Runtime-required stems | **17** (aligned with `audio_events.json`) |
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
