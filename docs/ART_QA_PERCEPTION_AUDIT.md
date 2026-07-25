# Art QA — perception system package

```yaml
audit_id: art-qa-perception-2026-07-25
tip: 6a06fb1a82dfcbc4bf7a72c9c4ec6ba73d574d36
tip_short: 6a06fb1
date_utc: 2026-07-25T21:05:00Z
ship_gate: ART_EVIDENCE_INSUFFICIENT
supersedes_partial: docs/ART_QA_COMBAT_READABILITY_AUDIT.md
related:
  - docs/ART_PRODUCTION_READINESS.md
  - docs/HALLMARK_FLOOR_AUDIT.md
  - docs/HALLMARK_ASSET_AUDIT.md
  - docs/DEVICE_TEST_LOG.md
  - docs/ART_DEVICE_QA_CHECKLIST.md
  - docs/art_qa/art_qa_audit.json
```

## Executive assessment

Surveillance Survivor’s **repo art + presentation path is technically attached and hierarchy-remediated**, but **cannot ship as art-approved** without a physical iPhone pass on the current tip.

| Ladder | Repo score | Basis |
| --- | --- | --- |
| Technically valid | **PASS** | `make assets-check` 194 PNGs; weapon-vfx / animation / chroma green |
| Isolation-acceptable | **PASS (code)** | `VisualCombatLayers.entityLayer` · player 30 · projectile 35 · deployables 16 |
| Readable in motion | **PARTIAL** | Player multi-frame OBSERVED; guards/boss single-frame; **device motion NOT_COMPUTABLE** |
| Readable under combat density | **PARTIAL** | Density soft-out on `PresentationQualityTier.densityScale` + cone/flood alphas OBSERVED; **live multi-weapon stress NOT_COMPUTABLE** |
| Cohesive | **PASS (code)** | Shared `VisualCombatPalette`; boss ≠ processing purple; landmark ≠ Blind Spot cyan |
| Distinctive enough to ship | **PARTIAL** | 10 cities × 13 runtime packs present; identity under live combat density needs device |

**Final gate:** `ART_EVIDENCE_INSUFFICIENT`  
Reason: no `DEVICE_TEST_LOG` combat-readability receipt for tip `6a06fb1` (historical device smokes are older SHAs and deployment-only). Honesty rule forbids `ART_SHIP_APPROVED` without physical-iPhone evidence.

Already-landed remediations **#81 / #82** are **OBSERVED fixed in code** and must not reappear as open P0/P1 code defects.

---

## Scope & method

**In scope:** perception of combat + city playfield art as projected by existing SpriteKit paths (`EntityProjector`, `WorldProjector`, `GhostTrailPresenter`, `PresentationPipeline` / `PresentationQualityTier`, `VisualAssetMap` / `TextureAssetLoader` / `GameAssetName`).

**Out of scope:** PNG re-export, fake device receipts, audio stems, store URLs, second render pipeline.

**Evidence classes**

| Class | Meaning |
| --- | --- |
| **OBSERVED** | Named path / gate / inventory verified this tip |
| **INFERRED** | Reasonable from OBSERVED code + design docs |
| **NOT_COMPUTABLE** | Missing named artifact (listed) |

---

## Inventory (tip `6a06fb1`)

| Metric | Value | Class |
| --- | --- | --- |
| RuntimeSprites PNG count | **194** | OBSERVED `make assets-check` |
| City packs (10) | 13 each | OBSERVED |
| MVP combat stills | player / LPR / Blind Spot / guard / boss / projectile_default / deployables | OBSERVED present |
| Projectile family stills | `projectile_default`, `_redaction`, `_identity`, `_foia` | OBSERVED |
| Deployable 3-state | mirror + signal active/inactive/expended | OBSERVED |
| Core tests | 158 pass | OBSERVED `make test` |
| Physical combat QA this tip | **absent** | NOT_COMPUTABLE — missing filled `DEVICE_TEST_LOG` for `6a06fb1` |

### Ten-city matrix

| City | Runtime prefix count | Terrain/skyline path owner | Density under combat | Distinctive enough (repo) |
| --- | --- | --- | --- | --- |
| Wichita | 13 | `VisualAssetMap` / `WorldProjector` | NOT_COMPUTABLE live | PASS inventory |
| Louisville | 13 | same | NOT_COMPUTABLE live | PASS inventory |
| Tulsa | 13 | same | NOT_COMPUTABLE live | PASS inventory |
| Dayton | 13 | same | NOT_COMPUTABLE live | PASS inventory |
| Oakland | 13 | same | NOT_COMPUTABLE live | PASS inventory |
| San Francisco | 13 | same | NOT_COMPUTABLE live | PASS inventory |
| Columbus | 13 | same | NOT_COMPUTABLE live | PASS inventory |
| New York | 13 | same | NOT_COMPUTABLE live | PASS inventory |
| Los Angeles | 13 | same | NOT_COMPUTABLE live | PASS inventory |
| Atlanta | 13 | same | NOT_COMPUTABLE live | PASS inventory |

Floor Hallmark M1–M4 marked remediated in `HALLMARK_FLOOR_AUDIT.md` (prior tip); **do not regress**. Live “wallpaper vs entities” remains a **device** check.

### Six countermeasure families

| WeaponID | Presentation path | Still / fallback | Family separation (repo) |
| --- | --- | --- | --- |
| `kineticCountermeasure` | Projectile still → shape | `projectile_default` + cyan disk fallback | PASS default family |
| `redactionOrdinance` | `projectile_redaction` → bar shape | Distinct still + taxonomy | PASS |
| `identityTransponder` | `projectile_identity` → puck | Distinct still + taxonomy | PASS |
| `foiaSwarm` | `projectile_foia` → sheet shape | Distinct still + taxonomy | PASS |
| `mirrorArray` | Deployable 3-state stills | `deployable_mirror_array_*` | PASS (not projectile) |
| `signalFlood` | Deployable 3-state + density flood fill | `deployable_signal_flood_*` | PASS (area FX) |

Mapping: `GameAssetName.Projectile.asset(for:)` / `Deployable.*` · `EntityProjector.applyProjectileAppearance` / `applyDeployableAppearance`.

---

## Hierarchy scorecard (player / enemy / LPR / Blind Spot)

| Layer | z (OBSERVED) | Path |
| --- | --- | --- |
| Landmark zone | 0.85 | `VisualCombatLayers.landmarkZone` |
| Deployables | 16 | `.mirrorArray` / `.signalFlood` |
| Guard | 20 | `.securityGuard` |
| LPR / camera | 21 | `.cameraPole` (cone child z = −1 under body) |
| Boss | 22 | `.boss` |
| Extraction / Blind Spot | 24 | `.extraction` |
| Ghost trail | 25 | `GhostTrailPresenter` |
| Player | 30 | `.player` |
| Projectiles | 35 | `.projectile` |

**Acceptance condition (code):** `VisualCombatLayers.entityLayer(for: .projectile) > entityLayer(for: .player) > entityLayer(for: .boss)` — covered by `VisualCombatReadabilityTests`.

**Acceptance condition (device):** player silhouette primary; projectiles above bodies; Blind Spot ≠ landmark ring — `docs/ART_DEVICE_QA_CHECKLIST.md`.

---

## Animation vs simulation authority

| Concern | Owner | Class |
| --- | --- | --- |
| Combat truth / spawns / damage | `SurveillanceCore` Simulation | OBSERVED architecture |
| Pose interpolation / secondary motion | `PresentationPipeline` | OBSERVED |
| Quality / density soft-out | `PresentationQualityTier` (presentation-only) | OBSERVED |
| Texture swap / tint | `EntityProjector` | OBSERVED |
| Density bands calibrated to `CombatLimits.maximumProjectiles` (96) | `PresentationQualityTier.densityScale` | OBSERVED — **does not change sim caps** |

---

## Accessibility

| Setting | Behavior (OBSERVED) | Non-color signal |
| --- | --- | --- |
| `reducedMotion` | tier `.minimal`; camera smoothing off; ghost trail calmed | Motion reduced — PASS code |
| `reducedFlash` | tier `.reduced`; flood → teal low-alpha | Flood color changes; **status still color-tinted** |
| Processing / disrupt | `colorBlendFactor` tints | **Mostly color-only** on sprites — residual P2 |
| Hierarchy | z-order independent of color | PASS code |

Wiring: `GameScene.applyAccessibilitySettings` → `presentation.applyAccessibility` → `entityProjector.applyPresentationSettings(presentation.settings)`.

---

## Density-collapse analysis

**Stress model (sim caps, presentation-only soft-out):**

1. Up to **4** active weapons (`CombatLimits.maximumActiveWeapons`)
2. Up to **96** projectiles (`maximumProjectiles`)
3. Up to **8** persistent deployables
4. Many LPR scan cones + signal floods + FOIA yellow

**What fails first under multi-weapon / high-LPR stress** (ordered):

| Order | Failure mode | Status after #81/#82 | Evidence class |
| ---: | --- | --- | --- |
| 1 | Stacked **hostile scan cones** white-out asphalt | Mitigated — alpha × `densityScale` | OBSERVED code; live NOT_COMPUTABLE |
| 2 | **Signal flood** + FOIA yellow merge | Partially mitigated — density + reduced-flash teal | OBSERVED code |
| 3 | **Projectile clutter** hides bodies | Mitigated — projectiles z=35 | OBSERVED code |
| 4 | **Boss / processing purple** collision | Fixed — charcoal boss + bureaucracy violet | OBSERVED code |
| 5 | **Landmark cyan = Blind Spot** | Fixed — dim landmark cyan, z=0.85 | OBSERVED code |
| 6 | City **floor wallpaper** drowns silhouettes | Floor Hallmark remediations prior; live density NOT_COMPUTABLE | INFERRED + device gap |
| 7 | **Color-only status** (processing) under flash | Residual | OBSERVED tint path |

**Testable acceptance (repo):** `PresentationQualityTier.full.densityScale(entityCount: CombatLimits.maximumProjectiles + 1) < densityScale(entityCount: 10)` — `VisualCombatReadabilityTests` / `PresentationPipelineTests`.

**Testable acceptance (device):** max loadout p95 ≤ 16.67 ms **and** cones not white-out — `DEVICE_TEST_LOG` + ART checklist.

---

## Ranked findings ledger

### Already remediations (do not re-open as unfixed)

| ID | Was | Now | Class |
| --- | --- | --- | --- |
| FIX-C1 | Flat entity z | `VisualCombatLayers.entityLayer` | OBSERVED #81 |
| FIX-C2 | Boss+processing purple | `bossFill` / `processingTint` split | OBSERVED #81 |
| FIX-C3 | Cone over body | cone `zPosition = -1` | OBSERVED #81 |
| FIX-M1 | Cone white-out | density-scaled cone alpha | OBSERVED #81/#82 |
| FIX-M2 | Flood flash | density + reducedFlash flood | OBSERVED #81/#82 |
| FIX-M3 | Landmark = Blind Spot cyan | dim cyan + z 0.85 | OBSERVED #81 |
| FIX-M4 | Single orange projectile fallback | shape taxonomy + family stills | OBSERVED #81 |
| FIX-INFRA | Parallel density helper | `PresentationQualityTier.densityScale` + settings path | OBSERVED #82 |

### Open findings

| ID | Sev | Title | Class | Player consequence | Acceptance condition | Missing artifact if any |
| --- | --- | --- | --- | --- | --- | --- |
| F-P1-01 | **P1** | No physical iPhone combat-readability pass on tip `6a06fb1` | NOT_COMPUTABLE | Cannot confirm ship-grade readability on Retina / thermal / real density | Filled `DEVICE_TEST_LOG` combat section + ART checklist for SHA `6a06fb1` (or newer) with pass marks | Device receipt for this tip |
| F-P1-02 | **P1** | Live multi-weapon max-density visual stress unproven | NOT_COMPUTABLE | Player may still lose shots/self under real 4-weapon fire | Device run with 4 weapons + flood/mirrors; cones readable; p95 noted | Device log + optional recording |
| F-P2-01 | **P2** | Kinetic still shares `projectile_default` | OBSERVED + **waived** | Kinetic uses default hero still as family mark | Waive recorded — distinct still optional only | — |
| F-P2-02 | **P2** | Processing / disrupt color-only | **Remediated** dash+shape status ring | Status readable via silhouette/dash under limited color vision | Ring kinds differ (tests) | — |
| F-P2-03 | **P2** | Guard / boss multi-frame absent | OBSERVED stills + **probe wired** | Hostiles still-only until inventory; plumbing ready | Attach `guard_*_2…` / `boss_default_2…` or keep still | Optional multi-frame PNGs (not code) |
| F-P3-01 | **P3** | FOIA yellow vs flood yellow adjacency | **Remediated** cool teal flood | Area FX no longer same family as FOIA | Flood RGB ≠ FOIA yellow (tests) | — |
| F-P3-02 | **P3** | City distinctiveness under live combat density | INFERRED inventory + floor audit | Cities may feel similar mid-fight | Device sample ≥3 cities, identity without labels | Device notes |
| F-NOTE-01 | NOTE | Historical device smoke SHAs (`669409d`, `34a8157`) ≠ current tip | OBSERVED log | Operators may over-claim device coverage | Always log current tip SHA | — |

**No open P0 code defects** for hierarchy/palette/density after #81/#82.

---

## Technical / fallback gates

| Gate | Result | Class |
| --- | --- | --- |
| `make assets-check` | PASS 194 PNGs | OBSERVED |
| `make weapon-vfx-check` | PASS 6 weapons | OBSERVED |
| `make animation-check` | PASS 6 weapons | OBSERVED |
| `make sprite-chroma-check` | PASS max_magenta 0.05 | OBSERVED |
| `make test` (core) | PASS 158 | OBSERVED |
| Shape fallbacks if texture missing | Present in `EntityProjector` | OBSERVED |
| Sim never reads z/palette | Architecture | OBSERVED |

---

## Phased remediation roadmap

### Phase A — Done on main (#81 / #82)

- [x] Entity z hierarchy via existing projectors  
- [x] Boss / processing palette split  
- [x] Cone under body; density soft-out  
- [x] Landmark zone dim cyan  
- [x] Projectile shape taxonomy + family stills  
- [x] Density on `PresentationQualityTier` + `CombatLimits` calibration  
- [x] Structural tests `VisualCombatReadabilityTests`  

### Phase B — Operator (blocks art ship approval)

- [ ] Physical device ART + combat checklist on tip ≥ `6a06fb1`  
- [ ] Full extract + max density notes in `DEVICE_TEST_LOG`  
- [ ] Owner ship note on GitHub #3  

### Phase C — Optional polish (non-blocking if B passes)

- [x] Kinetic still: **waived for MVP** — `projectile_default` is kinetic family hero; redaction/identity/FOIA have distinct stills (repo record 2026-07-25)  
- [x] Non-color processing/disrupt badge — dashed stamp vs ellipse status ring (`VisualCombatPalette.statusRing*`, EntityProjector)  
- [x] Guard multi-frame **probe** inventory-first (`OptionalSpriteFrameCycle`) — stills until `_2…` PNGs exist (P7 art)  
- [x] Flood/FOIA chroma separation — flood cool teal haze vs FOIA yellow bolts

---

## Human ship checklist (concise)

```text
[ ] Tip SHA recorded in DEVICE_TEST_LOG
[ ] Landscape iPhone signed Debug play ≥ one full extract
[ ] Player primary over guards/LPR
[ ] Projectiles readable at density
[ ] Scan cones not white-out
[ ] Boss ≠ processing purple
[ ] Blind Spot ≠ landmark ring
[ ] Reduced flash calmer floods
[ ] Sample 3 cities identifiable without labels
[ ] Owner: ship approval yes/no on #3
```

Detail: [`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md).

---

## Ship gate decision

| Option | Selected |
| --- | --- |
| `ART_SHIP_APPROVED` | No — no tip-matched device evidence |
| `ART_SHIP_APPROVED_WITH_NONBLOCKING_NOTES` | No |
| `ART_SHIP_BLOCKED` | No — repo art is not defective-blocking; evidence is missing |
| **`ART_EVIDENCE_INSUFFICIENT`** | **Yes** |

Machine-readable twin: [`art_qa/art_qa_audit.json`](art_qa/art_qa_audit.json).

---

## Provenance

| Artifact | Path |
| --- | --- |
| Gate log | implementer scratch `art_qa_gates.log` (session) |
| Inventory | implementer scratch `art_inventory.txt` |
| Code spot-check | implementer scratch `art_qa/code_spotcheck.txt` |
| Core test log | implementer scratch `art_qa/make_test.log` |
