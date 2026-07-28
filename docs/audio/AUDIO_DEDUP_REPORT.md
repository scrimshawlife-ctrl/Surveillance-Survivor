# Audio dedup report — Batch 0

> **Historical report — counts below are as of commit `b5e5228` (2026-07-24) and are
> deliberately not updated.** The manifest now holds **68 assets / 17 `runtime_required`
> stems**. Current scope: [`../AUDIO_PLAN.md`](../AUDIO_PLAN.md).

**Generated:** 2026-07-24 (UTC from inventory)  
**Commit:** see `AUDIO_INVENTORY.json` → `git_commit`  
**Authority:** [`AUDIO_AGENT_EXECUTION.md`](../AUDIO_AGENT_EXECUTION.md) · [`AUDIO_ASSET_MANIFEST.json`](../AUDIO_ASSET_MANIFEST.json)

## Summary

| Check | Result |
| --- | --- |
| Binary audio files under repo (excl. `.git`/`.build`) | **0** |
| SHA-256 duplicate groups | **None** (no binaries) |
| Orphan binaries (not in manifest) | **None** |
| Manifest entries still `missing` | **62 / 62** |
| Runtime catalog ↔ runtime_required stems | **Aligned** (11 / 11) |
| Semantic duplicate candidates among existing files | **N/A** — no files to compare |

**Conclusion:** There is nothing to reuse, reject, or hash-dedup. Batch 1 must *generate* all 11 `runtime_required` stems after owner license approval. Do not invent placeholder WAVs or system-sound substitutes.

---

## Search performed

- Extensions: `.wav`, `.mp3`, `.m4a`, `.aiff`, `.aif`, `.caf`, `.aac`, `.ogg`, `.flac`, `.opus`
- Skipped: `.git`, `.build`, `DerivedData`, `node_modules`, `.codebase-memory`
- Roots walked: repository root (source, `Resources/`, `App/`, `Game/`, `docs/`, `Tests/`, `out/`, etc.)

No matches.

---

## Manifest vs runtime catalog

| Stem | In `audio_events.json` | Manifest scope | Binary |
| --- | --- | --- | --- |
| `sfx_suspicion_tier_up` | yes | runtime_required | missing |
| `sfx_upgrade_offered` | yes | runtime_required | missing |
| `sfx_upgrade_selected` | yes | runtime_required | missing |
| `sfx_lpr_destroyed` | yes | runtime_required | missing |
| `sfx_weapon_fire` | yes | runtime_required | missing |
| `sfx_countermeasure_hit` | yes | runtime_required | missing |
| `sfx_player_damaged` | yes | runtime_required | missing |
| `sfx_player_defeated` | yes | runtime_required | missing |
| `sfx_boss_activated` | yes | runtime_required | missing |
| `sfx_extraction_opened` | yes | runtime_required | missing |
| `sfx_extraction_completed` | yes | runtime_required | missing |

- Catalog stems missing from manifest: **none**
- Runtime-required stems missing from catalog: **none**
- Catalog stems outside runtime_required scope: **none**

Reserved bank (51 assets): ambience, music, city mechanics, Atlanta boss phases — all `missing`, intentionally unintegrated until deterministic hooks + tests exist.

---

## Playback layer check

| Item | Finding |
| --- | --- |
| `Game/Feedback/AudioCuePlayer.swift` | Dry-run resolver; `availableAssets` defaults empty |
| System / UIKit sound fallback | **None** (product law preserved) |
| Core package binaries | **None** (correct — media must not live in SurveillanceCore) |

---

## Reuse policy going forward (Atlanta callbacks)

When later city batches exist:

1. Hash-audit every new master before commit.
2. Reject any file whose SHA-256 matches an approved master under a different stem.
3. Atlanta convergence **must** layer / filter / spatialize **prior-city approved masters**, not regenerate imitations.
4. Reject semantic duplicates (same role, different city filename) unless the production bible explicitly requires a city-identity layer.

At Batch 0 there are **no** approved masters to callback from.

---

## Rejected / deferred actions

| Action | Decision |
| --- | --- |
| Generate ElevenLabs candidates now | **Deferred** — needs owner license + Batch 0 complete (this report) |
| Commit silent placeholder WAVs | **Rejected** — would fake inventory completeness |
| Use iOS system sounds | **Rejected** — product law |
| Mark any manifest entry `runtime_integrated` | **Rejected** — no binaries, no device evidence |

---

## Next dedup gate

Re-run this report after any binary lands under `Resources/Audio/`. Update `AUDIO_INVENTORY.json` hashes in the same change.
