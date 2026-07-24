# Wichita City Environment — Completion Receipt

| Field | Value |
| --- | --- |
| City | Wichita, Kansas |
| Level | 1 — *The Panopticon of the Plains* |
| Signature mechanic | Aircraft scanners and zoning corridors |
| Workflow | Ten-city gated production loop |
| Status | **Foundation pack complete** (v1) — merged to `main` via #28 |

## Phase checklist

| Phase | Status |
| --- | --- |
| 0 Inventory & deduplication | Done — `WICHITA_REUSE_MATRIX.md`, `WICHITA_ASSET_INVENTORY.json` |
| 1 Identity lock | Done — boards in `docs/cities/wichita/assets/` |
| 2 Shared asset mapping | Done — LPR/Blind Spot/player/guard/boss **REUSE_EXACT** |
| 3 City foundation pack | Done — arterial + prairie edge + skyline |
| 4 Five district packs | **Partial** — districts reuse global biome tiles + Wichita landmarks; not separate full district atlases |
| 5 Landmark integration | Done — monument, grain elevator, hangar, bridge, siren |
| 6 State variants | Done as overlays — radar, storm alert, aircraft shadow (not full scene duplicates) |
| 7 Assembly & validation | `make assets-check` + simulator tests |
| 8 Completion receipt | This file |

## Runtime assets shipped (`wichita_*`)

13 presentation PNGs (see `WICHITA_FILENAME_MANIFEST.json`).

## Explicit non-duplication

| Role | Action |
| --- | --- |
| Player / LPR / guard / boss / Blind Spot / suspicion | `REJECT_DUPLICATE` |
| Global env tiles (downtown, gated, campus, warehouse) | `REUSE_EXACT` as district bases |
| Generic props/decals sheets | `REUSE_EXACT` |
| LPR baked into terrain | **Forbidden** — entities remain interactive |

## Known gaps (next iteration, not blocking foundation)

- Full autotile curb/sidewalk set specific to Wichita
- Separate modular packs labeled per five sub-districts (currently compositional reuse)
- Hangar door open / damaged grain elevator state variants
- Rail-yard modular track tiles
- Keeper-inspired midground + map-icon scales (distant monument only)

## Next city in sequence

**Louisville — Derby Day Data Dragnet** — foundation also on `main` (#29). Subsequent: **Tulsa — The Petroleum Panopticon**.
