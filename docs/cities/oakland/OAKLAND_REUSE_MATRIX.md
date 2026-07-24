# Oakland Phase 0 — Inventory & Deduplication

**City:** Oakland, California · Level 5 · *The Sanctuary Scanner*  
**Signature mechanic:** borrowed jurisdiction and contract renewal  
**Compared against:** global env v1, Wichita, Louisville, Dayton  
**Tulsa pack:** not present — treated as absent

## Visual thesis

> A port city of layered jurisdictions where freight logistics, transit infrastructure, sanctuary rhetoric, public art, private vendors, and federal access routes overlap until no institution can clearly explain who is watching—or under whose authority.

## REUSE_EXACT

| Asset / class | Oakland use |
| --- | --- |
| `player_*`, `lpr_*`, `guard_default`, `boss_default`, `blind_spot_decal`, `suspicion_tier_*` | Entity / HUD layers |
| `env_tile_*` (asphalt, downtown, gated, campus, warehouse) | District biome bases |
| `env_prop_sheet_*`, `env_decal_sheet`, `env_obstacle_retail_mass` | Generic industrial / retail watermarks |
| `env_parallax_skyline` | Fallback skyline |

## REUSE_VARIANT

| Role | GENERATE name |
| --- | --- |
| Port service terrain | `oakland_terrain_port_service_01` |
| Warehouse / yard floor | `oakland_terrain_warehouse_yard_01` |
| Skyline | `oakland_skyline_parallax_01` |

## REJECT_DUPLICATE

| Source | Reason |
| --- | --- |
| Wichita prairie / grain / hangar / radar | Plains aviation identity |
| Louisville bourbon / spires / Victorian | Derby hospitality identity |
| Dayton gateway / flight monument / fountain plaza | Gateway-city identity |
| Generic SF fog cable-car imagery | Wrong city |

## GENERATE_MISSING (foundation v1)

| # | Filename | Class |
| ---: | --- | --- |
| 1 | `oakland_terrain_port_service_01` | Port service road terrain |
| 2 | `oakland_terrain_warehouse_yard_01` | Container-yard floor |
| 3 | `oakland_skyline_parallax_01` | Cranes + hills + mid-rise |
| 4 | `oakland_landmark_port_crane_distant_01` | Port crane silhouette |
| 5 | `oakland_landmark_container_stack_midground_01` | Container stack wall |
| 6 | `oakland_landmark_lake_shoreline_01` | Urban lake edge |
| 7 | `oakland_landmark_transit_viaduct_01` | Elevated transit (no brand logos) |
| 8 | `oakland_prop_mural_wall_01` | Abstract mural facade (no slogans/faces) |
| 9 | `oakland_overlay_borrowed_jurisdiction_01` | Jurisdiction bleed lines |
| 10 | `oakland_overlay_contract_renewal_01` | Contract-extension glow |
| 11 | `oakland_overlay_marine_haze_01` | Port/lake haze |
| 12 | `oakland_decal_container_rust_01` | Rust / yard decal |
| 13 | `oakland_decal_rail_crossing_01` | Rail crossing marks |

Docs-only: `oakland_identity_board_01`, `oakland_palette_board_01`.

## COMPOSE_FROM_EXISTING (districts)

| District | Global biome | Oakland emphasis |
| --- | --- | --- |
| Retail Security Zone | asphalt | mural prop, borrowed-jurisdiction overlay |
| Smart Downtown | downtown | transit viaduct, mural |
| Gated Serenity | gated | hills skyline, marine haze |
| Civic Innovation Campus | campus | contract-renewal overlay |
| Evidence Warehouse | warehouse | container stack, port crane, yard terrain |

## Explicit non-goals

- No gang stereotypes, crime caricatures, or ruin porn  
- No BART logos, port branding, shipping logos, real posters/slogans/faces  
- No baked LPR / scan cones / jurisdiction logic into terrain  
- No SF cable-car / Golden Gate stand-ins  
