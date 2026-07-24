# GitHub issue reconciliation

Recorded during `agent/long-sprint-campaign-hardening` against `main` @ `9fdcadb` (sprint start).
Open issues evaluated: **#2** (WP1 playable foundation), **#3** (ART production exports).

This document is the durable recommendation when issue comments cannot be posted or should not auto-close work.

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
| Package + simulator gates | **Done** |
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

### Recommendation: **keep open** — substantially complete code-side; device art QA open

| Acceptance item | Status |
|---|---|
| App icon 1024² | **Attached** |
| Player 8 frames | **Attached** + `VisualAssetMap` / atlas manifest |
| LPR 3 states | **Attached** |
| Blind Spot decal | **Attached** |
| Suspicion native meter | **Done**; optional tier glyphs attached |
| Visual role map | **Done** (`docs/VISUAL_ASSET_MAP.md`) |
| Guard / boss sprites | **Partial** — art PR may land separately; shapes otherwise |
| Projectile / deployable art | **Not attached** (shape fallback) |
| Physical-device nearest-neighbor readability | **Still open** |
| Final owner art approval | **Still open** |

Do **not** close #3 until physical readability is observed and remaining reserved families are either accepted as shape-first forever or attached under the intake contract.

## Cross-cutting

- Simulator/emulator green **never** closes device acceptance language on either issue.
- Audio is out of scope for #2/#3; event-map is on main; product playback blocked until approved binaries.
