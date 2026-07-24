# Louisville Phase 0 — Inventory & Deduplication

**City:** Louisville, Kentucky · Level 2 · *Derby Day Data Dragnet*  
**Base:** `main` @ env package v1 (`bfc600d` lineage)  
**Compared against:** Wichita pack on `agent/wichita-city-environment-pack` (if present)

## Protected global entities — REJECT_DUPLICATE

| Asset family | Action |
| --- | --- |
| `player_*` (8) | REJECT_DUPLICATE |
| `lpr_intact` / `damaged` / `destroyed` | REJECT_DUPLICATE |
| `guard_default` / `boss_default` | REJECT_DUPLICATE |
| `blind_spot_decal` | REJECT_DUPLICATE |
| `suspicion_tier_0…5` | REJECT_DUPLICATE |
| App Icon | REJECT_DUPLICATE |

## Global environment v1

| Asset | Louisville use |
| --- | --- |
| `env_tile_downtown` | REUSE_EXACT Smart Downtown base |
| `env_tile_asphalt` | REUSE_EXACT arterials; Louisville gets brick-road variant |
| `env_tile_gated` | REUSE_EXACT Gated Serenity base |
| `env_tile_campus` | REUSE_EXACT Civic Innovation base |
| `env_tile_warehouse` | REUSE_EXACT Evidence Warehouse base |
| `env_obstacle_retail_mass` | REUSE_EXACT Retail Security Zone |
| `env_prop_sheet_municipal` | REUSE_EXACT generic utilities |
| `env_prop_sheet_retail` | REUSE_EXACT retail clutter |
| `env_decal_sheet` | REUSE_EXACT + city decals |
| `env_parallax_skyline` | REUSE_VARIANT → Louisville skyline |

## Wichita-specific — do not recolor / relabel

| Wichita asset class | Action for Louisville |
| --- | --- |
| prairie arterial / prairie edge | REJECT_DUPLICATE (wrong biome) |
| grain elevators / hangars / tornado sirens | REJECT_DUPLICATE |
| radar/aircraft shadow prairie overlays | REJECT_DUPLICATE |
| Wichita monument | REJECT_DUPLICATE |

## GENERATE_MISSING (Louisville-specific)

| Role | Filename |
| --- | --- |
| Identity board | `louisville_identity_board_01` (docs-only) |
| Palette board | `louisville_palette_board_01` (docs-only) |
| Brick arterial terrain | `louisville_terrain_brick_arterial_01` |
| Historic street tile | `louisville_terrain_historic_street_01` |
| Skyline / Twin Spire silhouette | `louisville_skyline_parallax_01` |
| Twin Spire landmark | `louisville_landmark_twin_spires_distant_01` |
| Riverfront / floodwall | `louisville_landmark_riverfront_floodwall_01` |
| Bourbon warehouse mass | `louisville_landmark_bourbon_warehouse_01` |
| Victorian facade edge | `louisville_landmark_victorian_facade_01` |
| Wrought-iron gate prop | `louisville_prop_wrought_iron_gate_01` |
| Map redaction overlay | `louisville_overlay_map_redaction_01` |
| Hidden-camera glint overlay | `louisville_overlay_hidden_camera_glint_01` |
| River haze overlay | `louisville_overlay_river_haze_01` |
| Bourbon stain decal | `louisville_decal_bourbon_stain_01` |
| Wet brick sheen decal | `louisville_decal_wet_brick_01` |

## Phase 2 shared runtime mapping

| Role | Source |
| --- | --- |
| LPR entities | `lpr_*` via VisualAssetMap |
| Blind Spot | `blind_spot_decal` |
| Player / guard / boss scale | existing entity sprites |
| Generic barriers / parking | `env_prop_sheet_*` |
