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
| `sidewalkWidth` | 14 | World units from pad edge to outer sidewalk edge |
| `minRoadWidth` | 28 | Minimum free-band height/width to treat as a full-span road corridor |

`alleys` is present on the model and currently always `[]` (optional narrow free bands deferred).

---

## Inference rules (deterministic)

Given `layout.obstacles` and `layout.bounds`:

1. **Building footprints**  
   Each `WorldObstacle` → `UrbanBuildingDress.footprint` equal to its AABB.

2. **Sidewalk rings**  
   Expand each footprint by `sidewalkWidth`, clamp to bounds → `sidewalkOuter`.  
   Sidewalk list is one outer rect per building; the renderer draws that rect as a lighter band (building stack sits on top of the pad).  
   Occupied space used for road carve is **footprints only** (sidewalks may sit on road visually).

3. **Roads from free gaps**  
   - Project footprints onto Y → free gaps ≥ `minRoadWidth` → full-width **horizontal** road bands.  
   - Project footprints onto X → free gaps ≥ `minRoadWidth` → full-height **vertical** road bands.  
   - Gaps are computed by sorting/merging 1D blocked intervals, then emitting free spans.  
   - Interior overlap between a road and a building footprint is forbidden by construction of the gap method (builder tests assert this).

4. **Intersections**  
   Overlap of one horizontal and one vertical road band → intersection rect.

5. **Fallback**  
   If no roads are inferred, residual free bounds become a single full-bounds road fill so the playfield is not pure void.

6. **No sim mutation**  
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

## Related docs

- Quality acceptance items: [`ARENA_QUALITY_CHECKLIST.md`](ARENA_QUALITY_CHECKLIST.md)
- Landmark/prop alpha audit: [`ARENA_ASSET_AUDIT.md`](ARENA_ASSET_AUDIT.md)
- Environment asset roles: [`../ENVIRONMENT_ART_MAP.md`](../ENVIRONMENT_ART_MAP.md)
- Prior floor calm pass notes: [`../HALLMARK_FLOOR_AUDIT.md`](../HALLMARK_FLOOR_AUDIT.md)
