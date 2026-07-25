# Hallmark audit — in-run HUD / chrome (device)

```yaml
/* Hallmark · pre-emit critique: P3 H2 E3 S3 R2 V3 */
verb: audit + remediate
target: App/RootView.swift HUDView · SuspicionMeter · control chrome
date: 2026-07-25
tip: 8578b1a (device-smoke)
device: iPhone 17 Pro landscape Debug
```

**Scope:** SwiftUI play HUD and system chrome. Not SpriteKit world art (see Art QA package).

**Genre:** atmospheric terminal-grid game HUD (existing `VisualDesignTokens`).

---

## Critical

| # | Tell | Where | Player consequence | Fix |
| --- | --- | --- | --- | --- |
| C1 | **Status block covers playfield** — tall left stack (district, title, objective, cosmetics, full suspicion card, integrity, shards, loadout names, seed, boss) in opaque 280pt panel | `HUDView` | Cones, cameras, player buried under chrome | Collapse to **single compact top strip**; drop seed/loadout names from live HUD |
| C2 | **Not true fullscreen** — system status bar / safe-area chrome still competes; landscape game should own the glass | `SurveillanceSurvivorApp` / Info.plist | Letterboxed / inset feel; wasted vertical band | Hide status bar; require fullscreen; edge-to-edge root |

---

## Major

| # | Tell | Where | Fix |
| --- | --- | --- | --- |
| M1 | Suspicion meter is a **full card** (glyph + two labels + 190×10 bar + tier copy) | `SuspicionMeter` | Compact horizontal: glyph + thin bar + tier digit only |
| M2 | Unlock cosmetics (radio / weather / trail) add **extra rows** mid-combat | `HUDView` | Single optional chip or pause-only |
| M3 | Top chrome: HUD left + 3 large bordered buttons right both use **16pt padding** into safe area | `RootView` | Tighter padding; icon-only buttons already OK |

---

## Minor

| # | Tell | Fix |
| --- | --- | --- |
| m1 | Seed always visible (debug noise) | Move to pause / summary only |
| m2 | Full loadout string list | Icon count only mid-run |
| m3 | District title can wrap 2 lines | One-line city · title truncate |

---

## What’s working

- Tokens via `VisualDesignTokens` (no mid-render rainbow)  
- Stick overlay separate from SpriteKit hit path  
- Modal upgrade draft correctly blocks game  
- A11y labels on vitals  

---

## Remediation status (this change)

- [x] C1 — compact HUD strip  
- [x] C2 — status bar hidden + fullscreen keys  
- [x] M1 — compact suspicion row  
- [x] M2/M3/m* — cosmetics/seed demoted  

**Device re-verify:** redeploy tip after merge; confirm playfield readable left-of-center.
