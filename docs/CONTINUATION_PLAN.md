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
- runtime sprites attached for player (8), LPR (3), Blind Spot decal, optional suspicion tier glyphs, guard/boss defaults, global environment package v1, and **Wichita + Louisville + Dayton city foundation packs** (13 textures each on `main`); Tulsa (#33) and Oakland (#32) foundation packs are open PRs; projectile/deployable remain shape-first;
- audio event-map catalog (`audio_events.json` + `AudioEventCatalog`); playback stays off until approved binaries exist;
- canonical ElevenLabs production bible, machine-readable audio work queue, remote-agent execution packet, and `make audio-check` drift gate;
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

- Global env v1 + Wichita (#28) + Louisville (#29) + **Dayton (#31)** are on `main`. Index: [`cities/README.md`](cities/README.md). Live PR board: [`REPO_STATUS.md`](REPO_STATUS.md).
- Open foundation PRs: **Tulsa #33**, **Oakland #32** (merge when green; independent).
- After those land: **San Francisco → Columbus → NYC → LA → Atlanta**.
- Always inventory/reuse first (`REUSE_EXACT` / `REUSE_VARIANT` / `GENERATE_MISSING` / `REJECT_DUPLICATE`). Never recolor prior city packs.
- Full five-district atlases per city are optional later; foundation packs (terrain + skyline + landmarks + overlays) are the merge unit.

### 3. Approved runtime asset and ElevenLabs audio intake

- Runtime role map is live: [`VISUAL_ASSET_MAP.md`](VISUAL_ASSET_MAP.md) / `VisualAssetMap.swift`. Projectors must resolve textures through the map.
- Ingest only reviewed texture exports under the naming and dimension contract in [`VISUAL_ASSETS_V0_2_INTAKE.md`](VISUAL_ASSETS_V0_2_INTAKE.md). Remaining open entity art: projectile/deployable families and any replacement of procedural suspicion glyphs.
- Audio event-map v1 is specified in [`AUDIO_EVENT_MAP.md`](AUDIO_EVENT_MAP.md) and `audio_events.json`; attach approved binary assets before enabling playback. Do not ship placeholder system sounds as product audio.
- ElevenLabs creative authority: [`AUDIO_ASSET_PRODUCTION_BIBLE.md`](AUDIO_ASSET_PRODUCTION_BIBLE.md).
- Machine-readable queue and status authority: [`AUDIO_ASSET_MANIFEST.json`](AUDIO_ASSET_MANIFEST.json).
- Remote execution order, receipts, directory contract, and acceptance gates: [`AUDIO_AGENT_EXECUTION.md`](AUDIO_AGENT_EXECUTION.md).
- Run `make audio-check` before and after any audio work. It verifies manifest shape, unique identities, exact filename/stem alignment, and equality between the 11 `runtime_required` stems and the current runtime catalog.
- The first autonomous audio batch is **audit only**: inventory existing binaries, compute SHA-256 hashes, classify duplicates, and create `docs/audio/AUDIO_INVENTORY.json`, `AUDIO_DEDUP_REPORT.md`, and `AUDIO_WORK_RECEIPT.md`.
- After audit, generate the 11 exact runtime stems first. All city music, ambience, mechanics, and boss material remain reserved until deterministic events or scene-state projection, catalog mappings, tests, and device evidence exist.
- Atlanta callback audio must reuse approved prior-city masters; do not regenerate imitations.
- Preserve shape-node and silent-audio fallbacks. Asset availability must remain independent of deterministic gameplay.

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

That runs privacy → assets → audio manifest → package tests → simulator unit/UI → launch smoke (see [`EMULATOR_AUTOMATION.md`](EMULATOR_AUTOMATION.md)). It does **not** replace physical-device acceptance.

## Current next engineering frontier

Autonomous / offline-capable (in priority order):

1. **Merge when green:** Tulsa [#33](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/33) and Oakland [#32](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/32).
2. **San Francisco** city foundation pack (same gated loop; inventory against all packs on `main` after merges).
3. Audio Batch 0 audit and receipts from [`AUDIO_AGENT_EXECUTION.md`](AUDIO_AGENT_EXECUTION.md); do not generate before deduplication is complete.
4. Audio Batch 1 generation and intake of the exact 11 runtime-required stems after owner review of selected ElevenLabs candidates.
5. Subsequent city foundation packs through Atlanta.
6. Reserved entity art: projectile / deployable families (optional).
7. Emulator suite remains the default gate while the iPhone is offline (`make emulator-test`).

Operator-required (cannot close autonomously):

1. Full physical-device acceptance per [`RELEASE_READINESS.md`](RELEASE_READINESS.md) — issues #2/#3 stay open until then.
2. Approval of ElevenLabs candidate selections and licenses before production binaries become canonical.
3. Device audio acceptance for speakers, headphones, Bluetooth, interruptions, silent-mode policy, ducking, and dense-combat clipping.
4. Final art review for reserved/optional sprites and full five-district atlases if desired.
5. App Store owner fields in [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md).

Campaign/content-graph hardening from the long sprint is on `main` (see [`LONG_SPRINT_REPORT.md`](LONG_SPRINT_REPORT.md)). Issue reconciliation: [`ISSUE_RECONCILIATION.md`](ISSUE_RECONCILIATION.md). Audit board: [`REPO_STATUS.md`](REPO_STATUS.md).

## Required local gate

```bash
make audio-check
make validate
```

`make validate` runs privacy, visual assets, audio manifest drift, the Swift package suite, XcodeGen generation, and the iOS Simulator test target. Generated `SurveillanceSurvivor.xcodeproj/` and `.codebase-memory/` remain local artifacts and must not be committed.
