# Urban arena presentation — cohesive city-grid dress

**Date:** 2026-08-02  
**Product:** Surveillance Survivor  
**Status:** Design approved (brainstorm)  
**Approach:** **A — Presentation-first urban dress** (infer streets/sidewalks from existing `WorldLayout`; procedural building depth; simulation/collision unchanged)

**Related:** execution goal *Rebuild Arenas as Cohesive Urban City Grids* (full Core city-grid generation **out of scope** for this design); recent calm-floor pass `5bcbbe4`; dual-lane law in `AGENTS.md`.

---

## 1. Purpose, success, non-goals

### Purpose

Make every district arena **read as a coherent top-down urban grid**: blocks of buildings, streets between them, sidewalks at building edges — not a collage of noisy terrain stamps and flat landmark cards on random pads.

### Success (this design)

| Criterion | Pass means |
| --- | --- |
| Urban read | Free space reads as **roads**; obstacle AABBs read as **blocks/buildings** with sidewalk rings |
| Continuity | No unexplained gaps of pure void; continuous base surface |
| Buildings | No opaque rectangular canvases; pads are solid city-tint **or** legitimate art with alpha; procedural depth stack (foundation/body/shadow/optional roof) |
| Streets | Connected corridors of free space; intersections where free bands meet; optional crosswalk/lane marks |
| Hierarchy | Walkable vs blocked is readable at a glance |
| Determinism | Same `WorldLayout` + district → same presentation |
| Sim contract | Obstacle AABBs, bounds, spawns, sensors, combat **unchanged** |
| Scope | Works for **all 10** districts without per-city one-off hacks |

### Non-goals (explicitly deferred)

- Rewriting `DistrictGenerator` / `districts.json` obstacle graphs into a Core `UrbanCellType` sim map  
- Changing collision, pathfinding, or entity movement rules  
- Full multi-sprite architectural building kits for every city  
- Replacing mechanics or expanding weapons/cities  
- “Giant background photo” floor that hides layout defects  
- Stretching/blurring pixel art  

**Later track (not this design):** optional Core city-grid generation that *produces* `WorldLayout` from blocks/roads.

---

## 2. Current system (audit)

```text
districts.json (ObstacleBlueprint AABBs)
        ↓
DistrictGenerator → WorldLayout { bounds, obstacles[] }
        ↓
Simulation (collision vs obstacle AABBs)
        ↓
WorldProjector (presentation only)
  ├── asphalt base + sparse terrain stamps
  ├── obstacle pads (city tint / retail skin)
  ├── parking lines | lane ticks
  ├── city wayfinding overlays
  ├── ≤2 ground decals
  └── ≤2 perimeter landmarks
```

### Root causes of defects

| Defect | Cause |
| --- | --- |
| Fragmented / busy floors | Terrain stamp wallpaper + dual layers + mid-field overlays/decals (partially calmed in `5bcbbe4`, still not “streets”) |
| Flat buildings | Pads without sidewalk/street grammar; landmark art previously squashed onto pads |
| Opaque squares | Landmark/prop PNGs with baked backgrounds or wrong alpha |
| No street network | Sim never models roads; projector never inferred free-space corridors |
| Weak city structure | No presentation model of block vs road vs sidewalk |

### Dependency map (target)

```text
LevelDefinition / DistrictID
    ↓
DistrictGenerator  →  WorldLayout (UNCHANGED sim truth)
    ↓
UrbanDressBuilder  →  UrbanDress (presentation geometry, pure/deterministic)
    ↓
WorldProjector (refactored layers)
    ├── GroundLayer (base fill)
    ├── StreetLayer (road bands + markings)
    ├── SidewalkLayer (rings around buildings)
    ├── BuildingLayer (depth stack per obstacle)
    ├── PropLayer (sparse decals, ≤2 landmarks)
    ├── WayfindingLayer (calmed)
    └── EntityLayer (existing GameScene / EntityProjector — unchanged ownership)
```

---

## 3. Architecture

### 3.1 Simulation (no change required)

| Type | Role |
| --- | --- |
| `WorldBounds` | Arena extents |
| `WorldObstacle` | AABB footprint (center + halfSize) — **collision truth** |
| `WorldLayout` | bounds + obstacles |
| `DistrictGenerator` | seed + district → layout + sensors |

Presentation must **never** derive collision from sprite pixels or `UrbanDress` cells.

### 3.2 Presentation model (new)

Add a pure, deterministic builder (prefer `Game/Presentation/` or `Game/Rendering/` — presentation only, no `SurveillanceCore` mutation):

```text
UrbanDressBuilder.build(layout: WorldLayout, district: DistrictID) -> UrbanDress
```

**Suggested types** (names may match house style):

```swift
enum UrbanSurfaceKind {
    case voidMask      // outside bounds (if needed)
    case groundFill    // continuous base under everything
    case road
    case intersection
    case sidewalk
    case buildingPad   // maps 1:1 to WorldObstacle id
    case alley         // optional narrow free band between pads
    case plaza         // optional open free region
}

struct UrbanDress: Equatable {
    var bounds: WorldBounds
    var roads: [UrbanRect]           // free-space corridors
    var intersections: [UrbanRect]
    var sidewalks: [UrbanRect]       // rings / bands around buildings
    var buildings: [UrbanBuildingDress]
    var alleys: [UrbanRect]
}

struct UrbanBuildingDress: Equatable {
    var obstacleID: UInt64
    var footprint: UrbanRect         // = obstacle AABB in world space
    var sidewalkOuter: UrbanRect     // footprint expanded by sidewalk width
    var district: DistrictID
}
```

`UrbanRect` = axis-aligned world rect (or reuse a small local struct). All construction from layout only — **no RNG** (or only seed-stable hash of obstacle ids/district if variation is required; prefer no RNG).

### 3.3 Inference algorithm (deterministic)

Given `layout.obstacles` and `layout.bounds`:

1. **Building footprints**  
   Each obstacle → `UrbanBuildingDress.footprint` (exact AABB).

2. **Sidewalk rings**  
   Expand each footprint by `sidewalkWidth` (constant, e.g. 12–18 world units; district override table allowed as pure constants).  
   Sidewalk = expanded rect minus footprint; clip to bounds; subtract other footprints.

3. **Road network (free space)**  
   - World bounds interior minus (all footprints ∪ sidewalks) is candidate free space.  
   - Extract **axis-aligned free bands** as roads: horizontal and vertical corridors with width ≥ `minRoadWidth` spanning between obstacles / bounds.  
   - Where a horizontal and vertical road band overlap → **intersection** rect.  
   - Remaining free pockets that are long and thin between two pads → optional **alley**.  
   - Larger free open areas → **plaza** (optional; may just leave as road fill).

4. **Connectivity check (presentation validation)**  
   Flood-fill free space from player-spawn-adjacent free cell (spawn from district profile, presentation-only).  
   If extraction position’s free neighborhood is disconnected, **do not change sim** — log/assert in debug validation; fall back to filling residual free space as continuous `road` so no visual void.

5. **No inventing new collision**  
   Obstacles remain the only blocked AABBs for sim.

### 3.4 Layered rendering (WorldProjector refactor)

Replace undifferentiated children with named layer nodes (z-order contract):

| Layer | Approx z | Contents |
| --- | --- | --- |
| Base terrain / void | −1000 | Continuous dark fill (city tint) covering bounds |
| Ground fill | −900 | Optional subtle city texture stamp (sparse, low alpha) |
| Roads | −800 | Road fill (darker asphalt strip colors) |
| Road markings | −750 | Sparse lane ticks / crosswalk dashes at intersections |
| Sidewalks | −700 | Lighter gray bands |
| Curbs | −650 | Thin edge lines road↔sidewalk |
| Building foundations | −500 | Slightly inset darker pad under body |
| Buildings | −400 | Procedural depth stack |
| Props / landmarks | −300 | ≤2 perimeter landmarks + ≤2 ground decals |
| Wayfinding | −200 | Existing city wayfinding (calmed alpha) |
| Entities | 0+ | Existing entity projector (unchanged) |

Exact numeric z may align with `VisualCombatLayers` without colliding entity bands.

**Implementation note:** Keep a single `WorldProjector.synchronize` entry; internal methods become `renderGround`, `renderStreets`, `renderSidewalks`, `renderBuildings`, etc.

### 3.5 Procedural building depth stack

For each `UrbanBuildingDress`:

```text
BuildingContainer (position = footprint center)
├── ContactShadow (offset down-right, dark ellipse/rect, alpha ~0.25)
├── Foundation (footprint, darker city tint)
├── Body (inset 1–2 units, city tint or soft retail mass texture α≤0.45)
├── Parapet / top edge (thin lighter strip at “north” edge of body)
└── Optional roof plate (only if aspect-fit city prop exists AND alpha is clean)
```

Rules:

- **Default** is geometric stack (no texture).  
- **Never** use landmark hangar/warehouse/pumpjack as pad skin.  
- Light direction: consistent N/NW highlight, SE contact shadow.  
- Anchor: footprint center; height visual only (no collision change).  
- Scale: body fits **inside** footprint with margin; never larger than AABB.

### 3.6 Asset transparency

| Work | Action |
| --- | --- |
| Audit | Script or check: report PNGs with opaque uniform corners used as buildings/landmarks |
| Repair | Flood-fill or re-export only assets that still show baked backgrounds |
| Contract | Landmark/prop sprites require true alpha; no checkerboard baked as pixels |
| Collision | Footprint remains sim AABB — transparent pixels irrelevant |

Prefer reporting + targeted repair over mass destructive rewrites.

### 3.7 City identity (presentation)

Identity channels (all presentation):

1. **Base asphalt hue** (already district-tinted).  
2. **Primary terrain stamp** (sparse, low alpha) from `terrainRole(for:)`.  
3. **Secondary edge stamps** from `secondaryTerrainRole`.  
4. **Pad tint** (building body).  
5. **≤2 landmarks** perimeter.  
6. **Wayfinding labels** (calmed).  

Streets use a slightly different value/hue per city so “road” ≠ “sidewalk” ≠ “pad”.

---

## 4. Validation, tests, debug

### 4.1 Unit tests (host / package or app tests)

- `UrbanDressBuilder` pure tests:  
  - sidewalks expand footprints by fixed width  
  - roads never overlap building footprints  
  - deterministic: same layout → same dress  
  - every obstacle has a building entry  
- WorldProjector smoke: synchronize builds named layer nodes  
- Existing simulation tests **must remain green** (no geometry change)

### 4.2 Visual / matrix

- Optional: simulator visual matrix or stills for 2–3 districts (Wichita, Louisville, NYC) after dress  
- Manual device glance: walkable open streets, buildings as blocks with shadows

### 4.3 Debug overlay (dev / UITesting optional)

Toggle or `-UIDebugUrbanDress` showing:

- Road rects (blue)  
- Sidewalks (gray)  
- Building footprints (red)  
- Intersections (yellow)  

Not required for ship; useful for agents and operators.

### 4.4 Asset audit artifact

```text
docs/arena/ or artifacts/ (gitignored if large):
  arena-asset-audit.md  — list of landmark/prop PNGs with corner opacity flags
```

Prefer `docs/arena/` for a small markdown report committed in-repo.

---

## 5. Implementation phases (bounded commits)

| # | Commit theme | Deliverable |
| ---: | --- | --- |
| 1 | Audit | Short `docs/arena/ARENA_AUDIT.md` root causes + map (can live in this design §2) |
| 2 | UrbanDress model + builder | Pure types + tests; no render change yet |
| 3 | Layered ground + roads + sidewalks | WorldProjector uses dress for floors |
| 4 | Building depth stack | Replaces flat pad-only look |
| 5 | Asset alpha audit / repair | Manifest + fixed PNGs where needed |
| 6 | Wayfinding/decal/landmark integration | Quiet props, debug overlay optional |
| 7 | Docs + completion checklist | Architecture notes + quality checklist |

After each phase: relevant tests + deterministic check + representative level inspect.

---

## 6. Files likely touched

| Path | Change |
| --- | --- |
| `Game/Presentation/UrbanDress.swift` (or Rendering/) | New model + builder |
| `Game/Rendering/WorldProjector.swift` | Layered render from dress |
| `Game/Rendering/VisualCombatLayers.swift` | Optional z-band docs |
| `Tests/SurveillanceSurvivorTests/*UrbanDress*` | Pure builder tests |
| `docs/superpowers/specs/2026-08-02-urban-arena-presentation-design.md` | This design |
| `docs/arena/` | Audit notes, asset checklist, architecture summary |
| Landmark/prop PNGs | Only if audit proves opaque backgrounds |

**Do not change** for this design: `WorldLayout`, `DistrictGenerator` collision, combat, spawn catalogs (except optional read of spawn positions for validation).

---

## 7. Quality checklist (acceptance for this design)

```text
[ ] Continuous ground surface (city-tinted base covers bounds)
[ ] Free space reads as connected road network (inferred)
[ ] Every obstacle has sidewalk ring + building depth stack
[ ] No landmark art squashed onto collision pads
[ ] No opaque texture backgrounds on used building/landmark sprites
[ ] Buildings have foundation + body + contact shadow (+ optional roof)
[ ] Collision still matches WorldObstacle AABBs exactly
[ ] Spawn / extraction free-space not visually sealed (presentation check)
[ ] Deterministic UrbanDress for fixed layout
[ ] Existing gameplay tests pass
[ ] New UrbanDress unit tests pass
[ ] Documentation describes dress vs sim separation
```

---

## 8. Explicit mapping from full execution prompt

| Full prompt phase | This design |
| --- | --- |
| Phase 1 audit | §2 + commit 1 |
| Phase 2 Core CityGrid | **Deferred** — presentation `UrbanDress` only |
| Phase 3 rebuild generation | **Deferred** for sim; presentation inference §3.3 |
| Phase 4 ground/road layers | §3.4 |
| Phase 5 building transparency | §3.6 |
| Phase 6 dimensional buildings | §3.5 procedural stack |
| Phase 7 sidewalks/curbs | §3.3–3.4 |
| Collision sync | **N/A** — sim already authoritative; dress mirrors AABBs |
| Debug / tests / docs | §4–5 |

---

## 9. Approval record

| Item | Value |
| --- | --- |
| Scope choice | Presentation-first urban grid |
| Building treatment | Procedural depth stack |
| Street derivation | Infer from obstacles + bounds |
| Approach | A |
| Sections approved | §1–§8 (2026-08-02) |
| Full design | Approved for written spec |
