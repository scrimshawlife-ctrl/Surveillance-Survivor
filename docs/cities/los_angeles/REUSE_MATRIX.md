# Los Angeles Phase 0 — Inventory & Deduplication

**City:** Los Angeles, California · Level 9 · *Thirty-Five Hundred Eyes, No One in Charge*  
**Signature mechanic:** decentralized public-private surveillance networks; private systems remain active after city contract ends  
**Compared against:** global env v1 + Wichita, Louisville, Tulsa, Dayton, Oakland, San Francisco, Columbus, New York (all prior city packs)

## Visual thesis

> A vast horizontal media metropolis where city agencies, studios, malls, HOAs, parking operators, and private security all observe independently then share enough data to form a citywide dragnet with no single accountable owner. Sun-faded sprawl, freeways, strip malls, studio backlots, gated entries, observatory hills, port logistics — not cyberpunk, not Blade Runner, not NY density.

## REUSE_EXACT

| Asset / class | LA use |
| --- | --- |
| `player_*`, `lpr_*`, `guard_default`, `boss_default`, `blind_spot_decal`, `suspicion_tier_*` | Entity / HUD layers (never city-varianted) |
| `env_tile_*` (asphalt, downtown, gated, campus, warehouse) | District biome bases (compositional) |
| `env_prop_sheet_*`, `env_decal_sheet`, `env_obstacle_retail_mass` | Generic retail / industrial watermarks |
| `env_parallax_skyline` | Fallback skyline only |

## REUSE_VARIANT

| Role | GENERATE name |
| --- | --- |
| Freeway arterial terrain | `los_angeles_terrain_freeway_arterial_01` |
| Sun-bleached parking / strip lot | `los_angeles_terrain_sunbleached_lot_01` |
| Horizontal sprawl skyline | `los_angeles_skyline_parallax_01` |

## REJECT_DUPLICATE

| Source | Reason |
| --- | --- |
| `player_city_variant` / `lpr_city_variant` / `guard_city_variant` / `boss_city_variant` / `blind_spot_city_variant` | Hard rule: never regenerate core entities per city |
| `new_york_density_grid_scaffold_subway` | Vertical density / subway — wrong LA sprawl |
| `san_francisco_fog_cable_victorian_hills` | Fog hills / cable / Victorian — wrong identity |
| `oakland_port_crane_container_bart` | Bay port / BART — not LA port logistics silhouette |
| `columbus_statehouse_arches_hearing` | Midwest civic capitol — not media metropolis |
| `tulsa_neon_oil_deco` | Oil / deco neon — wrong palette and thesis |
| `louisville_victorian_bourbon_spires` | Derby hospitality — not sun-faded strip sprawl |
| `dayton_gateway_flight_industrial` | Gateway / flight industrial — not freeways / backlots |
| `wichita_prairie_hangar_grain_radar` | Plains aviation — wrong geography |
| `blade_runner_cyberpunk_vertical_city` | Forbidden LA cliché — no neon rain megacity |
| `hollywood_sign_letters_or_brand_logos` | No Hollywood Sign letters, studio marks, real brands |
| `prior_city_identity_recolor` | Never recolor City A as City B |

Neutral fencing, cones, bollards, generic asphalt fragments: REUSE_EXACT from global sheets only.

## GENERATE_MISSING (foundation v1 — 13)

| # | Filename | Class |
| ---: | --- | --- |
| 1 | `los_angeles_terrain_freeway_arterial_01` | Multi-lane freeway / arterial asphalt |
| 2 | `los_angeles_terrain_sunbleached_lot_01` | Sun-faded strip-mall / surface lot fill |
| 3 | `los_angeles_skyline_parallax_01` | Low-rise horizontal skyline + basin haze |
| 4 | `los_angeles_landmark_observatory_hills_distant_01` | Hills + observatory dome (distant, no logos) |
| 5 | `los_angeles_landmark_studio_backlot_01` | Abstract studio soundstage / backlot wall |
| 6 | `los_angeles_landmark_gated_community_gate_01` | Gated-entry monument (generic, no HOA brands) |
| 7 | `los_angeles_landmark_port_logistics_distant_01` | Distant port logistics silhouette (not Oakland crane kit) |
| 8 | `los_angeles_prop_parking_booth_01` | Private parking operator booth |
| 9 | `los_angeles_overlay_private_operator_mesh_01` | Multi-operator private surveillance mesh |
| 10 | `los_angeles_overlay_contract_void_01` | City contract ended / private systems still live |
| 11 | `los_angeles_overlay_marine_layer_haze_01` | Morning marine-layer / basin haze |
| 12 | `los_angeles_decal_faded_lane_paint_01` | Sun-bleached lane paint |
| 13 | `los_angeles_decal_studio_spike_mark_01` | Abstract backlot spike / mark (no logos) |

Docs-only: `los_angeles_identity_board_01`, `los_angeles_palette_board_01`.

## COMPOSE_FROM_EXISTING (districts)

| District | Global biome | LA emphasis |
| --- | --- | --- |
| Retail Security Zone | asphalt | sunbleached lot, parking booth, private mesh overlay |
| Smart Downtown | downtown | skyline parallax, freeway arterial, marine-layer haze |
| Gated Serenity | gated | gated community gate, contract-void overlay |
| Civic Innovation Campus | campus | observatory hills distant, private operator mesh |
| Evidence Warehouse | warehouse | studio backlot, port logistics distant, studio spike decal |

## Mechanic note — contract void

Signature satire: when the municipal contract ends, **city cameras may go dark while private HOA, mall, studio, parking, and neighboring-jurisdiction systems stay hot**. Foundation encodes this as `los_angeles_overlay_contract_void_01` + `los_angeles_overlay_private_operator_mesh_01` (overlays, not baked terrain logic).

## Explicit non-goals

- No Blade Runner / cyberpunk vertical neon city  
- No Hollywood Sign letterforms, studio logos, real brands, celebrity likenesses  
- No NY grid density, subway portals, or scaffold sheds as identity  
- No Oakland port-crane / BART recolor; LA port is distant logistics only  
- No baked LPR poles, scan cones, or interactive surveillance into terrain  
- No player / LPR / guard / boss / Blind Spot city variants  
