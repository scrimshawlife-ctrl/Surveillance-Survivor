# Visual Assets v0.1 — Integration Audit

## Status

The uploaded visual pack establishes a strong and coherent art direction, but it is not yet a production-ready SpriteKit asset bundle.

## Observed inventory

| Asset | Reported role | Actual dimensions | Alpha | Runtime status |
|---|---|---:|---|---|
| `AppIcon_PixelArt_1024.png` | App icon | 784×1168 | fully opaque | reference only; must be re-exported square |
| `Player_SpriteSheet_TopDown.png` | player animation sheet | 1168×784 | fully opaque | reference board; must be sliced/re-exported |
| `LPR_Camera_Pole_States.png` | LPR intact/damaged/destroyed states | 1168×784 | fully opaque | reference board; must be re-exported as isolated states |
| `Suspicion_Meter_HUD.png` | six-tier HUD | 1168×784 | fully opaque | visual reference; rebuild as native HUD components |
| `KeyArt_Promo_Banner.png` | promotional key art | 1168×784 | fully opaque | usable for marketing/reference, not gameplay |
| `Concept_Illustration_Cinematic.png` | concept/title art | 784×1168 | fully opaque | usable for marketing/reference, not gameplay |

## Canonical art direction

- pixel-art dystopian satire;
- asphalt and deep navy backgrounds;
- cyan `#00F5FF` for Blind Spot and resistance systems;
- red `#FF1A3C` for active surveillance and danger;
- yellow `#FFEA00` for warnings and upgrade affordances;
- glitch, scanline, and digital-interference motifs;
- high-contrast silhouettes readable on an iPhone in landscape.

## Production export contract

### App icon

Required:

- exactly 1024×1024 pixels;
- sRGB PNG;
- no transparency;
- no rounded corners baked into the image;
- critical subject matter inside the central safe area;
- readability verified at 180×180, 120×120, 80×80, and 40×40.

### Player atlas

Required:

- transparent background;
- uniform cell dimensions;
- explicit row/column map;
- no captions, labels, borders, or presentation framing;
- nearest-neighbor-compatible pixel edges;
- consistent anchor point and feet baseline;
- initial MVP set: four directions × idle and walk;
- deterministic frame names such as `player_down_idle_0`.

### LPR camera states

Required as separate transparent PNGs or one texture atlas:

- `lpr_intact`;
- `lpr_damaged`;
- `lpr_destroyed`;
- common canvas size and anchor;
- collision footprint documented separately from visual bounds.

### Suspicion HUD

The provided board is a design reference. The production HUD should remain native SwiftUI/SpriteKit so values, accessibility labels, Dynamic Type behavior, and reduced-motion behavior are not baked into a bitmap.

## Integration policy

1. Preserve source boards under `ArtSource/VisualPackV0_1/` when binary upload is available.
2. Place runtime exports under `Resources/Assets.xcassets` or `Resources/Textures.atlas`.
3. Runtime code references logical asset names only through `GameAssetName`.
4. If a runtime texture is unavailable, use the current shape-node fallback.
5. Never infer sprite slicing coordinates from artwork by guesswork; require a manifest.
6. Visual state must remain a projection of authoritative simulation state.

## Readiness classification

- **OBSERVED:** visual direction is coherent and aligned with the game concept.
- **OBSERVED:** the supplied files have no usable transparency and several stated dimensions do not match the files.
- **INFERRED:** these are presentation/reference generations rather than final production exports.
- **NOT_COMPUTABLE:** exact sprite frame boundaries and animation cadence cannot be derived safely without an explicit frame manifest or clean exports.
