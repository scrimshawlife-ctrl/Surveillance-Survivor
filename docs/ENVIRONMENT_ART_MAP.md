# Environment Art Map (v1)

Production batch of **modular district environment assets** for Surveillance Survivor.
Gameplay systems first, scenery second: readable lanes, prominent LPR poles (entity layer),
and coherent satirical municipal identity.

## Style contract

| Trait | Value |
| --- | --- |
| Perspective | Top-down 3/4 orthographic |
| Medium | Modern 2.5D pixel art (not cartoon / anime / voxel / painterly) |
| Tone | Over-engineered municipal satire, not apocalyptic horror |
| Palette | midnight blue, camera red, bureaucratic beige, safety lime, copier gray, asphalt, oxidized steel, yellow paint |
| Filtering | nearest-neighbor |
| Collision | independent of art; shape fallbacks remain valid |

## Biome → district mapping

| Level | City (opener) | Terrain role | Tile name |
| ---: | --- | --- | --- |
| 1 | Wichita (Retail Security Zone) | `envTileAsphalt` | `env_tile_asphalt` |
| 2 | Louisville (Smart Downtown) | `envTileDowntown` | `env_tile_downtown` |
| 3 | Tulsa (Gated Serenity) | `envTileGated` | `env_tile_gated` |
| 4 | Dayton (Civic Innovation Campus) | `envTileCampus` | `env_tile_campus` |
| 5 | Oakland (Evidence Warehouse) | `envTileWarehouse` | `env_tile_warehouse` |
| 6–9 | later dense cities | downtown kit reuse | `env_tile_downtown` |
| 10 | Atlanta | asphalt kit reuse | `env_tile_asphalt` |

Resolved at runtime by `VisualAssetMap.terrainRole(for:)`.

## Asset inventory (v1 attached)

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

## Projection rules

1. Terrain is tiled across world bounds; never drives collision.
2. Obstacles may use retail mass texture sized to obstacle half-extents.
3. Prop/decal sheets are sparse watermarks only — open combat arenas stay clear.
4. LPR poles remain entity sprites (`lpr_*`), not environment props.
5. No product UI, logos, or characters in environment binaries.

## Future expansions (not in v1)

- Autotile edge transitions per biome
- Destroyed / hazard ground variants
- Per-prop sliced imagesets (bollard, meter, cart, dumpster, …)
- District-specific obstacle kits (glass towers, HOA gates, warehouse aisles)
- Separate lighting overlay layers

## Validation

```bash
make assets-check
```

Canonical names are listed in `scripts/validate_visual_assets.sh`.
Runtime map: `VisualAssetMap` + `GameAssetName.Environment`.
