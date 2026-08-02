# Urban dress architecture

**Status:** presentation-first urban grid (Approach A)  
**Design:** [`docs/superpowers/specs/2026-08-02-urban-arena-presentation-design.md`](../superpowers/specs/2026-08-02-urban-arena-presentation-design.md)  
**Code:** `Game/Presentation/UrbanDress.swift`, `UrbanDressBuilder.swift`, `Game/Rendering/WorldProjector.swift`

This note describes how arena presentation infers a cohesive city-grid look from existing simulation layout. It is **not** a Core city-grid generator and does **not** claim READY launch.

---

## UrbanDress vs WorldLayout

| Concern | Owner | Types / files |
| --- | --- | --- |
| Arena extents | Simulation | `WorldBounds` on `WorldLayout` |
| Blocked collision footprints | Simulation | `WorldObstacle` AABBs (`center` + `halfSize`) |
| Layout generation | Simulation | `DistrictGenerator` + `districts.json` blueprints |
| Visual streets / sidewalks / building stacks | Presentation only | `UrbanDress` via `UrbanDressBuilder` |
| SpriteKit projection | Presentation only | `WorldProjector.synchronize` |

```text
districts.json → DistrictGenerator → WorldLayout (UNCHANGED sim truth)
                                         ↓
                              UrbanDressBuilder.build(layout, district)
                                         ↓
                                    UrbanDress
                                         ↓
                              WorldProjector named layers
```

**Contract**

- Collision, pathfinding, spawns, sensors, and combat remain **simulation-owned**.
- Presentation must **never** derive collision from sprite pixels, alpha, or `UrbanDress` cells.
- `UrbanDress` mirrors obstacle AABBs for footprints; sidewalk/road geometry is **visual only**.
- Same `WorldLayout` + district → same `UrbanDress` (pure, no RNG). `district` is currently reserved for future width tables; widths are shared constants today.

---

## Presentation model

| Type | Role |
| --- | --- |
| `UrbanRect` | Axis-aligned world rect (min/max or center/halfSize) |
| `UrbanBuildingDress` | One obstacle: `obstacleID`, `footprint`, `sidewalkOuter` |
| `UrbanDress` | `bounds`, `roads`, `intersections`, `sidewalks`, `buildings`, `alleys` |

Constants on `UrbanDressBuilder` (tune once; not district-keyed yet):

| Constant | Value | Meaning |
| --- | ---: | --- |
| `streetSidewalkWidth` | 5 | Sidewalk on each side of a street |
| `streetParkingWidth` | 4 | Curb parking when gap is wide enough |
| `minCarriagewayWidth` | 22 | Minimum two-lane travel lanes |
| `minRoadWidth` | 32 | sidewalk + carriageway + sidewalk (free-gap threshold; parking optional) |
| `buildingCurbWidth` | 4 | Thin pad apron (not primary street sidewalk) |
| `sidewalkWidth` | 4 | Alias of `buildingCurbWidth` (compat) |

**Satellite cross-section (when gap allows):**  
`sidewalk | parking | multi-lane carriageway | parking | sidewalk`  
with warm center double-dash, white lane dashes on wide roads, zebra crosswalks, sparse tree dots.

`alleys` is present on the model and currently always `[]` (optional narrow free bands deferred).

---

## Inference rules (deterministic)

Given `layout.obstacles` and `layout.bounds`:

1. **Building footprints**  
   Each `WorldObstacle` → `UrbanBuildingDress.footprint` equal to its AABB.  
   Thin curb apron: expand by `buildingCurbWidth` → `sidewalkOuter`.

2. **Two-way street corridors**  
   - Project footprints onto Y/X → free gaps ≥ `minRoadWidth`.  
   - Split each gap into: **sidewalk | two-lane carriageway | sidewalk**.  
   - `dress.roads` = carriageways only (darker asphalt + centerline + edge lines).  
   - `dress.sidewalks` = street-edge strips only (lighter band + curb lip).  
   - Carriageways must not interior-overlap building footprints.

3. **Intersections**  
   Overlap of one horizontal and one vertical **carriageway** → intersection rect + crosswalk dashes.

4. **Fallback**  
   If no gaps form, the full layout bounds are dressed as one horizontal two-way street (sidewalks + carriageway).

5. **No sim mutation**  
   Builder never writes Core state. Obstacles remain the only blocked AABBs for collision.

---

## WorldProjector layer tree (z contract)

Named children under the projector root (relative z on each layer node):

| Layer name | Layer `zPosition` | Contents |
| --- | ---: | --- |
| (parallax skyline) | −2 | Soft city skyline band (optional asset) |
| `urban-ground` | 0 | City-tinted continuous base (`urban-ground-base`) + sparse terrain stamps |
| `urban-roads` | 0.02 | Road fills, intersections, crosswalk dashes, parking/lane ticks |
| `urban-sidewalks` | 0.08 | Outer sidewalk rects per building |
| `urban-buildings` | 1.0 | One container per obstacle (depth stack) |
| `urban-props` | 1.15 | ≤2 ground decals + ≤2 perimeter landmarks |

Wayfinding overlays, landmark zone ring, and floor edge vignette still attach at root (existing city presentation). Entity projection remains outside this stack (GameScene / entity projector).

Child names used by tests and debug:

- Roads: `urban-road`, `urban-intersection`
- Sidewalks: `urban-sidewalk`
- Buildings: `building-{obstacleID}` with children below

---

## Building depth stack

Per obstacle, under `urban-buildings` → `building-{id}` (position = footprint center):

| Child name | Role |
| --- | --- |
| `building-shadow` | SE-biased contact shadow (visual only) |
| `building-foundation` | Full footprint, darker city foundation tint |
| `building-body` | Slightly inset pad mass |
| `building-parapet` | Thin lighter strip on north edge of body |

Optional sparse `env_obstacle_retail_mass` skin may attach on some pads when aspect fits; **landmark hangar/warehouse/pumpjack art is not used as pad skin**. Footprint size and position remain the sim AABB — stack height is cosmetic.

---

## Collision remains AABB

| Truth | Source |
| --- | --- |
| Walkable vs blocked | Simulation vs `WorldObstacle` AABBs only |
| Presentation sidewalks/roads | Do not expand or shrink collision |
| Transparent landmark/prop pixels | Irrelevant to hit tests |
| `UrbanDress` | Projection input only |

If dress extraction ever looks wrong (e.g. disconnected free space), **do not change sim** — fix presentation inference or fall back to continuous road fill.

---

## Camera (presentation)

Default play uses a fixed satellite zoom: `GameScene.satelliteCameraScale = 1.38`
on `SKCameraNode` (scale > 1 = more world visible). Simulation units and
collision are unchanged; entities appear slightly smaller on screen.
Blind Spot on-screen tests multiply view half-size by camera scale.

---

## Related docs

- Quality acceptance items: [`ARENA_QUALITY_CHECKLIST.md`](ARENA_QUALITY_CHECKLIST.md)
- Landmark/prop alpha audit: [`ARENA_ASSET_AUDIT.md`](ARENA_ASSET_AUDIT.md)
- Environment asset roles: [`../ENVIRONMENT_ART_MAP.md`](../ENVIRONMENT_ART_MAP.md)
- Prior floor calm pass notes: [`../HALLMARK_FLOOR_AUDIT.md`](../HALLMARK_FLOOR_AUDIT.md)

## Arena scale

District `simulation` spatial profiles (bounds, obstacles, spawns, sensors positions) were scaled **1.5×** so satellite view reads as a larger city grid. Combat radii and speeds were **not** scaled.
