# Art QA — combat readability audit

```yaml
/* Hallmark · combat readability · code-first remediation */
verb: audit + remediate
target: EntityProjector / WorldProjector / GhostTrailPresenter + RuntimeSprites
date: 2026-07-25
branch: feat/art-qa-combat-readability
tip_base: 405190d
```

**Scope:** human-grade combat readability (hierarchy, density, shape/palette grammar, city identity without combat power from art). Not App Store copy. Not operator/device/audio license.

**Inventory-first rule:** remediations use **existing** projectors, `TextureAssetLoader`, `VisualAssetMap`, `GameAssetName`, and attached RuntimeSprites. No new asset pipeline. No full PNG re-export unless a named binary is proven broken.

---

## Failure mode

Globally noisy **valid** assets + flat z-order + colliding purple status colors. The field reads as “everything is important,” so player, shots, and Blind Spot lose primacy.

---

## Findings

### Critical

| # | Tell | Where | Remediation |
| --- | --- | --- | --- |
| C1 | **Flat entity z** — non-player kinds all at `20` | `EntityProjector.synchronize` | Layer map via `VisualCombatLayers.entityLayer` (extends prior `player?30:20`) |
| C2 | **Purple collision** — boss fill + processing tint both `systemPurple` | `EntityProjector` boss/guard branches | Boss = municipal charcoal + alarm stroke; processing = light bureaucracy violet |
| C3 | **Scan cones over bodies** — cone `zPosition = 1` on camera container | `cameraNode` | Cone at `-1` under body/accent |

### Major

| # | Tell | Where | Remediation |
| --- | --- | --- | --- |
| M1 | **Cone stack white-out** at high LPR density | scan-cone update | Density-scaled alpha from original 0.12/0.45 bases |
| M2 | **Flood field competes with FOIA yellow** | signal flood shape fallback | Density + reduced-flash soft-out on existing yellow/teal |
| M3 | **Landmark zone = Blind Spot cyan** | `WorldProjector` landmark ring | Dim cyan palette; z under combat (`0.85`) |
| M4 | **Projectile fallback is one orange disk** | `makeNode(.projectile)` | Shape taxonomy from existing `projectileStyle` (still prefer weapon stills) |

### Minor

| # | Tell | Where | Status |
| --- | --- | --- | --- |
| m1 | Ghost trail z was magic `25` | `GhostTrailPresenter` | Named constant matching prior value |
| m2 | City floors/landmarks already Hallmark-remediated | floor audit M1–M4 | Do not regress |
| m3 | PNG chroma/style stills | prior Hallmark asset audit | Code does not re-export |

---

## What we deliberately did **not** do

- Re-export RuntimeSprites or invent a second art pipeline  
- Move sim combat truth into SpriteKit  
- Touch HUD tokens (`VisualDesignTokens` remains SwiftUI-only)  
- Bake mock residents / LPR into terrain  

---

## Code touch surface (existing paths only)

| File | Role |
| --- | --- |
| `Game/Rendering/EntityProjector.swift` | z-order, palette, density soft-out, projectile fallback shapes |
| `Game/Rendering/WorldProjector.swift` | landmark zone color + z |
| `Game/Presentation/GhostTrailPresenter.swift` | z constant only |
| `Game/Rendering/VisualCombatLayers.swift` | **thin** shared constants for the three call sites above |

Assets continue to resolve through `TextureAssetLoader` → `VisualAssetMap` / `GameAssetName` with shape-node fallbacks.

---

## Verification

- Structural unit tests: layer order, density scale monotonicity, landmark under player  
- `make test` (SwiftPM + package graph)  
- Emulator visual smoke remains inventory-first (`EmulatorVisualAssetSmokeTests`)  

---

## Residual (out of band / later)

- Operator #3 device pass  
- Store listing art  
- Audio catalog license  
- Optional: still-art pass if shape taxonomy still shows after stills attach  
- Optional: city-specific cone tint (presentation only; no combat power)  
