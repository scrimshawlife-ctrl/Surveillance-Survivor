# Visual Assets v0.2 — Production Intake Contract

## Status

- **Code-side integration:** ACTIVE
- **Binary production assets:** PARTIAL — player (8 frames), LPR (3 states), Blind Spot decal, optional suspicion tier glyphs, contract-security `guard_default`, Shift Manager `boss_default`, and 1024² App Icon under `Resources/`
- **Optional attached:** `suspicion_tier_0...5` (HUD glyphs; native meter bar/labels remain authority); `guard_default` / `boss_default` (shape fallback retained)
- **Reserved (shape fallback):** projectile / deployable names listed in the visual asset map
- **Fallback rendering:** REQUIRED for any missing name; present names load through `TextureAssetLoader` / `Assets.xcassets`
- **Runtime map:** sim role → texture → fallback is documented in [`VISUAL_ASSET_MAP.md`](VISUAL_ASSET_MAP.md) and implemented by `VisualAssetMap.swift`

Measured runtime canvases and anchors are recorded in [`VISUAL_ASSETS_V0_2_MANIFEST.json`](VISUAL_ASSETS_V0_2_MANIFEST.json).

## Canonical runtime names

### Player

- `player_idle_down`
- `player_idle_left`
- `player_idle_up`
- `player_idle_right`
- `player_walk_down`
- `player_walk_left`
- `player_walk_up`
- `player_walk_right`

### LPR camera

- `lpr_intact`
- `lpr_damaged`
- `lpr_destroyed`

### Suspicion icons

- `suspicion_tier_0` through `suspicion_tier_5`

### Environment

- `blind_spot_decal`

## Binary acceptance gates

Every runtime PNG must pass all applicable gates before shape-node fallback is disabled:

1. filename exactly matches the canonical runtime name;
2. PNG decodes without warnings;
3. sRGB color space;
4. sprites requiring isolation contain real alpha transparency;
5. no labels, captions, grid lines, or presentation borders;
6. consistent logical canvas and anchor point within each state family;
7. pixel dimensions recorded in the final manifest;
8. nearest-neighbor filtering remains readable at intended physical-device size;
9. visual bounds are independent from authoritative collision radii;
10. app icon is exactly 1024×1024, opaque, and contains no baked corner radius.

## Player atlas decision

The runtime supports deterministic logical sequence names through `PlayerAtlasManifest.swift`. Frame rectangles and final frame counts are intentionally not inferred. They must be populated only after the real v0.2 atlas is attached and measured.

Preferred delivery order:

1. individual transparent frame PNGs in `.atlas` folders; or
2. one transparent atlas plus exact pixel rect JSON.

Individual frame PNGs are preferred for the first vertical slice because they reduce slicing ambiguity and simplify Xcode asset review.

## LPR anchor convention

- common canvas across intact, damaged, and destroyed states;
- anchor at normalized `(0.5, 0.12)` unless the final art requires a documented exception;
- collision radius remains defined by simulation data, not texture dimensions;
- destruction effects may extend beyond the logical body without altering collision geometry.

## Suspicion HUD decision

The meter is implemented natively in SwiftUI in `App/SuspicionMeter.swift`. Optional tier PNGs may replace only the glyph area. Progress, labels, animation, contrast, and accessibility remain native.

## Required attachment

Upload the actual v0.2 package into the conversation or commit it to the branch. Descriptions of generated assets are not sufficient to establish dimensions, alpha integrity, crop bounds, or manifest coordinates.

After attachment, run `make assets-check`. It validates canonical runtime filenames, PNG decodability, sRGB color space, alpha presence, and shared canvas dimensions within player and LPR state families. It intentionally reports an asset-free repository as pending while binary intake is blocked.
