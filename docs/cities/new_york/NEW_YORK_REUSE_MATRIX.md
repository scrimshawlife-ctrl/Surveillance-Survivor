# New York City Phase 0 — Inventory & Deduplication

**City:** New York City · Level 8 · *The Five-Borough Omnigaze*  
**Signature mechanic:** borough-specific surveillance phases  
**Compared against:** global env v1 + Wichita, Louisville, Tulsa, Dayton, Oakland, San Francisco, Columbus (all on `main`)

## Visual thesis

> A hyper-dense city where five distinct borough surveillance systems compete, overlap, and ultimately fuse into a single real-time urban organism.

## REUSE_EXACT

| Asset / class | NYC use |
| --- | --- |
| `player_*`, `lpr_*`, `guard_default`, `boss_default`, `blind_spot_decal`, `suspicion_tier_*` | Entity / HUD |
| `env_tile_*` | District biome bases (compositional) |
| `env_prop_sheet_*`, `env_decal_sheet`, `env_obstacle_retail_mass` | Generic watermarks |
| `env_parallax_skyline` | Fallback only |

## REJECT_DUPLICATE

| Source | Reason |
| --- | --- |
| SF cable / hills / Victorian | Not NYC subway / grid density |
| Oakland BART / port cranes / containers | Not MTA / Manhattan density |
| Columbus arches / statehouse | Not toll gantries / NYC civic |
| Louisville Victorian streets | Not brownstone rhythm |
| Tulsa neon | Not Times Square digital panels |
| Wichita plains aviation | Wrong identity |

Neutral bridge hardware, rail fragments, fencing, cones: REUSE_EXACT from global sheets only.

## GENERATE_MISSING (foundation v1 — 13)

| # | Filename | Class |
| ---: | --- | --- |
| 1 | `new_york_terrain_avenue_grid_01` | Dense avenue grid asphalt |
| 2 | `new_york_terrain_brownstone_street_01` | Brownstone-block street fill |
| 3 | `new_york_skyline_parallax_01` | Multi-borough skyline strip |
| 4 | `new_york_landmark_suspension_bridge_distant_01` | Original bridge (not photo trace) |
| 5 | `new_york_landmark_subway_entrance_01` | Subway stair portal (no logos) |
| 6 | `new_york_landmark_scaffold_shed_01` | Sidewalk shed / scaffolding |
| 7 | `new_york_landmark_rooftop_water_tower_01` | Rooftop water tower |
| 8 | `new_york_prop_digital_signage_panel_01` | Abstract digital billboard panel |
| 9 | `new_york_overlay_borough_phase_01` | Borough-phase segmentation |
| 10 | `new_york_overlay_omnigaze_fusion_01` | Five-borough fusion network |
| 11 | `new_york_overlay_subway_steam_01` | Subway steam / under-street vapor |
| 12 | `new_york_decal_scaffold_shadow_01` | Scaffold shadow on pavement |
| 13 | `new_york_decal_wet_asphalt_01` | Wet asphalt sheen |

Docs-only: `new_york_identity_board_01`, `new_york_palette_board_01`.

## COMPOSE_FROM_EXISTING (districts)

| District | Global biome | NYC emphasis |
| --- | --- | --- |
| Retail Security Zone | asphalt | avenue grid, digital signage, scaffold |
| Smart Downtown | downtown | skyline, billboard panel, omnigaze |
| Gated Serenity | gated | brownstone street, park edge via global |
| Civic Innovation Campus | campus | subway entrance, steam overlay |
| Evidence Warehouse | warehouse | scaffold, wet asphalt, bridge distant |

## Five-borough foundation note

Full per-borough atlases are **out of foundation v1**. This pack encodes borough *identity signals* (grid vs brownstone, bridge, subway, scaffold, digital, fusion overlay) compositionally. Later passes may split Manhattan/Brooklyn/Queens/Bronx/Staten modules.

## Explicit non-goals

- No real ads, transit logos, station names, crowds  
- No SF/Oakland recolor  
- No baked LPR / trains / scan cones  
- No Manhattan-only package  
