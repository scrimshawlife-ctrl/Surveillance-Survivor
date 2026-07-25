# City-by-city landmark top-down pass

```yaml
version: 1.0.1
status: complete
last_updated: 2026-07-25
tip_base: 0322330
authority: docs/HALLMARK_ASSET_AUDIT.md · docs/HALLMARK_ASSET_REMEDIATION_RECEIPT.md
```

## Goal

Convert every city **landmark** runtime sprite to a **top-down / orthographic footprint** language that matches playfield projection. Preserve city identity; remove isometric 3D hero angles.

## Style contract (locked)

| Axis | Rule |
| --- | --- |
| View | Straight top-down / map-icon orthographic — **not** isometric 3/4 |
| Medium | Pixel municipal paint, hard edges |
| Alpha | True transparency; no magenta plates |
| Text | Never |
| Size | Per `LANDMARK_TOPDOWN_SIZES.json` (LA normalized to standard canvases) |

## Campaign results

| # | City | Landmarks | Status |
| ---: | --- | ---: | --- |
| 1 | Wichita | 4 | **Done** (3 in #64 + river monument this pass) |
| 2 | Louisville | 4 | **Done** |
| 3 | Dayton | 4 | **Done** |
| 4 | Tulsa | 4 | **Done** |
| 5 | Oakland | 4 | **Done** |
| 6 | San Francisco | 4 | **Done** |
| 7 | Columbus | 4 | **Done** |
| 8 | New York | 4 | **Done** |
| 9 | Los Angeles | 4 | **Done** (canvas normalized) |
| 10 | Atlanta | 5 | **Done** |

**Total:** 41 / 41 landmarks re-authored to top-down footprints.

## Tooling

- `scripts/ingest_landmark_topdown.py` — strip plate, crop, nearest-neighbor fit, write RuntimeSprites + xcassets
- `docs/art/LANDMARK_TOPDOWN_SIZES.json` — target dimensions

## Gates

```bash
make assets-check          # 185 runtime PNGs
make sprite-chroma-check   # OK
make test
```

## Residual

- Prop midground polish (gates already landmarks in some cities)
- Skyline painterly language still intentional far layer
- Device ART QA #3
- Some map-icons are more abstract than photoreal — acceptable for projection consistency
