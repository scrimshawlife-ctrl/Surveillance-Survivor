# Visual Asset Map

Authoritative runtime mapping from **simulation presentation roles** → **texture names** → **availability / fallback**.

Implementation:

| Layer | File | Responsibility |
| --- | --- | --- |
| Roles + sizes + anchors | [`Game/Rendering/VisualAssetMap.swift`](../Game/Rendering/VisualAssetMap.swift) | sim state → role → `Entry` |
| Logical names | [`Game/Rendering/GameAssetName.swift`](../Game/Rendering/GameAssetName.swift) | string namespace only |
| Load + availability | [`Game/Rendering/TextureAssetLoader.swift`](../Game/Rendering/TextureAssetLoader.swift) | `UIImage` / `SKSpriteNode`, nil when missing |
| World projection | [`Game/Rendering/EntityProjector.swift`](../Game/Rendering/EntityProjector.swift) | resolve via map; shape fallback |
| HUD glyph | [`App/SuspicionMeter.swift`](../App/SuspicionMeter.swift) | optional tier textures; native bar/labels |

## Rules

1. **Projectors and HUD must not hard-code texture strings.** Resolve through `VisualAssetMap` (roles) and `GameAssetName` (namespace constants used only by the map).
2. **Missing binaries keep product fallbacks.** Shape nodes in SpriteKit; SF Symbol for suspicion glyph. Collision radii stay in simulation data.
3. **`requiredForMVP`** marks textures that must be present for the current art slice. Optional / reserved names may be absent forever without breaking play.
4. **Display size and anchor live on the map entry**, not scattered through projectors.
5. **Intake gates** remain in [`VISUAL_ASSETS_V0_2_INTAKE.md`](VISUAL_ASSETS_V0_2_INTAKE.md) and `make assets-check`.

## Role matrix

| Role | Asset name | Required | Fallback |
| --- | --- | --- | --- |
| `playerIdle*` / `playerWalk*` (8) | `player_idle_*` / `player_walk_*` | yes | white/cyan circle |
| `lprIntact` / `lprDamaged` / `lprDestroyed` | `lpr_*` | yes | yellow/orange/gray pole |
| `blindSpotDecal` | `blind_spot_decal` | yes | cyan ring shape |
| `suspicionTier0`…`5` | `suspicion_tier_N` | no | SF Symbol eye |
| `guardDefault` | `guard_default` | no (attached) | colored rect by archetype |
| `bossDefault` | `boss_default` | no (attached) | purple rect |
| `projectileDefault` | `projectile_default` | no | weapon-tinted circle |
| `mirrorArray` / `signalFlood` | `deployable_*` | no | teal / yellow shapes |

## State → role helpers

- **Player facing:** `VisualAssetMap.playerRole(velocityX:velocityY:heading:)` — velocity when speed > 8, else heading; four cardinal buckets (sim Y-up).
- **LPR damage:** `lprRole(health:)` — destroyed ≤ 0, damaged < 30, else intact.
- **Suspicion:** `suspicionRole(tier:)` — clamps 0…5.
- **Entity kind default:** `primaryRole(for: EntityKind)`.

## Diagnostics

```swift
TextureAssetLoader.availabilityReport()   // [(name, required, available)]
TextureAssetLoader.missingRequiredAssets()
```

## Binary layout

- Source export: `Resources/RuntimeSprites/*.png`
- Xcode catalog: `Resources/Assets.xcassets/<name>.imageset/`
- Dimensions / intake notes: [`VISUAL_ASSETS_V0_2_MANIFEST.json`](VISUAL_ASSETS_V0_2_MANIFEST.json)

## Tests

[`Tests/SurveillanceSurvivorTests/VisualAssetMapTests.swift`](../Tests/SurveillanceSurvivorTests/VisualAssetMapTests.swift) locks role uniqueness, required set, facing/LPR/tier helpers, entity-kind coverage, and alignment with `PlayerAtlasManifest` / `GameAssetName`.
