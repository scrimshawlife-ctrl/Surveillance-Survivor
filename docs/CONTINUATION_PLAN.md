# Continuation Plan

## Current vertical-slice state

The deterministic Big-Box Parking Expanse vertical slice is implemented in the repository:

- fixed-step, seeded simulation with structured run receipts;
- The Ghost, visibility/Suspicion tiers, Contract Security, automated surveillance, Shift Manager, and Blind Spot extraction;
- six MVP countermeasures, twelve base upgrades, and four deterministic evolutions;
- SpriteKit projection, touch movement, accessibility settings, reduced motion/flash, haptics, run-summary persistence, and interruption-safe pause/resume;
- deterministic core tests, iOS Simulator tests, GitHub Actions Simulator tests, privacy manifest, and App Store metadata scaffold.

This is **not** release-ready. The distinction between simulator proof and physical-device proof is tracked in [`RELEASE_READINESS.md`](RELEASE_READINESS.md).

## Authority boundaries

```text
SurveillanceCore
  owns deterministic state, content values, event ordering, combat, upgrades, and receipts

SpriteKit
  projects authoritative snapshots and owns no gameplay truth

SwiftUI
  owns lifecycle shell, HUD, accessibility controls, overlays, and receipt persistence
```

## Current engineering priorities

### 1. Physical-device acceptance

Follow the exact protocol in [`RELEASE_READINESS.md`](RELEASE_READINESS.md): a full run through extraction, settings checks, background/resume, maximum-density frame capture, thermal observation, haptic clarity, and audio-route interruption observation.

The checked-in simulator gate cannot be substituted for this evidence.

### 2. Approved runtime asset and audio intake

- Ingest only reviewed texture exports under the naming and dimension contract in [`VISUAL_ASSETS_V0_2_INTAKE.md`](VISUAL_ASSETS_V0_2_INTAKE.md).
- Add audio only after approved source assets and an event-map specification exist; do not ship placeholder system sounds as product audio.
- Preserve shape-node fallbacks and collision geometry independent of artwork.

### 3. Store-submission completion

Complete owner-provided fields in [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md): policy/support URLs, SKU, age rating, copyright, rights confirmation, release-build screenshots, review notes, and App Store Connect privacy answers.

### 4. Data-driven content migration

The current vertical-slice content is deterministic but still compiled into the core. Migrate content definitions to versioned bundled JSON only with schema validation, stable IDs, and fixture coverage; do not introduce file or network reads into the fixed-step path.

## Required local gate

```bash
make validate
```

This runs the Swift package suite, XcodeGen generation, and the iOS Simulator test target. Generated `SurveillanceSurvivor.xcodeproj/` and `.codebase-memory/` remain local artifacts and must not be committed.
