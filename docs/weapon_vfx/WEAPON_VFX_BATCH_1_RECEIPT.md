# Weapon / VFX work receipt — Batch 1 (P0 candidates)

| Field | Value |
| --- | --- |
| Batch | **1** — P0 identity candidates only |
| Date (UTC) | 2026-07-25 |
| Runtime intake | **No** — shape fallbacks remain |
| Gameplay code | **Unchanged** |

## Mission

Generate **owner-review candidates** for the three runtime-addressable stems. Do not mark `runtime_integrated` or copy into `Resources/RuntimeSprites/` until Batch 2 + owner approval.

## Candidates

| logical_stem | Canvas | Path | SHA-256 (prefix) |
| --- | ---: | --- | --- |
| `projectile_default` | 128×128 | `Resources/WeaponVFX/Masters/P0/projectile_default_candidate_01.png` | see JSON |
| `deployable_mirror_array` | 256×256 | `Resources/WeaponVFX/Masters/P0/deployable_mirror_array_candidate_01.png` | see JSON |
| `deployable_signal_flood` | 256×256 | `Resources/WeaponVFX/Masters/P0/deployable_signal_flood_candidate_01.png` | see JSON |

Machine record: [`WEAPON_VFX_BATCH_1_CANDIDATES.json`](WEAPON_VFX_BATCH_1_CANDIDATES.json)  
Doc contact copies: `docs/weapon_vfx/candidates/`

Manifest status for these three: **`concept_generated`** (not runtime-integrated).

## Known candidate gaps (honest)

- Deployables are **single-frame** heroes; manifest allows 3 frames (inactive / active / expended) — multi-state strips deferred after owner silhouette OK.
- `deployable_signal_flood` source pass had **baked text** (“SIGNAL FLOOD”); re-edit without labels required before intake (product law: no text in runtime sprites).
- Mirror candidate may retain checker/edge fringe after keying — clean alpha before intake.
- Projectile is the cleanest silhouette; verify at 16–32px gameplay scale.
- Style is more illustrated 2.5D than nearest-neighbor city packs — owner may request pixel pass for cohesion.

## Explicit non-claims

- Not attached to Xcode asset catalog  
- Not in `RuntimeSprites` allow-list bank for gameplay  
- Collision / radii unchanged  
- Reserved P1/P2 weapon families not generated  

## Validation

```bash
make weapon-vfx-check
# PASS — concept_generated allowed; roles still registered
```

## Owner decision needed

```text
[ ] Approve silhouette set for Batch 2 intake
[ ] Request regenerate (notes: ________)
[ ] Accept shape-first forever for MVP (reject candidates)
```

## Next

Batch 2 intake only after owner approve: RuntimeSprites + imagesets + tests + device readability.  
