# Architecture isolation audit — 2026-08-05

**Audit:** D (architecture / sim-isolation)  
**Program:** post-merge audit program C→D→B→A  
**Prior:** C hygiene @ tip parent; this freeze after C commit  

## Tip freeze

- branch: `main`
- note: C froze `5e76990`; D runs after C docs commit. Isolation verdict applies to product tree on main post-#156/#159 (UrbanDress + 341 sprites). Re-read `git rev-parse --short HEAD` at D commit time.

## Ownership map

| Layer | Paths | Owns | Must not own |
| --- | --- | --- | --- |
| Core | `Sources/SurveillanceCore/**` | sim time, entities, AABB collision, damage, spawns, content layout | pixels, frame indices as hits |
| Presentation | `Game/Presentation/**` | UrbanDress inference, pose buffer, secondary motion, quality tier **display** caps | mutating RunState / combat resolution |
| Rendering | `Game/Rendering/**` | sprites, terrain carpet, frame cycles, layer nodes | hit timing / damage |
| Scenes | `Game/Scenes/**` | input, camera scale 1.38 | authoritative range/damage |

## Anti-pattern search pack

| Search | Hits | Assessment |
| --- | --- | --- |
| `SKPhysics` / physics bodies in Game/App | **none** | PASS |
| Presentation `RunState` / `SimulationEngine` / `applyDamage` | none on those symbols | PASS |
| Presentation `projectile` mentions | `PresentationQualityTier` uses `CombatLimits.maximumProjectiles` for **LOD tier only**; `PresentationPipeline` / `EntityAnimationState` classify projectile for **pose rules** | PASS (review: no combat mutation) |
| `OptionalSpriteFrameCycle` / EntityProjector `frameName` | texture stem selection only | PASS |
| RNG in `Game/Presentation` | **none** | PASS |
| `navigablePerimeterMargin` | Core `DistrictGenerator` only | sim/content |
| `satelliteCameraScale` 1.38 | `GameScene` camera only | presentation |

## Contract reads

### DistrictGenerator
`navigablePerimeterMargin = 220` expands layout **bounds** after profile obstacles/sensors are placed — free ring before hard wall. Content 1.5× arenas live in `districts.json`. **Sim/content ownership.**

### UrbanDressBuilder
`static func build(layout:district:)` pure inference from obstacle AABBs; no RNG matches. **Presentation.**

### WorldProjector
Ground: city tint + gapless terrain carpet (`baseSize` 256, `coverage: .full`, nearest filter) under UrbanDress roads/sidewalks/buildings. Walkability not derived from textures. **Presentation.**

### OptionalSpriteFrameCycle
`probeLimit = 16`; `frameName` chooses catalog stems for multi-frame banks. **Presentation only.**

### Tests encoding contracts
- `SimulationTests.wichitaPreservesTheVerticalSliceLayout` — scaled bounds + perimeter margin  
- `UrbanDressBuilderTests` — determinism, non-overlap roads/footprints  
- `WorldProjectorUrbanDressTests` — layer node structure  

## Isolation verdict

- Core owns combat truth: **PASS**
- UrbanDress is pure projection input: **PASS**
- Asset frames do not drive hit timing: **PASS**

## Findings

| Severity | Claim | Evidence | Disposition |
| --- | --- | --- | --- |
| Info | Quality tier reads `CombatLimits.maximumProjectiles` | `PresentationQualityTier.swift` | Accept — display LOD constant, not mutation |
| Info | #156 scaled arenas + perimeter are sim content | `districts.json`, `DistrictGenerator` | Documented; not a bug |
| Info | Camera 1.38 is presentation zoom | `GameScene.satelliteCameraScale` | Not sim range |

## Non-claims

- No art beauty judgment (Audit B)  
- No ship READY / freeze decision (Audit A)  
- No product code changes in this audit  
