# Tulsa Phase 0 — Inventory & Deduplication

**City:** Tulsa, Oklahoma · Level 3 · *The Petroleum Panopticon*  
**Signature mechanic:** oil extraction reimagined as behavioral-data mining  
**Compared against:** global env v1, Wichita, Louisville, Dayton (on `main`)  
**Oakland pack:** open PR / may land separately — not required for this foundation

## Visual thesis

> A chrome-and-neon oil city where data is pumped from the ground, refined through roadside surveillance, and stored as civic memory beneath an immaculate Art Deco shell.

## REUSE_EXACT

| Asset / class | Tulsa use |
| --- | --- |
| `player_*`, `lpr_*`, `guard_default`, `boss_default`, `blind_spot_decal`, `suspicion_tier_*` | Entity / HUD |
| `env_tile_*` | District biome bases (compositional) |
| `env_prop_sheet_*`, `env_decal_sheet`, `env_obstacle_retail_mass` | Generic industrial/retail watermarks |
| `env_parallax_skyline` | Fallback skyline |

## REUSE_VARIANT

| Role | GENERATE name |
| --- | --- |
| Route arterial terrain | `tulsa_terrain_route_arterial_01` |
| Oilfield access terrain | `tulsa_terrain_oilfield_access_01` |
| Skyline | `tulsa_skyline_parallax_01` |

## REJECT_DUPLICATE

| Source | Reason |
| --- | --- |
| Wichita prairie / grain / hangar / radar | Plains aviation identity |
| Louisville bourbon / spires / Victorian | Derby hospitality |
| Dayton gateway / flight monument / fountain | Gateway-city identity |
| Exact Route 66 shields, real motel brands, oil logos | Legal / IP |
| Exact Golden Driller replica | Use original industrial-watchman instead |

## GENERATE_MISSING (foundation v1)

| # | Filename | Class |
| ---: | --- | --- |
| 1 | `tulsa_terrain_route_arterial_01` | Route 66-style arterial |
| 2 | `tulsa_terrain_oilfield_access_01` | Oilfield / industrial access |
| 3 | `tulsa_skyline_parallax_01` | Deco + refinery + derrick skyline |
| 4 | `tulsa_landmark_deco_tower_distant_01` | Original Art Deco tower |
| 5 | `tulsa_landmark_industrial_watchman_midground_01` | Original monumental watchman |
| 6 | `tulsa_landmark_oil_derrick_01` | Oil derrick |
| 7 | `tulsa_landmark_pumpjack_01` | Pumpjack |
| 8 | `tulsa_prop_motel_sign_frame_01` | Motel sign frame (no text) |
| 9 | `tulsa_overlay_behavioral_crude_flow_01` | Behavioral-extraction flow |
| 10 | `tulsa_overlay_neon_glow_01` | Roadside neon glow |
| 11 | `tulsa_overlay_refinery_haze_01` | Refinery / dust haze |
| 12 | `tulsa_decal_pipeline_leak_01` | Pipeline leak / oil stain |
| 13 | `tulsa_decal_route_marking_01` | Faded roadside marking |

Docs-only: `tulsa_identity_board_01`, `tulsa_palette_board_01`.

## COMPOSE_FROM_EXISTING (districts)

| District | Global biome | Tulsa emphasis |
| --- | --- | --- |
| Retail Security Zone | asphalt | route arterial, motel sign, neon |
| Smart Downtown | downtown | deco tower, skyline |
| Gated Serenity | gated | storm-country haze, watchman distant |
| Civic Innovation Campus | campus | behavioral crude overlay |
| Evidence Warehouse | warehouse | derrick, pumpjack, oilfield terrain |

## Explicit non-goals

- No cowboys, horses, Native stereotypes, casino/Vegas styling  
- No exact Route 66 shields or brand logos  
- No baked LPR / scan cones  
- No player/enemy regeneration  
