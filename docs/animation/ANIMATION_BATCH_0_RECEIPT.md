# Gameplay animation work receipt — Batch 0

| Field | Value |
| --- | --- |
| Batch | **0** — Inventory and presentation audit |
| Date (UTC) | 2026-07-24 |
| Agent | Grok Build |
| Base | `main` @ inventory generation SHA (see inventory) |
| Art generated | **None** |
| Gameplay / presentation code changed | **No** |
| Runtime roles expanded | **No** |

## Mission

Execute Batch 0 only from [`GAMEPLAY_ANIMATION_AGENT_EXECUTION.md`](../GAMEPLAY_ANIMATION_AGENT_EXECUTION.md): inventory frames, atlases, projectors; map sim → presentation; classify manifest rows. **No art generation. No unrestricted physics.**

## Deliverables

| Artifact | Path | Status |
| --- | --- | --- |
| Inventory | [`ANIMATION_INVENTORY.json`](ANIMATION_INVENTORY.json) | Written |
| Dedup report | [`ANIMATION_DEDUP_REPORT.md`](ANIMATION_DEDUP_REPORT.md) | Written |
| This receipt | [`ANIMATION_BATCH_0_RECEIPT.md`](ANIMATION_BATCH_0_RECEIPT.md) | Written |
| Index | [`README.md`](README.md) | Written |

## Findings

1. **Player:** 8 single-frame PNGs registered; all unique hashes; multi-frame targets unmet.  
2. **Architecture:** no snapshot interpolation buffer, no secondary-motion component, no quality-tier system; reduced-motion/flash toggles exist with **partial** application (camera snap; signalFlood shape colors).  
3. **Entities:** direct position projection + texture/shape swaps; node pooling present.  
4. **Weapon stills:** P0 deployable/projectile binaries **missing** (weapon VFX track); shape fallbacks active.  
5. **Manifest:** 27 clips — 8 reuse stills, 3 Batch-1 code, 1 procedural later, 15 generate/implement later.  
6. **Law:** no `SKPhysics` gameplay authority under `Game/`.

## Manifest IDs / decisions

| Group | Decision |
| --- | --- |
| `player.idle.*` / `player.walk.*` (8) | REUSE_EXACT_STILL → expand Batch 2 |
| `arch.*` (3) | IMPLEMENT_IN_BATCH_1 |
| `env.secondary.lights` | PROCEDURAL_LATER |
| Remaining 15 | GENERATE_OR_IMPLEMENT_LATER (after arch / VFX stills as applicable) |

Manifest **statuses unchanged** this batch (no binary intake).

## Validation

```bash
make animation-check
# animation-check: PASS — 27 clips, 9 non-missing statuses, physics_informed, 6 weapons
```

## Explicit non-claims

- Multi-frame animation is **not** implemented.  
- Presentation architecture Batch 1 is **not** implemented.  
- Weapon motion is **not** ready (stills missing).  
- Device readability of future multi-frame banks is **not** started.

## Unresolved (handoff)

| Item | Next |
| --- | --- |
| Batch 1 presentation architecture | Code: interp, SM, secondary motion, tiers + tests |
| Batch 2 player multi-frame | Art + atlas frameCount after Batch 1 preferred |
| Weapon flight/impact motion | After weapon-VFX P0 stills + owner |
| LPR/guard/boss/Blind Spot sequences | Later batches |
| Max-density + reduced-motion device QA | Operator |

## Batch 1 entry criteria

1. This receipt on `main`.  
2. `make animation-check` green.  
3. Implement architecture without changing `SurveillanceCore` combat.  
4. Tests prove interpolation/secondary motion do not alter sim outcomes.  
5. Keep shape fallbacks and existing single-frame player bank.

## Changed files (this batch)

- `docs/animation/*`  
- Status board updates (`CONTINUATION_PLAN`, `REPO_STATUS`, plan entry) as needed  
