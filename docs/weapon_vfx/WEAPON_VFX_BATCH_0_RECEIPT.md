# Weapon / VFX work receipt — Batch 0

| Field | Value |
| --- | --- |
| Batch | **0** — Inventory and deduplication |
| Date (UTC) | 2026-07-24 |
| Agent | Grok Build |
| Base | `main` at Batch 0 start (see inventory `git_commit_at_generation`) |
| Generation | **None** |
| Runtime roles changed | **No** |
| Gameplay code changed | **No** |

## Mission

Execute Batch 0 only from [`WEAPON_VFX_AGENT_EXECUTION.md`](../WEAPON_VFX_AGENT_EXECUTION.md): inventory, SHA-256, classify reuse, write receipts. **Do not generate** P0 art in this batch.

## Deliverables

| Artifact | Path | Status |
| --- | --- | --- |
| Inventory | [`WEAPON_VFX_INVENTORY.json`](WEAPON_VFX_INVENTORY.json) | Written |
| Dedup report | [`WEAPON_VFX_DEDUP_REPORT.md`](WEAPON_VFX_DEDUP_REPORT.md) | Written |
| This receipt | [`WEAPON_VFX_BATCH_0_RECEIPT.md`](WEAPON_VFX_BATCH_0_RECEIPT.md) | Written |
| Media tree scaffold | `Resources/WeaponVFX/{Masters,Delivery}/…` | Empty `.gitkeep` only |

## Findings

1. **473** PNGs in repo; **0** match any of the **20** manifest `logical_stem`s.
2. Manifest statuses remain **`missing`** for all entries (validator: 20 assets, 3 runtime roles, 6 weapons).
3. P0 stems registered in `GameAssetName` / `VisualAssetMap` with shape fallbacks; **no** binary bank.
4. **144** duplicate-hash groups are expected multi-path copies of city/env/entity art — **not** weapon VFX.
5. No weaponish orphan candidates under names containing projectile / deployable / weapon / vfx.

## Manifest IDs touched

**None** (no status promotions; no hashes to record on entries).

### P0 classification (all GENERATE_MISSING)

| asset_id | logical_stem | canvas | frames |
| --- | --- | --- | --- |
| runtime.projectile_default | `projectile_default` | 128×128 | 1 |
| runtime.deployable_mirror_array | `deployable_mirror_array` | 256×256 | 3 |
| runtime.deployable_signal_flood | `deployable_signal_flood` | 256×256 | 3 |

Prompts: verbatim in [`WEAPON_VFX_ASSET_MANIFEST.json`](../WEAPON_VFX_ASSET_MANIFEST.json).

## Reused / rejected

| Kind | Count |
| --- | --- |
| REUSE_EXACT | 0 |
| REUSE_VARIANT | 0 |
| REJECT_DUPLICATE | 0 |
| GENERATE_MISSING (P0) | 3 |
| RESERVED_INTEGRATION | 17 |

## Provenance / generator

N/A — no candidates generated.

## Validation

```bash
make weapon-vfx-check
# weapon-vfx-check: PASS — 20 assets, 3 runtime roles, 6 canonical weapons
```

Also clean tree aside from this batch’s docs + empty dirs.

## Explicit non-claims

- P0 art is **not** generated or integrated.
- Shape fallbacks remain authoritative.
- Collision / combat remain simulation-owned.
- Device readability / reduced-flash **not** started.
- Reserved six-weapon identity pack **not** started (Batch 3+).

## Unresolved (handoff)

| Item | Owner / next |
| --- | --- |
| Batch 1: generate 3 P0 silhouette candidates only | Art agent (after this receipt on main) |
| Owner review of candidates | Owner — **before** Batch 2 intake |
| Batch 2: runtime intake + tests + device QA | Engineering + operator |
| Physical max-density + reduced-flash | Device (#3 / RELEASE_READINESS) |

## Batch 1 entry criteria

1. This Batch 0 receipt on `main`.
2. Exact prompts/canvases/frames/anchors from manifest.
3. Masters under `Resources/WeaponVFX/Masters/P0/` (candidates only).
4. **Do not** remove shape fallbacks; **do not** mark `runtime_integrated`.
5. Contact sheets for owner review.
6. `make weapon-vfx-check` still green.

## Changed files (this batch)

- `docs/weapon_vfx/WEAPON_VFX_INVENTORY.json`
- `docs/weapon_vfx/WEAPON_VFX_DEDUP_REPORT.md`
- `docs/weapon_vfx/WEAPON_VFX_BATCH_0_RECEIPT.md`
- `docs/weapon_vfx/README.md`
- `Resources/WeaponVFX/**/.gitkeep` (empty contract dirs)
- Status board / plan links as needed
