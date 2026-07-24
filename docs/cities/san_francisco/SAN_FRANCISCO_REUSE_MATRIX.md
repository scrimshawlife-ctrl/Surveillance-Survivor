# San Francisco Phase 0 — Inventory & Deduplication

**City:** San Francisco, California · Level 6 · *Fog of Probable Cause*  
**Signature mechanic:** fog-hidden sensors and improper searches  
**Compared against:** global env v1, Wichita, Louisville, Tulsa, Dayton, Oakland (all on `main`)

## Visual thesis

> A steep, ornate, self-consciously progressive city where fog obscures who is watching, autonomous systems follow without explanation, and every temporary safeguard quietly expands the field of observation.

## REUSE_EXACT

| Asset / class | SF use |
| --- | --- |
| `player_*`, `lpr_*`, `guard_default`, `boss_default`, `blind_spot_decal`, `suspicion_tier_*` | Entity / HUD |
| `env_tile_*` | District biome bases (compositional) |
| `env_prop_sheet_*`, `env_decal_sheet`, `env_obstacle_retail_mass` | Generic watermarks |
| `env_parallax_skyline` | Fallback only |

## REUSE_VARIANT

| Role | GENERATE name |
| --- | --- |
| Steep arterial terrain | `san_francisco_terrain_steep_arterial_01` |
| Hill stair / terrace terrain | `san_francisco_terrain_hill_stair_01` |
| Skyline | `san_francisco_skyline_parallax_01` |

## REJECT_DUPLICATE

| Source | Reason |
| --- | --- |
| Oakland crane / container / BART-like viaduct / port yard | Port identity ≠ SF hills/fog/Victorian |
| Wichita prairie / grain / hangar | Plains aviation |
| Louisville bourbon / spires | Derby hospitality |
| Tulsa derrick / pumpjack / deco oil | Petroleum |
| Dayton gateway / flight monument | Gateway checkpoints |
| Exact Golden Gate, cable-car brands, Sutro replica | Legal / IP / postcard |

Compatible neutral industrial hardware stays REUSE_EXACT from global sheets.

## GENERATE_MISSING (foundation pack v1)

| # | Filename | Class |
| ---: | --- | --- |
| 1 | `san_francisco_terrain_steep_arterial_01` | Damp steep arterial asphalt |
| 2 | `san_francisco_terrain_hill_stair_01` | Stair-step / terrace pavement |
| 3 | `san_francisco_skyline_parallax_01` | Hills + ornate mid-rise + fog |
| 4 | `san_francisco_landmark_bridge_distant_01` | Original suspension-bridge silhouette |
| 5 | `san_francisco_landmark_victorian_midground_01` | Victorian bay-window facade |
| 6 | `san_francisco_landmark_cable_track_01` | Cable-track infrastructure (no brand cars) |
| 7 | `san_francisco_landmark_comms_tower_01` | Original hilltop communications tower |
| 8 | `san_francisco_prop_av_shell_01` | Empty autonomous vehicle shell (no logos) |
| 9 | `san_francisco_overlay_fog_band_01` | Modular street fog band |
| 10 | `san_francisco_overlay_prediction_haze_01` | Predictive-observation haze |
| 11 | `san_francisco_overlay_improper_search_01` | Improper-search / borrowed-access wash |
| 12 | `san_francisco_decal_cable_groove_01` | Street cable groove |
| 13 | `san_francisco_decal_damp_asphalt_01` | Damp asphalt stain |

Docs-only: `san_francisco_identity_board_01`, `san_francisco_palette_board_01`.

## COMPOSE_FROM_EXISTING (districts)

| District | Global biome | SF emphasis |
| --- | --- | --- |
| Retail Security Zone | asphalt | steep arterial, cable groove, fog |
| Smart Downtown | downtown | Victorian, prediction haze |
| Gated Serenity | gated | hill stair, comms tower, fog |
| Civic Innovation Campus | campus | AV shell, improper-search overlay |
| Evidence Warehouse | warehouse | bridge distant, damp asphalt |

## Explicit non-goals

- Not a recolored Oakland package  
- No tourists, crowds, branded transit, exact landmarks  
- No baked LPR / scan cones / HUD  
- No mocking of residents or marginalized communities  
