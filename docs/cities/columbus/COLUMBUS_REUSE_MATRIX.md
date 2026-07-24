# Columbus Phase 0 — Inventory & Deduplication

**City:** Columbus, Ohio · Level 7 · *The Six-Hundred-Eye Statehouse*  
**Signature mechanic:** jurisdiction splitting and statewide data sharing  
**Compared against:** global env v1, Wichita, Louisville, Tulsa, Dayton, Oakland  
**San Francisco pack:** not required as base (Columbus builds from `main`)

## Visual thesis

> A government-centered city where state, municipal, campus, suburban, and agency systems divide responsibility while sharing the same surveillance network underneath.

## REUSE_EXACT (do not regenerate)

| Asset / class | Columbus use |
| --- | --- |
| `player_*` (8) | Entity layer |
| `lpr_*` (3) | Entity layer — empty mounts only on env art |
| `guard_default` / `boss_default` | Entity layer |
| `blind_spot_decal` | Extraction |
| `suspicion_tier_*` | HUD optional |
| `env_tile_asphalt` / downtown / gated / campus / warehouse | District biome bases (compositional) |
| `env_prop_sheet_municipal` / `env_prop_sheet_retail` | Sparse prop watermarks |
| `env_decal_sheet` | Generic ground marks |
| `env_obstacle_retail_mass` | Generic obstacle mass when city massing unavailable |
| `env_parallax_skyline` | Fallback if city skyline missing |

## REUSE_VARIANT (new pixels, same role family)

| Role | Global / prior | Columbus GENERATE name |
| --- | --- | --- |
| Arterial / approach terrain | `env_tile_downtown` / asphalt | `columbus_terrain_capitol_approach_01` |
| Secondary terrain | campus / mixed | `columbus_terrain_jurisdiction_patchwork_01` |
| Skyline | `env_parallax_skyline` | `columbus_skyline_parallax_01` |

## REJECT_DUPLICATE (never recolor as Columbus)

| Source | Reason |
| --- | --- |
| Wichita prairie, grain elevator, hangar, radar, runway stripe | Plains aviation identity |
| Louisville brick arterial, Twin Spires, bourbon warehouse, Victorian, iron gate | Derby / hospitality identity |
| Tulsa oil / neon / Art Deco / pumpjack / derrick | Petroleum identity |
| Dayton gateway / flight monument / fountain plaza / test-lane | Gateway-city / aviation-heritage identity |
| Oakland port crane / container stack / marine haze / rail yard | Port / sanctuary-scanner identity |
| San Francisco fog / cable car / Golden Gate stand-ins | Bay fog identity (wrong city) |

Compatible **neutral** municipal hardware (benches empty of branding, generic curbs, dumpsters) stays REUSE_EXACT from global sheets — do not create `columbus_*` copies.

## GENERATE_MISSING (foundation pack v1)

| # | Filename | Class |
| ---: | --- | --- |
| 1 | `columbus_terrain_capitol_approach_01` | Terrain — limestone plaza + civic approach asphalt |
| 2 | `columbus_terrain_jurisdiction_patchwork_01` | Terrain — multi-agency zone floor |
| 3 | `columbus_skyline_parallax_01` | Skyline — statehouse massing + river + civic blocks |
| 4 | `columbus_landmark_ohio_statehouse_distant_01` | Landmark — neoclassical statehouse-inspired (not DC replica) |
| 5 | `columbus_landmark_scioto_riverfront_01` | Landmark — riverwalk / flood wall |
| 6 | `columbus_landmark_short_north_arch_01` | Landmark — steel gateway arch (no brand text) |
| 7 | `columbus_landmark_hearing_chamber_midground_01` | Landmark — hearing-chamber massing |
| 8 | `columbus_prop_public_comment_podium_01` | Prop — public-comment podium |
| 9 | `columbus_overlay_jurisdiction_split_01` | Overlay — agency pie-slice boundaries |
| 10 | `columbus_overlay_statewide_share_01` | Overlay — statewide data-share mesh |
| 11 | `columbus_overlay_hearing_reschedule_01` | Overlay — bureaucratic reschedule haze |
| 12 | `columbus_decal_capitol_stripe_01` | Decal — ceremonial plaza stripe |
| 13 | `columbus_decal_agency_boundary_01` | Decal — surveyor agency boundary marks |

Docs-only (not runtime): `columbus_identity_board_01`, `columbus_palette_board_01`.

## COMPOSE_FROM_EXISTING (district packs — foundation scope)

Five districts reuse global biome tiles + Columbus landmarks/overlays compositionally:

| District | Global biome | Columbus emphasis |
| --- | --- | --- |
| Retail Security Zone | asphalt + retail props | agency-boundary decal, jurisdiction split overlay |
| Smart Downtown | downtown tile | statehouse distant, capitol stripe, hearing chamber |
| Gated Serenity | gated tile | short-north arch, suburban patch in patchwork terrain |
| Civic Innovation Campus | campus tile | campus-brick patches, statewide share overlay |
| Evidence Warehouse | warehouse tile | hearing reschedule overlay, municipal massing |

Full per-district atlases are **out of foundation v1** (same as prior city packs).

## Explicit non-goals

- No player/enemy/boss regeneration  
- No baked LPR sprites or scan cones  
- No exact Ohio Statehouse photogrammetry, seals, flags, or readable agency logos  
- No DC Capitol replica silhouettes  
- No readable signs, addresses, or brand marks on arches  
- No recolor of prior city packs  
