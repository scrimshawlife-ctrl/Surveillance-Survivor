# Environment Art Map (v1 + city foundation packs)

Production batch of **modular district environment assets** for Surveillance Survivor.
Gameplay systems first, scenery second: readable lanes, prominent LPR poles (entity layer),
and coherent satirical municipal identity.

**Layers on `main`:**

1. **Global environment package v1** — shared biome tiles, props, decals, generic parallax.
2. **City foundation packs** — per-city terrain variants, skyline, landmarks, overlays, decals (**all 10 cities attached**).

## Hallmark M5 — ground authority (locked)

| Layer | Authority | Rule |
| --- | --- | --- |
| **Playfield ground** | City pack `*_terrain_*` when present | **City wins.** Never bake surveillance beams into terrain. |
| **Fallback ground** | Global `env_tile_*` | Used only when city terrain role is missing. |
| **Far skyline** | City `*_skyline_parallax_01` else `env_parallax_skyline` | Soft-compat desaturated/pixelated (Hallmark M1). Non-interactive. |
| **Overlays** | City `*_overlay_*` | Pressure FX only; not ground authority. |

**Urban dress (presentation):** arenas also project inferred roads/sidewalks/building stacks from `WorldLayout` via `UrbanDressBuilder` → `WorldProjector` layers (`urban-ground` … `urban-props`). Collision stays sim AABBs. See [`docs/arena/URBAN_DRESS.md`](arena/URBAN_DRESS.md) and [`docs/arena/ARENA_QUALITY_CHECKLIST.md`](arena/ARENA_QUALITY_CHECKLIST.md).

## Style contract

| Trait | Value |
| --- | --- |
| Perspective | Top-down orthographic (landmarks: map-icon footprint; entities: top-down pixel) |
| Medium | Municipal pixel satire (not cartoon / anime / voxel) |
| Tone | Over-engineered municipal satire, not apocalyptic horror |
| Palette | asphalt, charcoal, cyan resistance, red surveillance, yellow hazard |
| Filtering | nearest-neighbor |
| Collision | independent of art; shape fallbacks remain valid |

## Biome → district mapping (global fallbacks)

| Level | City (opener) | Global terrain role | Global tile name | City pack terrain preference |
| ---: | --- | --- | --- | --- |
| 1 | Wichita | `envTileAsphalt` | `env_tile_asphalt` | `wichita_terrain_*` when present |
| 2 | Louisville | `envTileDowntown` | `env_tile_downtown` | `louisville_terrain_*` when present |
| 3 | Tulsa | `envTileGated` | `env_tile_gated` | `tulsa_terrain_*` when present |
| 4 | Dayton | `envTileCampus` | `env_tile_campus` | `dayton_terrain_*` when present |
| 5 | Oakland | `envTileWarehouse` | `env_tile_warehouse` | `oakland_terrain_*` when present |
| 6 | San Francisco | downtown kit | `env_tile_downtown` | `san_francisco_terrain_*` when present |
| 7 | Columbus | downtown kit | `env_tile_downtown` | `columbus_terrain_*` when present |
| 8 | New York | downtown kit | `env_tile_downtown` | `new_york_terrain_*` when present |
| 9 | Los Angeles | asphalt kit | `env_tile_asphalt` | `los_angeles_terrain_*` when present |
| 10 | Atlanta | asphalt kit | `env_tile_asphalt` | `atlanta_terrain_*` when present |

Resolved at runtime by `VisualAssetMap.terrainRole(for:)` / `skylineRole(for:)` — **city pack names win** when the district city matches; otherwise global env tiles/skyline apply.

## Global asset inventory (v1 attached)

| Name | Role | Canvas | Notes |
| --- | --- | --- | --- |
| `env_tile_asphalt` | ground fill | 256² | seamless parking asphalt |
| `env_tile_downtown` | ground fill | 256² | granite/steel plaza |
| `env_tile_gated` | ground fill | 256² | sterile lawn/path |
| `env_tile_campus` | ground fill | 256² | innovation campus concrete |
| `env_tile_warehouse` | ground fill | 256² | industrial floor |
| `env_parallax_skyline` | far layer | 1024×384 | non-interactive skyline |
| `env_obstacle_retail_mass` | obstacle projection | 384×256 | strip-mall mass |
| `env_prop_sheet_municipal` | prop library sheet | 512×288 | bollards/cabinets/foundations |
| `env_prop_sheet_retail` | prop library sheet | 512×320 | kiosk / cart corral |
| `env_decal_sheet` | ground decals | 512×288 | oil, paint, skids, utility marks |

All are **optional** (`requiredForMVP: false`). `WorldProjector` falls back to shape asphalt/obstacles when missing.

## City foundation packs

| City | Status | Runtime prefix | Count | Docs |
| --- | --- | ---: | ---: | --- |
| Wichita | On `main` (#28) | `wichita_*` | 13 | [`docs/cities/wichita/`](cities/wichita/) |
| Louisville | On `main` (#29) | `louisville_*` | 13 | [`docs/cities/louisville/`](cities/louisville/) |
| Tulsa | Open PR (#33) | `tulsa_*` | 13 | lands with PR (not on `main` until merge) |
| Dayton | On `main` (#31) | `dayton_*` | 13 | [`docs/cities/dayton/`](cities/dayton/) |
| Oakland | Open PR (#32) | `oakland_*` | 13 | lands with PR (not on `main` until merge) |
| SF … Atlanta | Not started | — | — | After #32/#33 |

Live board: [`REPO_STATUS.md`](REPO_STATUS.md).

### Shipped roles (each city)

Typical foundation pack (not every city uses every class):

| Class | Purpose |
| --- | --- |
| Terrain (2) | Arterial / edge or historic fill preferred over global biome for that city |
| Skyline (1) | City-specific parallax; preferred over `env_parallax_skyline` |
| Landmarks (3–4) | Place-identity mid/far props (readable silhouettes, no labels) |
| Prop (1) | Signature city prop |
| Overlays (2–3) | Atmosphere / satire (radar, haze, redaction) — not full scene duplicates |
| Decals (2) | Sparse ground marks |

### Production rules

1. **Inventory first.** Classify every candidate as `REUSE_EXACT`, `REUSE_VARIANT`, `GENERATE_MISSING`, or `REJECT_DUPLICATE`.
2. **Never recolor City A as City B.** Wichita prairie/hangar/grain/radar must not ship as Louisville; Louisville brick/bourbon/spires must not ship as Tulsa.
3. **REUSE_EXACT** global entities (player, LPR, guard, boss, Blind Spot) and generic env props/decals sheets.
4. **Partial district packs are intentional** for foundation: global biomes + city landmarks. Full five-district atlases are a later pass.
5. LPR poles remain entity sprites (`lpr_*`), never baked into terrain.

Index and workflow: [`docs/cities/README.md`](cities/README.md).

## Projection rules

1. Terrain is tiled across world bounds; never drives collision.
2. Obstacles may use retail mass texture sized to obstacle half-extents.
3. Prop/decal sheets and city decals are sparse watermarks only — open combat arenas stay clear.
4. City landmarks and overlays are projected by `WorldProjector` for matching district cities.
5. LPR poles remain entity sprites (`lpr_*`), not environment props.
6. No product UI, logos, brand marks, readable maps, or characters in environment binaries.

## Future expansions (not foundation)

- Autotile edge transitions per biome
- Destroyed / hazard ground variants
- Per-prop sliced imagesets (bollard, meter, cart, dumpster, …)
- Full five-district themed tile atlases per city
- Separate lighting overlay layers
- Remaining city packs: Tulsa → Dayton → Oakland → SF → Columbus → NYC → LA → Atlanta

## Validation

```bash
make assets-check
```

Canonical names (global + Wichita + Louisville) are listed in `scripts/validate_visual_assets.sh`.
Runtime map: `VisualAssetMap` + `GameAssetName.Environment` / `.Wichita` / `.Louisville`.
