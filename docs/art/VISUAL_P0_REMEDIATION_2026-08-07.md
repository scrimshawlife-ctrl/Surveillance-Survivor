# Visual P0 remediation — 2026-08-07

## Scope

Level-by-level audit follow-up: wrong-subject landmarks, wiped Tulsa overlay,
baked LPR scan beams, and empty-content gate.

## Changes

| Asset | Before | After |
| --- | --- | --- |
| `louisville_landmark_twin_spires_distant_01` | Sunglasses silhouette | Twin brick towers + grandstand (Churchill Downs read), no labels |
| `new_york_landmark_scaffold_shed_01` | Fireplace / stove | Top-down scaffold sidewalk shed + caution stripe |
| `tulsa_overlay_refinery_haze_01` | Fully wiped (a≈0, magenta RGB under) | Soft industrial haze with true alpha |
| `lpr_intact` | Baked warm scan cone | Camera pole + red LED only (procedural cone owns scan) |
| `lpr_damaged` / `lpr_destroyed` | Residual warm cone risk | Beam candidates stripped; cyan shatter preserved on destroyed |

RuntimeSprites and matching `Assets.xcassets/*.imageset` copies updated together.

## Gate

- New: `scripts/validate_sprite_content.py` (empty/wiped hard fail)
- Hooked from `scripts/validate_visual_assets.sh` and `make sprite-content-check`
- Residual magenta-under-transparent → **WARN only** (does not fail composite)

## Validation

```bash
make assets-check
make sprite-content-check
make sprite-chroma-check
```

## Residual (not this pass)

- Magenta RGB under transparent on several city decals/overlays (WARN)
- Oakland crane silhouette polish (P2)
- Combat CGI vs pixel style (P2)
- Physical-device ART QA (#3) still open
