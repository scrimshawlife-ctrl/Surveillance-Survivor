# Hallmark audit — floors / terrain playfield

```yaml
/* Hallmark · pre-emit critique: P4 H4 E4 S4 R3 V3 */
verb: audit
target: Game/Rendering/WorldProjector.swift fillTerrain + city terrain assets
date: 2026-07-25
tip: c8d702e
```

**Scope:** playfield floors only (`fillTerrain`, asphalt base, city terrain tiles, parking lines). Not HUD. Not landmarks.

**Genre note:** This is a satirical roguelite SpriteKit field, not a marketing page. Web Hallmark gates are adapted to **game-floor readability**: clutter, tiling tells, contrast vs entities, city identity without wallpaper noise.

---

## Critical (0)

None that block ship. Floors already use a calm asphalt base + low-alpha city tiles (good anti-slop for playfields).

---

## Major

| # | Tell | Where | Fix |
| --- | --- | --- | --- |
| M1 | **Uniform tiling rhythm** — fixed 320² tiles in a regular grid reads as “texture wallpaper” | `WorldProjector.swift` `fillTerrain` ~L98–113 | Break rhythm: 2–3 tile scales, slight rotation (±2°), or sparse irregular stamps instead of full grid coverage |
| M2 | **City identity under-asserted** — tile alpha 0.22 + one terrain role may make cities feel same at a glance | `fillTerrain` ~L99; `VisualAssetMap.terrainRole` | Second terrain layer at lower alpha / different scale, or edge gradient using city terrain B role |
| M3 | **Same asphalt base for all cities** — OKLCH-ish gray `0.11/0.12/0.14` is generic | `fillTerrain` ~L86–91 | Per-district base tint from city weather/lighting labels (still dark, but prairie vs fog vs brick shift ~ΔL 3–6%) |
| M4 | **Parking lines always drawn** regardless of city grammar | `addParkingLines` (called L38) | Gate by topology: lot cities yes; steep arterial / capitol approach use lane or brick marks instead |

---

## Minor

| # | Tell | Where | Fix |
| --- | --- | --- | --- |
| m1 | **Nearest filtering on large soft tiles** can look blocky on Retina | `fillTerrain` L96–97 | Use `.linear` for terrain-only; keep `.nearest` for characters |
| m2 | **Decal scatter is sparse but placement is hard-coded mid-field** | `scatterDecals` ~L187–195 | Seed-stable scatter from district + seed so floors differ run-to-run within identity |
| m3 | **No wear gradient** at world bounds | asphalt `SKShapeNode` | Soft inner vignette on floor (presentation only) so edges recede |
| m4 | **Landmark art on obstacles competes with floor read** when alpha 0.9 | `projectObstacles` L169 | Floor stays primary; keep obstacle art ≤0.75 alpha (already partially calmed for landmarks z≥1.1) |

---

## What’s working (do not regress)

- Asphalt base under busy city tiles — prevents unreadable clutter  
- Low tile alpha (0.22) — identity without drowning entities  
- City-specific terrain roles exist for all 10 districts  
- Landmark zone is a soft ring, not a floor takeover  
- Collision pads stay solid and readable under art  

---

## Priority punch list

1. **M3** — per-city asphalt tint (small, high impact) — **remediated**  
2. **M1** — break grid tiling rhythm — **remediated**  
3. **M4** — parking lines by topology grammar — **remediated**  
4. **M2** — dual terrain role / scale for city pair identity — **remediated**  
5. **m1–m3** polish — **partial** (linear terrain filter, edge vignette, obstacle alpha)

---

## Remediation receipt (follow-up)

| Item | Status |
| --- | --- |
| M3 asphalt tint | Done — `asphaltBaseColor(for:)` |
| M1 irregular stamps | Done — `stampTerrainLayer` multi-size + phase + twist |
| M2 secondary terrain | Done — `secondaryTerrainRole` dual layer |
| M4 parking vs lane ticks | Done — `usesParkingLotMarks` / `addLaneTicks` |
| m1 linear terrain filter | Done |
| m2 seed-stable decal scatter | Done — `jitteredPoint` / `placeDecal` |
| m3 edge vignette | Done — `addFloorEdgeVignette` |
| m4 obstacle art α | Done — 0.75 |

---

## Count (audit baseline)

**0 critical · 4 major · 4 minor** (original audit)

Post-remediation: majors closed in presentation code; re-audit when city art packs change.

---

## Operator calm-floor pass (2026-08-02)

Feedback: arenas **too busy** and **not city-accurate**; **buildings messed up**.

| Change | Detail |
| --- | --- |
| Terrain | Sparse primary stamps + edge-only secondary (no dual carpet) |
| Base tint | Stronger per-city asphalt hue (identity without texture noise) |
| Decals | Max **2 ground decals** / city; mid-field overlays removed from floor |
| Pads | City-tinted solid blocks; **no landmark art squashed onto collision AABBs** |
| Landmarks | Max **2** perimeter silhouettes, calmer alpha/size |
| Wayfinding | Lower group alpha; quieter mid-field rings/valves on early cities |

Code: `Game/Rendering/WorldProjector.swift`

---

## Audit boundaries

Original Hallmark `audit` was read-only. Remediation is a separate implementation pass.
