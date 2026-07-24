# City environment production

Gated, inventory-first workflow for per-city presentation packs. Simulation authority for all ten cities lives in `Sources/SurveillanceCore/Resources/Content/districts.json`. **This tree owns art production evidence only.**

## Status on `main`

| Level | City | Title | Foundation pack | Merged |
| ---: | --- | --- | --- | --- |
| 1 | Wichita | The Panopticon of the Plains | 13 × `wichita_*` | [#28](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/28) |
| 2 | Louisville | Derby Day Data Dragnet | 13 × `louisville_*` | [#29](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/29) |
| 3 | Tulsa | The Petroleum Panopticon | — | **Next** |
| 4 | Dayton | Gateway City: Every Camera Counts | — | Not started |
| 5 | Oakland | The Sanctuary Scanner | — | Not started |
| 6 | San Francisco | Fog of Probable Cause | — | Not started |
| 7 | Columbus | The Six-Hundred-Eye Statehouse | — | Not started |
| 8 | New York City | The Five-Borough Omnigaze | — | Not started |
| 9 | Los Angeles | Thirty-Five Hundred Eyes, No One in Charge | — | Not started |
| 10 | Atlanta | Flock's Nest | — | Not started |

Roster authority: [`TEN_CITY_CAMPAIGN_ROSTER.md`](../TEN_CITY_CAMPAIGN_ROSTER.md). Projection rules: [`ENVIRONMENT_ART_MAP.md`](../ENVIRONMENT_ART_MAP.md).

## Per-city deliverables

Each finished city directory should contain:

| File | Purpose |
| --- | --- |
| `*_REUSE_MATRIX.md` | Phase 0 inventory vs global env + prior cities |
| `*_ASSET_INVENTORY.json` | Structured classify list |
| `*_FILENAME_MANIFEST.json` | Runtime names + docs-only boards |
| `*_COMPLETION_RECEIPT.md` | Phase checklist, gaps, next city |
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

**Hard rules**

1. Never recolor Wichita as Louisville (or any city as another).
2. Never regenerate player / LPR / guard / boss / Blind Spot for a city pack.
3. Never bake interactive LPR poles into terrain art.
4. Partial five-district packs are OK for foundation: global biomes + city landmarks/overlays.
5. Docs-only boards (`*_identity_board_*`, `*_palette_board_*`) are not runtime.

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

Produce **Tulsa** foundation pack only after inventory against global env + Wichita + Louisville, then open a single city PR following the same structure as Louisville.
