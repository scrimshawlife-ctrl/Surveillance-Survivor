# Gameplay animation plan (agent entry point)

**Remote agents: start here for motion / physics-informed presentation work.**

| Role | Path |
| --- | --- |
| **This plan** | `docs/GAMEPLAY_ANIMATION_PLAN.md` |
| **Production doctrine** | [`GAMEPLAY_ANIMATION_PHYSICS_PRODUCTION.md`](GAMEPLAY_ANIMATION_PHYSICS_PRODUCTION.md) |
| **Execution batches** | [`GAMEPLAY_ANIMATION_AGENT_EXECUTION.md`](GAMEPLAY_ANIMATION_AGENT_EXECUTION.md) |
| **Machine queue** | [`GAMEPLAY_ANIMATION_MANIFEST.json`](GAMEPLAY_ANIMATION_MANIFEST.json) |
| **Gate** | `make animation-check` |
| **Still weapon art** | [`WEAPON_VFX_AGENT_EXECUTION.md`](WEAPON_VFX_AGENT_EXECUTION.md) |
| **Current player atlas** | `Game/Rendering/PlayerAtlasManifest.swift` |
| **Projectors** | `Game/Rendering/EntityProjector.swift`, `WorldProjector.swift` |

---

## Doctrine in one line

**Physics-informed animation, not unrestricted physics simulation** — SpriteKit projects deterministic sim state; secondary motion is bounded and decorative.

---

## Current status

| Item | State |
| --- | --- |
| Production doctrine + agent packet | **On main** (#44) |
| Manifest + `make animation-check` | **On main** |
| Batch 0 inventory receipts | **Done** — [`animation/ANIMATION_BATCH_0_RECEIPT.md`](animation/ANIMATION_BATCH_0_RECEIPT.md) |
| Batch 1 presentation architecture | **Done** — [`animation/ANIMATION_BATCH_1_RECEIPT.md`](animation/ANIMATION_BATCH_1_RECEIPT.md) |
| Batch 2 multi-frame player | **Done** — walk 4f / idle 2f × 4 dirs (#49) · [`ANIMATION_BATCH_2_RECEIPT.md`](animation/ANIMATION_BATCH_2_RECEIPT.md) |
| Secondary-motion / interpolation layer | **Implemented** (`PresentationPipeline`) |
| Weapon P0 stills | **Runtime integrated** (#49) |
| SKPhysics gameplay | **Forbidden** / not used as authority |

---

## Work order

1. Read this plan + production doctrine + Batch 0 receipt.  
2. `make animation-check`  
3. ~~Batch 0 inventory~~ **Done**.  
4. ~~Batch 1 presentation architecture~~ **Done**.  
5. ~~Batch 2 player multi-frame~~ **Done** (#49).  
6. Optional later: enemy/boss/LPR sequences; deployable multi-state motion.  
7. Never change `SurveillanceCore` combat math for “better feel.”  

---

## P0 presentation targets (do not invent stems)

| Area | Today | Target |
| --- | --- | --- |
| Player idle/walk 4-dir | 8× single PNG | Multi-frame cycles per manifest |
| Projectile / deployable | Shape fallback (+ optional stills) | Motion clips after VFX stills |
| LPR | Static state textures | State machine + destroy sequence |
| Guards / boss | Static | Families + telegraphs later |

---

## Quick commands

```bash
make animation-check
make weapon-vfx-check
make audio-check
make validate
```
