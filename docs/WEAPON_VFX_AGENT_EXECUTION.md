# Surveillance Survivor — Weapon / Projectile / VFX Agent Execution

> **Batch receipts:** [`weapon_vfx/`](weapon_vfx/) · Batch 0 is complete when `WEAPON_VFX_BATCH_0_RECEIPT.md` exists on `main`.

## Authority

Read in this order:

1. `docs/WEAPON_SYSTEM_DESIGN.md` — gameplay and six-countermeasure authority.
2. `docs/WEAPON_VFX_ASSET_PRODUCTION.md` — creative and production contract.
3. `docs/WEAPON_VFX_ASSET_MANIFEST.json` — machine work queue and status authority.
4. `Game/Rendering/GameAssetName.swift` and `Game/Rendering/VisualAssetMap.swift` — currently registered runtime roles.

Run `make weapon-vfx-check` before and after every related change.

## Hard boundary

Only these three weapon/deployable visual stems are currently runtime-addressable:

- `projectile_default`
- `deployable_mirror_array`
- `deployable_signal_flood`

All other manifest entries are reserved production requirements. Do not mark them `runtime_integrated` unless namespace, role mapping, projector behavior, binaries, and tests land together.

Do not invent weapons beyond the canonical six:

- `kineticCountermeasure`
- `redactionOrdinance`
- `identityTransponder`
- `foiaSwarm`
- `mirrorArray`
- `signalFlood`

Deferred concepts in `WEAPON_SYSTEM_DESIGN.md` remain deferred.

## Required workflow

### Batch 0 — inventory and deduplication

1. Start with `git status --short`.
2. Inventory all PNGs in `Resources/RuntimeSprites`, `Resources/Assets.xcassets`, generated art folders, PR branches, and supplied archives.
3. Record filename, SHA-256, dimensions, alpha, frame count, semantic role, source, license, and status.
4. Compare every candidate against the manifest by both hash and semantic function.
5. Classify each manifest entry as:
   - `REUSE_EXACT`
   - `REUSE_VARIANT`
   - `COMPOSE_FROM_EXISTING`
   - `GENERATE_MISSING`
   - `REJECT_DUPLICATE`
   - `RESERVED_INTEGRATION`
6. Do not generate during Batch 0.

Deliver:

- `docs/weapon_vfx/WEAPON_VFX_INVENTORY.json`
- `docs/weapon_vfx/WEAPON_VFX_DEDUP_REPORT.md`
- `docs/weapon_vfx/WEAPON_VFX_BATCH_0_RECEIPT.md`

### Batch 1 — P0 identity candidates

Generate only:

- `runtime.projectile_default`
- `runtime.deployable_mirror_array`
- `runtime.deployable_signal_flood`

Use the exact prompts, canvases, frames, anchors, and stems from the manifest. Produce transparent PNG masters and contact sheets. Preserve shape-node fallbacks.

Do not integrate until owner approval.

### Batch 2 — P0 runtime intake

For approved P0 assets:

1. Validate dimensions, sRGB, alpha, common canvas, frame order, and anchor.
2. Place source masters under `Resources/RuntimeSprites/` or the repository-approved source location.
3. Place Xcode catalog derivatives under the exact logical stem.
4. Update the manifest status and hashes.
5. Run visual asset tests, simulator build, density smoke, and physical-iPhone readability QA.
6. Confirm collision and simulation geometry are unchanged.

### Batch 3 — canonical six-weapon identity pass

Generate identity candidates for reserved P1 assets only after P0 sign-off. These establish the six weapon families but do not become runtime-addressable automatically.

Requirements:

- distinct silhouette and motion language
- color supplementary, never sole identifier
- no city-exclusive variants
- no conventional-firearm visual dominance
- no new mechanics
- reduced-flash alternatives for pulse and reflection families

### Batch 4 — supporting FX

Produce P2 emission, trail, impact, status, destruction, extraction, and severance sequences only after the corresponding identity is approved.

Prefer modular particle textures over large flattened animations where SpriteKit can compose the effect more efficiently.

## Repository layout

```text
Resources/WeaponVFX/
  Masters/
    P0/
    Weapons/<weapon>/
    SharedFX/
  Delivery/
    P0/
    Weapons/<weapon>/
    SharedFX/

docs/weapon_vfx/
  WEAPON_VFX_INVENTORY.json
  WEAPON_VFX_DEDUP_REPORT.md
  WEAPON_VFX_BATCH_<n>_RECEIPT.md
  WEAPON_VFX_DEVICE_QA.md
```

Do not create directories containing unapproved binaries merely to imply completion.

## Receipt requirements

Every batch receipt must include:

- manifest asset IDs touched
- source prompts
- generator and settings
- source and delivery paths
- SHA-256 hashes
- dimensions, alpha, color profile, frame count, and anchors
- reuse decisions and rejected duplicates
- namespace and role changes, if any
- tests and build commands run
- simulator evidence
- physical-device evidence status
- unresolved risks
- commit and PR status

## Intake gates

An asset is not complete until:

- it maps to one manifest entry
- its role is not duplicated
- its exact stem is deterministic
- alpha and dimensions pass
- anchor and frame order are documented
- it is readable at actual landscape-iPhone gameplay scale
- a reduced-flash alternative exists where required
- simulation geometry remains authoritative
- the manifest and receipt are updated in the same change
- `make weapon-vfx-check` passes

## Prohibited shortcuts

- Do not rename a generic candidate as six different weapon assets.
- Do not recolor one projectile silhouette and call the roster complete.
- Do not create city-specific bullets.
- Do not bake trails into cores unless the manifest explicitly requires it.
- Do not replace deterministic hit logic with SpriteKit physics.
- Do not remove shape fallbacks before physical-device approval.
- Do not integrate reserved stems by hard-coding strings outside `GameAssetName` / `VisualAssetMap`.
- Do not claim device readability from contact sheets or simulator screenshots alone.
