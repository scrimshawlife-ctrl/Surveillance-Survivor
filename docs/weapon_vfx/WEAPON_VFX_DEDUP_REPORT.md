# Weapon / VFX dedup report — Batch 0

**Generated:** 2026-07-24  
**Commit:** see `WEAPON_VFX_INVENTORY.json` → `git_commit_at_generation`  
**Authority:** [`WEAPON_VFX_AGENT_EXECUTION.md`](../WEAPON_VFX_AGENT_EXECUTION.md) · [`WEAPON_VFX_ASSET_MANIFEST.json`](../WEAPON_VFX_ASSET_MANIFEST.json)

## Summary

| Check | Result |
| --- | --- |
| PNGs scanned (excl. `.git` / `.build` / `out`) | **473** |
| Manifest entries | **20** (3 runtime-addressable P0, 17 reserved) |
| Manifest stem binary hits | **0 / 20** — all still `missing` |
| Weapon/VFX-looking orphan PNGs | **0** |
| SHA-256 duplicate groups | **144** (expected multi-location art copies) |
| Weapon/VFX hash collisions | **None** |
| P0 ready to generate candidates | **Yes** (nothing to reuse) |

**Conclusion:** There are **no** projectile / deployable / combat-FX binaries to reuse or reject. P0 must use `GENERATE_MISSING`. Batch 0 does **not** generate art. Shape-node fallbacks remain correct for runtime.

---

## Manifest P0 (runtime-addressable)

| logical_stem | inventory | batch0 decision |
| --- | --- | --- |
| `projectile_default` | missing | **GENERATE_MISSING** |
| `deployable_mirror_array` | missing | **GENERATE_MISSING** |
| `deployable_signal_flood` | missing | **GENERATE_MISSING** |

Registered in code (`GameAssetName` + `VisualAssetMap`) with `requiredForMVP: false`. Display sizes are projection-only; **simulation collision is not derived from sprites**.

---

## Reserved bank (17)

All inventory status **missing**. Batch 0 classification:

| Priority families | Decision |
| --- | --- |
| P1 weapon identity projectiles / deployables | **RESERVED_INTEGRATION** until P0 owner sign-off + Batch 3 |
| P2 FX (trails, impacts, status, extraction, etc.) | **RESERVED_INTEGRATION** until identity approved + Batch 4 |

Do not invent weapons outside the six countermeasures. Do not hard-code reserved stems into projectors.

---

## Repository PNG landscape (not weapon VFX)

| Role family | Approx. PNG count | Notes |
| --- | --- | --- |
| City foundation (10 cities) | ~410 | Often triplicated: RuntimeSprites + xcassets + docs/cities |
| Global env | ~20 | Runtime + catalog |
| Player / LPR / tiers / guard / boss / Blind Spot | remainder | Entity pack |
| README marketing | 2 | Not runtime game art |

### Duplicate hash patterns (intentional)

| Pattern | Meaning |
| --- | --- |
| RuntimeSprites + Assets.xcassets + docs/cities | City pack mirrored for runtime, catalog, and art receipt |
| RuntimeSprites + Assets.xcassets | Shared entity / env without docs third copy |
| docs/cities + Assets.xcassets | Doc/catalog pairs |

These are **not** weapon/VFX semantic duplicates. Do **not** reclassify city textures as projectiles.

---

## Rejected / deferred actions

| Action | Decision |
| --- | --- |
| Generate P0 candidates now | **Deferred to Batch 1** (after this receipt on main) |
| Integrate textures by inventing stems | **Rejected** |
| Recolor one dart into six weapons | **Rejected** (product law) |
| Mark any entry `runtime_integrated` | **Rejected** — no binaries |
| Remove shape fallbacks | **Rejected** — device QA not done |
| City-specific bullets | **Rejected** |

---

## Runtime boundary (unchanged)

```text
projectile_default
deployable_mirror_array
deployable_signal_flood
```

Only these three may become runtime-integrated after owner approval + intake. All other manifest IDs need namespace + map + tests together.

---

## Next dedup gate

Re-run after any P0 master lands under `Resources/WeaponVFX/` or `Resources/RuntimeSprites/`. Update inventory hashes in the same change.
