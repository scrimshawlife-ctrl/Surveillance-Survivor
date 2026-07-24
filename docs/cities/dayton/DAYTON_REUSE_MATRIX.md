# Dayton Phase 0 — Inventory & Deduplication

**City:** Dayton, Ohio · Level 4 · *Gateway City: Every Camera Counts*  
**Signature mechanic:** chained gateway checkpoints  
**Compared against:** global env v1, Wichita pack (#28), Louisville pack (#29)  
**Tulsa pack:** not present on `main` — treated as absent (no REUSE from Tulsa)

## Visual thesis

> An aviation-heritage city transformed into a municipal test range where every neighborhood entrance, civic marker, and research corridor becomes a checkpoint feeding the same optimization system.

## REUSE_EXACT (do not regenerate)

| Asset / class | Dayton use |
| --- | --- |
| `player_*` (8) | Entity layer |
| `lpr_*` (3) | Entity layer — empty mounts only on env art |
| `guard_default` / `boss_default` | Entity layer |
| `blind_spot_decal` | Extraction |
| `suspicion_tier_*` | HUD optional |
| `env_tile_asphalt` / downtown / gated / campus / warehouse | District biome bases (compositional) |
| `env_prop_sheet_municipal` / `env_prop_sheet_retail` | Sparse prop watermarks |
| `env_decal_sheet` | Generic ground marks |
| `env_obstacle_retail_mass` | Generic obstacle mass when city factory unavailable |
| `env_parallax_skyline` | Fallback if city skyline missing |

## REUSE_VARIANT (new pixels, same role family)

| Role | Global / prior | Dayton GENERATE name |
| --- | --- | --- |
| Arterial terrain | `env_tile_campus` / asphalt | `dayton_terrain_gateway_approach_01` |
| Secondary terrain | campus / industrial | `dayton_terrain_industrial_corridor_01` |
| Skyline | `env_parallax_skyline` | `dayton_skyline_parallax_01` |

## REJECT_DUPLICATE (never recolor as Dayton)

| Source | Reason |
| --- | --- |
| Wichita prairie, grain elevator, hangar, radar, runway stripe | Aviation-service plains identity ≠ Dayton gateway/test-range |
| Louisville brick arterial, Twin Spires, bourbon warehouse, Victorian, iron gate, bourbon stain | Derby / hospitality identity |
| Any Tulsa oil/neon/Art Deco (when present) | Petroleum identity |

Compatible **neutral** industrial hardware (fencing, cones, pallets, dumpsters) stays REUSE_EXACT from global sheets — do not create `dayton_*` copies.

## GENERATE_MISSING (foundation pack v1)

| # | Filename | Class |
| ---: | --- | --- |
| 1 | `dayton_terrain_gateway_approach_01` | Terrain — monitored approach / stop-line asphalt |
| 2 | `dayton_terrain_industrial_corridor_01` | Terrain — factory service corridor |
| 3 | `dayton_skyline_parallax_01` | Skyline — industrial + lab + fountain civic massing |
| 4 | `dayton_landmark_early_flight_distant_01` | Landmark — original wing/frame monument (no Wright likeness) |
| 5 | `dayton_landmark_riverscape_fountain_midground_01` | Landmark — civic fountain basin |
| 6 | `dayton_landmark_factory_sawtooth_01` | Landmark — adaptive-reuse factory |
| 7 | `dayton_landmark_navigation_lab_01` | Landmark — research annex / lab |
| 8 | `dayton_prop_neighborhood_gateway_01` | Prop — dual-column gateway, empty camera mounts |
| 9 | `dayton_overlay_copied_route_01` | Overlay — movement-history trail |
| 10 | `dayton_overlay_checkpoint_pulse_01` | Overlay — sequential gateway alert lights |
| 11 | `dayton_overlay_fountain_mist_01` | Overlay — riverfront mist |
| 12 | `dayton_decal_gateway_scrape_01` | Decal — tire/scrape at threshold |
| 13 | `dayton_decal_test_lane_stripe_01` | Decal — research test-lane marking |

Docs-only (not runtime): `dayton_identity_board_01`, `dayton_palette_board_01`.

## COMPOSE_FROM_EXISTING (district packs — foundation scope)

Five districts reuse global biome tiles + Dayton landmarks/overlays compositionally:

| District | Global biome | Dayton emphasis |
| --- | --- | --- |
| Retail Security Zone | asphalt + retail props | gateway approach terrain, gateway prop |
| Smart Downtown | downtown tile | fountain landmark, mist overlay |
| Gated Serenity | gated tile | neighborhood gateway prop |
| Civic Innovation Campus | campus tile | navigation lab, test-lane decal |
| Evidence Warehouse | warehouse tile | factory sawtooth, industrial corridor terrain |

Full per-district atlases are **out of foundation v1** (same as Wichita/Louisville).

## Explicit non-goals

- No player/enemy/boss regeneration  
- No baked LPR sprites or scan cones  
- No exact museum/aircraft replicas or Wright brothers likenesses  
- No readable signs, addresses, or brand marks  
- No recolor of prior city packs  
