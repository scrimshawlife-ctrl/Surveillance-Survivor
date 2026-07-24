# City environment production

Gated, inventory-first workflow for per-city presentation packs. Simulation authority for all ten cities lives in `Sources/SurveillanceCore/Resources/Content/districts.json`. **This tree owns art production evidence only.**

Full PR/issue board: [`../REPO_STATUS.md`](../REPO_STATUS.md).

## Status (audit 2026-07-24 — post Atlanta)

| Level | City | Title | Foundation pack | Status |
| ---: | --- | --- | --- | --- |
| 1 | Wichita | The Panopticon of the Plains | 13 × `wichita_*` | **On `origin/main`** [#28](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/28) |
| 2 | Louisville | Derby Day Data Dragnet | 13 × `louisville_*` | **On `origin/main`** [#29](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/29) |
| 3 | Tulsa | The Petroleum Panopticon | 13 × `tulsa_*` | **On `origin/main`** [#33](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/33) |
| 4 | Dayton | Gateway City: Every Camera Counts | 13 × `dayton_*` | **On `origin/main`** [#31](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/31) |
| 5 | Oakland | The Sanctuary Scanner | 13 × `oakland_*` | **On `origin/main`** [#32](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/32) |
| 6 | San Francisco | Fog of Probable Cause | 13 × `san_francisco_*` | **On `origin/main`** [#35](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/35) |
| 7 | Columbus | The Six-Hundred-Eye Statehouse | 13 × `columbus_*` | **On `origin/main`** [#36](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/36) |
| 8 | New York City | The Five-Borough Omnigaze | 13 × `new_york_*` | **Local `main` only** — no open PR |
| 9 | Los Angeles | Thirty-Five Hundred Eyes, No One in Charge | 13 × `los_angeles_*` | **Local `main` only** — no open PR |
| 10 | Atlanta | Flock's Nest | 13 × `atlanta_*` | **Local `main` only** — no open PR |

Local runtime total with all ten packs + globals: **160** PNGs (`make assets-check`).

Roster authority: [`TEN_CITY_CAMPAIGN_ROSTER.md`](../TEN_CITY_CAMPAIGN_ROSTER.md). Projection rules: [`ENVIRONMENT_ART_MAP.md`](../ENVIRONMENT_ART_MAP.md).

## Per-city deliverables

Each finished city directory should contain:

| File | Purpose |
| --- | --- |
| `*_REUSE_MATRIX.md` or `REUSE_MATRIX.md` | Phase 0 inventory vs global env + prior cities |
| `*_ASSET_INVENTORY.json` or `ASSET_INVENTORY.json` | Structured classify list |
| `*_FILENAME_MANIFEST.json` or `FILENAME_MANIFEST.json` | Runtime names + docs-only boards |
| `*_COMPLETION_RECEIPT.md` or `COMPLETION_RECEIPT.md` | Phase checklist, gaps, next city |
| `*_QA_REPORT.md` or `QA_REPORT.md` | Landscape iPhone QA (Wichita/Louisville may omit) |
| `assets/` | Docs-only identity/palette boards + reference copies (optional) |

Runtime binaries ship under:

- `Resources/RuntimeSprites/<name>.png`
- `Resources/Assets.xcassets/<name>.imageset/`

Names must match `GameAssetName` and `scripts/validate_visual_assets.sh`.

## Reuse classes (required)

| Class | Meaning |
| --- | --- |
| `REUSE_EXACT` | Ship existing asset as-is (player, LPR, global biome tiles, generic prop sheets, …) |
| `REUSE_VARIANT` | Same role, new city-specific pixels (skyline, arterial terrain) |
| `GENERATE_MISSING` | No prior asset covers the role; create new |
| `REJECT_DUPLICATE` | Do not recolor/relabel another city’s identity assets |
| `CAMPAIGN_CALLBACK` | Atlanta only: reintroduce prior-city systems as modular echoes (not recolors) |

**Hard rules**

1. Never recolor City A as City B.
2. Never regenerate player / LPR / guard / boss / Blind Spot for a city pack.
3. Never bake interactive LPR poles into terrain art.
4. Partial five-district packs are OK for foundation: global biomes + city landmarks/overlays.
5. Docs-only boards (`*_identity_board_*`, `*_palette_board_*`) are not runtime.
6. When wiring a new city, **add** enums/roles — do not replace prior city packs.

## Phase loop (per city)

0. Inventory & deduplication  
1. Identity lock (docs boards)  
2. Shared asset mapping (REUSE_EXACT globals)  
3. City foundation terrain + skyline  
4. District packs (compositional / partial OK)  
5. Landmark integration  
6. State overlays (not full scene duplicates)  
7. `make assets-check` + simulator tests  
8. Completion receipt → merge when green → next city  

## Code touchpoints

| Area | Location |
| --- | --- |
| Names | `Game/Rendering/GameAssetName.swift` |
| Roles / sizes | `Game/Rendering/VisualAssetMap.swift` |
| Placement | `Game/Rendering/WorldProjector.swift` |
| Allow-list | `scripts/validate_visual_assets.sh` |

## Next action

1. Foundation sequence **complete on `main`** (#37). No city 11.  
2. Device ART readability + owner ship note for issue [#3](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/issues/3) — [`ART_PRODUCTION_READINESS.md`](../ART_PRODUCTION_READINESS.md).  
3. Optional later: five-district mega-atlases, Atlanta boss-phase overlays.  
4. Product sequencing: [`ROADMAP.md`](../ROADMAP.md).  
