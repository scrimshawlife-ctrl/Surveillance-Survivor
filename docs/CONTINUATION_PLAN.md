# Continuation Plan

## Current vertical-slice state

The deterministic Big-Box Parking Expanse vertical slice is implemented in the repository:

- fixed-step, seeded simulation with structured run receipts;
- The Ghost, visibility/Suspicion tiers, Contract Security, automated surveillance, Shift Manager, and Blind Spot extraction;
- six MVP countermeasures, twelve base upgrades, and four deterministic evolutions;
- catalog-backed player integrity and guard/boss contact damage with a non-extract defeat path;
- disabled/disrupted sensors freeze rotation and automated movement;
- SpriteKit projection, touch movement, accessibility settings, reduced motion/flash, haptics, run-summary persistence, interruption-safe pause/resume, and manual pause;
- formal visual asset map (`VisualAssetMap`) from simulation presentation roles → texture names → shape/SF-Symbol fallbacks;
- runtime sprites attached for player (8), LPR (3), Blind Spot decal, optional suspicion tier glyphs, guard/boss defaults, global environment package v1, and **Wichita + Louisville city foundation packs** (13 textures each); projectile/deployable remain shape-first;
- audio event-map catalog (`audio_events.json` + `AudioEventCatalog`); playback stays off until approved binaries exist;
- campaign unlock progression with offline store; emulator extraction and campaign UX smokes;
- run seed exposed in HUD and completion summary for device-test correlation;
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

Signed Debug deployment to the connected iPhone is automated and verified with `DEVICE_UDID=<connected-iPhone-UDID> make device-smoke`. It builds, installs, and foreground-launches the app; it does not replace acceptance observations.

Follow the exact protocol in [`RELEASE_READINESS.md`](RELEASE_READINESS.md): a full run through extraction, settings checks, background/resume, maximum-density frame capture, thermal observation, haptic clarity, and audio-route interruption observation.

The checked-in simulator gate cannot be substituted for this evidence.

### 2. Ten-city environment foundation sequence

- Global env v1 + Wichita (#28) + Louisville (#29) are on `main`. Index: [`cities/README.md`](cities/README.md).
- Continue city-by-city: **Tulsa next**, then Dayton → Oakland → SF → Columbus → NYC → LA → Atlanta.
- Always inventory/reuse first (`REUSE_EXACT` / `REUSE_VARIANT` / `GENERATE_MISSING` / `REJECT_DUPLICATE`). Never recolor prior city packs.
- Full five-district atlases per city are optional later; foundation packs (terrain + skyline + landmarks + overlays) are the merge unit.

### 3. Approved runtime asset and audio intake

- Runtime role map is live: [`VISUAL_ASSET_MAP.md`](VISUAL_ASSET_MAP.md) / `VisualAssetMap.swift`. Projectors must resolve textures through the map.
- Ingest only reviewed texture exports under the naming and dimension contract in [`VISUAL_ASSETS_V0_2_INTAKE.md`](VISUAL_ASSETS_V0_2_INTAKE.md). Remaining open entity art: projectile/deployable families and any replacement of procedural suspicion glyphs.
- Audio event-map v1 is specified in [`AUDIO_EVENT_MAP.md`](AUDIO_EVENT_MAP.md) and `audio_events.json`; attach approved binary assets before enabling playback. Do not ship placeholder system sounds as product audio.
- Preserve shape-node fallbacks and collision geometry independent of artwork.

### 4. Store-submission completion

Complete owner-provided fields in [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md): policy/support URLs, SKU, age rating, copyright, rights confirmation, release-build screenshots, review notes, and App Store Connect privacy answers.

### 5. Data-driven content (shipped)

Weapon, upgrade, enemy, wave, suspicion, boss, and district catalogs are versioned bundled JSON with schema validation, stable IDs, and fixture coverage. The district catalog preserves the canonical ten-city order, roster names, signature mechanics, and research qualifications.

Each district authors a `simulation` profile (`districts.json` schema 2) that drives the run: world bounds, obstacle geometry, player spawn, starting sensor grid, sensor deployment order, contract-security roster, guard target, suspicion pressure, boss scaling, boss spawn, and Blind Spot position. `WaveCatalog.guardPopulationCeiling` (schema 2) is the global safety bound; districts author their own target beneath it. Wichita reproduces the original vertical-slice layout and is locked by test.

Districts are fixed for the duration of a run and recorded on `RunReceipt` (schema 2). Campaign progression unlocks the next roster level after a successful Blind Spot extraction (`CampaignProgress` + offline `CampaignProgressStore`). The run-summary picker only offers unlocked cities; defeat does not advance the campaign. Audio playback still requires approved source binaries on top of the shipped event-map. Do not introduce file or network reads into the fixed-step path.

## Emulator-first while device is offline

When no physical iPhone is connected, use the full emulator suite instead of inventing new systems:

```bash
make emulator-test
```

That runs privacy → assets → package tests → simulator unit/UI → launch smoke (see [`EMULATOR_AUTOMATION.md`](EMULATOR_AUTOMATION.md)). It does **not** replace physical-device acceptance.

## Current next engineering frontier

Autonomous / offline-capable (in priority order):

1. **Tulsa city foundation pack** (inventory → GENERATE_MISSING → map → assets-check → emulator → merge when green).
2. Subsequent city foundation packs through Atlanta (same gated loop).
3. Reserved entity art: projectile / deployable families (optional).
4. Emulator suite remains the default gate while the iPhone is offline (`make emulator-test`).

Operator-required (cannot close autonomously):

1. Full physical-device acceptance per [`RELEASE_READINESS.md`](RELEASE_READINESS.md).
2. Approved audio binary bank (no system-sound placeholders).
3. Final art review for reserved/optional sprites and full five-district atlases if desired.
4. App Store owner fields in [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md).

Campaign/content-graph hardening from the long sprint is on `main` (see [`LONG_SPRINT_REPORT.md`](LONG_SPRINT_REPORT.md)). Issue reconciliation: [`ISSUE_RECONCILIATION.md`](ISSUE_RECONCILIATION.md).

## Required local gate

```bash
make validate
```

This runs the Swift package suite, XcodeGen generation, and the iOS Simulator test target. Generated `SurveillanceSurvivor.xcodeproj/` and `.codebase-memory/` remain local artifacts and must not be committed.
