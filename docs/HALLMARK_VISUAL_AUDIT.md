# Hallmark visual audit — Surveillance Survivor HUD / presentation

```yaml
version: 1.0.0
status: applied
last_updated: 2026-07-25
genre: atmospheric
theme: terminal-grid
```

**Verb:** `hallmark audit` on App HUD + runtime presentation surface, then recommended fixes applied.

## Pre-flight

- Framework: SwiftUI shell + SpriteKit game (`App/`, `Game/`)
- Motion: presentation pipeline present; reduced-motion settings exist
- Palette: previously improvised `Color.cyan` / pure black (no token lock)
- Fonts: system monospaced (intentional terminal-grid voice for satire product)
- Runtime sprites: 179 PNGs under `Resources/RuntimeSprites` (city packs + combat + multi-frame)

## Findings (audit)

### Critical

| Tell | Where | Fix applied |
| --- | --- | --- |
| Pure black paper | `GameScene.backgroundColor = .black`, panel `.black.opacity` | Tinted paper via `VisualDesignTokens.skPaper` / `paper` |
| Rainbow / multi-hue gradient meter | `SuspicionMeter` tier-5 `LinearGradient([.red,.purple,.cyan])` | Solid per-tier accent ramp (`suspicionFill`) |
| Mid-render color improvisation | HUD/overlays/stick ad-hoc `.cyan` / `.white` | Locked tokens in `App/VisualDesignTokens.swift` |

### Major

| Tell | Where | Fix applied |
| --- | --- | --- |
| Eyebrow product title shouting | HUD `SURVEILLANCE SURVIVOR` above district | Lead with district + objective; drop title eyebrow |
| Generic borderedProminent CTA stack | Upgrade draft cards all cyan prominent | Plain tokenized cards + hairline rule |
| Centred hierarchy noise | Objective buried under brand + vitals | Objective elevated under district identity |

### Minor / deferred

| Tell | Notes |
| --- | --- |
| Simulator screenshot orientation | Smoke capture often portrait device with landscape app → looks rotated; AppDelegate already forces landscape mask. Physical-device ART QA still required (#3). |
| Full-bleed haze overlays | Many `*_overlay_*` textures are full-frame atmospheric (not broken chroma); no mass re-gen this pass. |
| Runtime sprite variety | Ten-city foundation already distinct; mega-atlas polish remains P7. |

## Summary — 3 critical · 3 major · 3 minor deferred

**Verdict (pre-fix):** reads as AI-tinted terminal HUD (cyan-on-black + rainbow tier).  
**Verdict (post-fix):** atmospheric terminal-grid with locked tokens; still monospaced by product intent.

## Files touched

- `App/VisualDesignTokens.swift` (new)
- `App/RootView.swift`
- `App/SuspicionMeter.swift`
- `App/MovementStickOverlay.swift`
- `Game/Scenes/GameScene.swift`
- this receipt

## Gates

```bash
make test
make emulator-test   # preferred after xcodegen
```
