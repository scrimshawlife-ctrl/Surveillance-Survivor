# Wichita Phase 0 — Inventory & Deduplication

**City:** Wichita, Kansas · Level 1 · *The Panopticon of the Plains*  
**Branch base:** `agent/environment-art-map-v1` (global env package v1)  
**Scan date:** 2026-07-24  

Protected runtime entities (**never regenerate as city art**):

| Asset | Status |
| --- | --- |
| `player_*` (8) | `REJECT_DUPLICATE` |
| `lpr_intact` / `damaged` / `destroyed` | `REJECT_DUPLICATE` |
| `guard_default` / `boss_default` | `REJECT_DUPLICATE` |
| `blind_spot_decal` | `REJECT_DUPLICATE` |
| `suspicion_tier_0…5` | `REJECT_DUPLICATE` |
| App Icon | `REJECT_DUPLICATE` |

## Existing global environment (v1)

| Asset | Classification for Wichita | Notes |
| --- | --- | --- |
| `env_tile_asphalt` | `REUSE_VARIANT` base | Source for prairie arterial; city gets `wichita_terrain_*` variants |
| `env_tile_downtown` | `REUSE_EXACT` for Smart Downtown pack base | Accent with river/bridge landmarks |
| `env_tile_gated` | `REUSE_EXACT` for Gated Serenity base | Accent with HOA/siren props |
| `env_tile_campus` | `REUSE_EXACT` for Civic Innovation base | Accent with hangar/test-range props |
| `env_tile_warehouse` | `REUSE_EXACT` for Evidence Warehouse base | Accent with rail/grain props |
| `env_parallax_skyline` | `REUSE_VARIANT` | Generic; Wichita needs prairie skyline |
| `env_obstacle_retail_mass` | `REUSE_EXACT` | Retail Security Zone obstacles |
| `env_prop_sheet_municipal` | `REUSE_EXACT` | Bollards, cabinets, foundations |
| `env_prop_sheet_retail` | `REUSE_EXACT` | Kiosk / cart corral |
| `env_decal_sheet` | `REUSE_EXACT` + city decals | Plus Wichita runway/grain decals |

Full file scan: [`WICHITA_ASSET_INVENTORY.json`](WICHITA_ASSET_INVENTORY.json).

## Generate-missing (Wichita-specific)

| Semantic role | Proposed filename | Status |
| --- | --- | --- |
| Identity board | `wichita_identity_board_01` | GENERATE_MISSING |
| Palette board | `wichita_palette_board_01` | GENERATE_MISSING |
| Prairie arterial terrain | `wichita_terrain_asphalt_arterial_01` | GENERATE_MISSING |
| Dry grass edge tile | `wichita_terrain_prairie_edge_01` | GENERATE_MISSING |
| Prairie skyline parallax | `wichita_skyline_parallax_01` | GENERATE_MISSING |
| River monument distant | `wichita_landmark_river_monument_distant_01` | GENERATE_MISSING |
| Grain elevator midground | `wichita_landmark_grain_elevator_midground_01` | GENERATE_MISSING |
| Aircraft hangar arena-edge | `wichita_landmark_aircraft_hangar_01` | GENERATE_MISSING |
| Bridge approach module | `wichita_landmark_bridge_span_01` | GENERATE_MISSING |
| Tornado siren prop | `wichita_prop_tornado_siren_01` | GENERATE_MISSING |
| Radar sweep overlay | `wichita_overlay_radar_sweep_01` | GENERATE_MISSING |
| Storm alert overlay | `wichita_overlay_storm_alert_01` | GENERATE_MISSING |
| Runway stripe decal | `wichita_decal_runway_stripe_01` | GENERATE_MISSING |
| Grain dust decal | `wichita_decal_grain_dust_01` | GENERATE_MISSING |
| Aircraft shadow overlay | `wichita_overlay_aircraft_shadow_01` | GENERATE_MISSING |

## Shared mapping (Phase 2)

| Role | Runtime source |
| --- | --- |
| LPR poles | `VisualAssetMap` → `lpr_*` entity sprites |
| Blind Spot | `blind_spot_decal` |
| Player / guard / boss scale refs | existing entity sprites |
| Generic parking / utility | `env_prop_sheet_*`, `env_decal_sheet` |
| Retail obstacles | `env_obstacle_retail_mass` |

No LPR, player, or boss may be baked into terrain tiles.
