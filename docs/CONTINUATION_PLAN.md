# Continuation plan

**Product sequencing:** [`ROADMAP.md`](ROADMAP.md)  
**Live board:** [`REPO_STATUS.md`](REPO_STATUS.md)  
**Device evidence:** [`RELEASE_READINESS.md`](RELEASE_READINESS.md)  
**ART inventory:** [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md)

## Current vertical-slice state

Implemented on `main`:

- Fixed-step, seeded simulation with structured run receipts  
- The Ghost, Suspicion tiers, Contract Security, automated surveillance, Shift Manager, Blind Spot extraction  
- Six MVP countermeasures, twelve base upgrades, four evolutions  
- Catalog-backed integrity, guard/boss contact, non-extract defeat  
- Sensor disable/disrupt freeze  
- SpriteKit projection, stick input, accessibility, haptics, summary persistence, pause/resume  
- `VisualAssetMap` + runtime player/LPR/Blind Spot/tiers/guard/boss  
- Global environment package v1 + **all ten city foundation packs** (13 each; 160 PNGs)  
- Audio event-map + ElevenLabs manifest/queue/`make audio-check` (binaries still missing)  
- **Audio Batch 0** complete: inventory / dedup / receipts under [`audio/`](audio/) · plan entry [`AUDIO_PLAN.md`](AUDIO_PLAN.md)  
- Weapon/VFX production prompt + machine manifest + execution packet + `make weapon-vfx-check` (P0 binaries still missing)  
- **Weapon/VFX Batch 0** complete: inventory / dedup / receipts under [`weapon_vfx/`](weapon_vfx/) (0 stem hits; shape fallbacks remain)  
- **Gameplay animation doctrine** — physics-informed presentation (not unrestricted physics): plan + manifest + `make animation-check`  
- **Animation Batch 0** complete: inventory / presentation audit under [`animation/`](animation/)  
- **Animation Batch 1** complete: presentation pipeline (pose buffer, SM, secondary motion, quality tiers)  
- Campaign unlocks + emulator extraction/campaign smokes  
- CI core-tests + simulator  

**Not release-ready** until device acceptance, ART device QA/owner decisions, store owner fields, and (for full product audio) approved stems exist.

## Authority boundaries

```text
SurveillanceCore  → deterministic state, content, combat, receipts
SpriteKit         → projects snapshots; no gameplay truth
SwiftUI           → lifecycle, HUD, a11y, overlays, receipt persistence
```

## Engineering priorities (aligned with roadmap)

### 1. Physical-device acceptance (P2 · issue #2)

Follow [`RELEASE_READINESS.md`](RELEASE_READINESS.md) + [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md).  
`make device-smoke` is deploy-only, not acceptance.

### 2. ART sign-off (P3 · issue #3)

Inventory is largely complete — see [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md).  
Remaining: device readability pass; projectile/deployable shape-first decision; owner ship note.

#### Weapon/VFX production sequence

1. Run `make weapon-vfx-check`, then inventory and SHA-256 audit all existing projectile, deployable, impact, field, and extraction visual files.
2. Follow [`WEAPON_VFX_AGENT_EXECUTION.md`](WEAPON_VFX_AGENT_EXECUTION.md) and reconcile against [`WEAPON_VFX_ASSET_MANIFEST.json`](WEAPON_VFX_ASSET_MANIFEST.json); mark exact and semantic duplicates before generation.
3. Produce P0 assets first: `projectile_default`, `deployable_mirror_array`, and `deployable_signal_flood`.
4. Review P0 silhouettes at actual landscape-iPhone gameplay scale before animation expansion or runtime intake.
5. Produce canonical identity concepts for all six countermeasures using [`WEAPON_VFX_ASSET_PRODUCTION.md`](WEAPON_VFX_ASSET_PRODUCTION.md), without adding reserved roles to runtime.
6. Expand reserved projectiles, swarm agents, impacts, fields, and Blind Spot FX only when namespace, `VisualAssetMap`, projectors, manifests, and tests are updated together.
7. Preserve shape-node fallbacks and simulation-owned collision/radius/cadence authority.
8. Require reduced-flash variants and maximum-density physical-device evidence before final approval.
9. Run `make weapon-vfx-check` after every manifest, namespace, role, or binary intake change.

#### Gameplay animation / physics-informed presentation

Doctrine: **physics-informed animation**, not unrestricted physics. See [`GAMEPLAY_ANIMATION_PLAN.md`](GAMEPLAY_ANIMATION_PLAN.md).

1. Run `make animation-check`.
2. ~~Batch 0 inventory~~ **Done** — [`animation/ANIMATION_BATCH_0_RECEIPT.md`](animation/ANIMATION_BATCH_0_RECEIPT.md).
3. ~~Batch 1 architecture~~ **Done** — [`animation/ANIMATION_BATCH_1_RECEIPT.md`](animation/ANIMATION_BATCH_1_RECEIPT.md); `Game/Presentation/*`.
4. Batch 2+: multi-frame player cycles, then weapon/camera/enemy motion — never change sim hitboxes or trajectories for “feel.”
5. Pair motion with weapon VFX stills; do not re-author silhouettes under animation filenames.
6. Reduced-motion / reduced-flash and max-density device evidence before sign-off.

### 3. Product audio (P4)

1. ~~Batch 0: inventory/dedup/receipts~~ **Done** — [`audio/AUDIO_WORK_RECEIPT.md`](audio/AUDIO_WORK_RECEIPT.md)  
2. Owner license review of ElevenLabs candidates  
3. Batch 1: exact 11 `runtime_required` stems  
4. Integrate playback; keep silent fallback until masters approved  

Never ship system-sound placeholders as product audio.  
`make audio-check` before/after audio work.

### 4. Store listing (P5)

Owner completes [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md): live privacy/support URLs, SKU, copyright, age rating, screenshots from release build, ASC privacy answers.

### 5. Optional polish (P7)

Five-district atlases, Atlanta boss-phase env overlays, reserved entity art, city music/ambience packages.

## Emulator-first while device offline

```bash
make emulator-test
# or CI-parity:
make validate
```

Does **not** replace physical-device acceptance.

## Current next frontier

**Autonomous / offline**

1. Keep docs boards accurate (this file, REPO_STATUS, ROADMAP).  
2. ~~Weapon/VFX Batch 0~~ **Done**; ~~Batch 1 candidates~~ **Done** — owner review then Batch 2 intake.  
3. ~~Animation Batch 0–1~~ **Done** — next: Batch 2 multi-frame player after art priority.  
4. Audio Batch 1 only after owner ElevenLabs license OK (see [`AUDIO_PLAN.md`](AUDIO_PLAN.md) + Batch 0 receipt).  
5. Reserved six-weapon identity / multi-frame motion only after P0 owner sign-off + namespace/map/tests.  

**Operator-required**

1. Device acceptance (#2).  
2. ART device QA + P0 weapon/VFX ship decision (#3).  
3. Privacy/support URLs + store fields.  
4. ElevenLabs license approval before Audio Batch 1 generation.  

## Required local gate

```bash
make audio-check
make weapon-vfx-check
make animation-check
make validate
```

Do not commit generated `SurveillanceSurvivor.xcodeproj/` or `.codebase-memory/`.
