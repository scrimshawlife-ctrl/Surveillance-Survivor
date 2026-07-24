# GitHub issue reconciliation

**Updated:** 2026-07-24 (repo audit after Dayton #31 on `main`; Tulsa #33 and Oakland #32 open).  
Prior long-sprint note was against `main` @ `9fdcadb`. Live board: [`REPO_STATUS.md`](REPO_STATUS.md).

Open issues evaluated: **#2** (WP1 playable foundation), **#3** (ART production exports).  
Closed: **#4** (WP2A countermeasures), **#6** (WP2B Redaction/Identity).

## Issue #2 — WP1 Complete playable iPhone foundation

### Original acceptance (summary)

- Bounded virtual-stick input and left-handed configuration
- Project all authoritative entities into SpriteKit
- Camera follow and world bounds
- Collision broad phase and contact resolution
- Node/projectile pooling
- Atomic pause on interruption; resume without duplicates
- Responsive landscape controls on **physical** iPhone
- Deterministic state independent of render frame rate
- Core tests and simulator build pass

### Recommendation: **keep open** — partially complete

| Acceptance item | Status |
|---|---|
| Virtual stick + handedness | **Done** (SwiftUI stick overlay) |
| Entity projection | **Done** (`EntityProjector`) |
| Camera follow / world bounds | **Done** |
| Collision / contact | **Done** (core) |
| Pooling | **Done** (entity node pool) |
| Pause / interruption freeze | **Done** (app shell + scene) |
| Campaign / extraction / ten-city sim profiles | **Done** (long sprint + catalog smokes) |
| Package + simulator gates | **Done** (`make emulator-test` / CI) |
| Physical iPhone responsiveness / landscape acceptance | **Still open** |
| Device background/reopen evidence | **Still open** |

Do **not** close #2 until physical-device acceptance items in [`RELEASE_READINESS.md`](RELEASE_READINESS.md) are filed with dated receipts.

## Issue #3 — ART Convert visual pack v0.1 into production iOS exports

### Original acceptance (summary)

- App icon 1024²
- Player atlas four directions idle/walk
- LPR three states common canvas/anchor
- Suspicion HUD native (optional tier icons)
- No labels/borders; alpha verified; nearest-neighbor on device

### Recommendation: **keep open** — substantially expanded beyond v0.1; device QA still required

| Acceptance item | Status |
|---|---|
| App icon 1024² | **Attached** |
| Player 8 frames | **Attached** + `VisualAssetMap` / atlas manifest |
| LPR 3 states | **Attached** |
| Blind Spot decal | **Attached** |
| Suspicion native meter | **Done**; optional tier glyphs attached |
| Visual role map | **Done** (`docs/VISUAL_ASSET_MAP.md`) |
| Guard / boss sprites | **Attached** (`guard_default`, `boss_default`) |
| Global environment package v1 | **On `main`** (#27) |
| City foundation packs | **Wichita + Louisville + Dayton on `main`**; Tulsa #33 + Oakland #32 open |
| Projectile / deployable art | **Not attached** (shape fallback) |
| Physical-device nearest-neighbor readability | **Still open** |
| Final owner art approval | **Still open** |

Do **not** close #3 until physical readability is observed and remaining reserved families are either accepted as shape-first forever or attached under the intake contract. City foundation work tracks under [`cities/README.md`](cities/README.md) and does not by itself close #3.

## Open PRs (art) — not issues

| PR | Action |
| ---: | --- |
| #32 Oakland foundation | Merge when CI green |
| #33 Tulsa foundation | Merge when CI green |

## Cross-cutting

- Simulator/emulator green **never** closes device acceptance language on either issue.
- Audio is out of scope for #2/#3; event-map is on main; product playback blocked until approved binaries.
- Prefer documenting status in this file + [`REPO_STATUS.md`](REPO_STATUS.md) over proliferating new tracking issues for each city pack.
