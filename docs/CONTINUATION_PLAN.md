# Continuation plan

**Product sequencing:** [`ROADMAP.md`](ROADMAP.md) (P0–P11)  
**Live board:** [`REPO_STATUS.md`](REPO_STATUS.md)  
**Systemic design:** [`ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md`](ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md)  
**Device evidence:** [`RELEASE_READINESS.md`](RELEASE_READINESS.md)  
**ART inventory:** [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md)  
**Versioning:** [`VERSIONING.md`](VERSIONING.md) · `versions.json`

## Current vertical-slice state

Implemented on `main` (tip through #82):

- Fixed-step, seeded simulation with structured run receipts  
- The Ghost, Suspicion tiers, Contract Security, automated surveillance, Shift Manager, Blind Spot extraction  
- Six MVP countermeasures, twelve base upgrades, four evolutions  
- Catalog-backed integrity, guard/boss contact, non-extract defeat  
- Sensor disable/disrupt freeze  
- SpriteKit projection, stick input, accessibility, haptics, summary persistence, pause/resume  
- `VisualAssetMap` + player / LPR / Blind Spot / tiers / guard / boss  
- Global environment package v1 + **all ten city foundation packs**  
- **RuntimeSprites** — cities + P0 combat stills + player multi-frame (`make assets-check`)  
- Combat readability hierarchy / density on existing projectors (#81/#82)  
- Audio event-map + ElevenLabs queue / `make audio-check` (**binaries still missing**)  
- Weapon/VFX Batch 0–2: P0 `projectile_default` + deployables **runtime_integrated**  
- Animation Batch 0–2: presentation pipeline + player idle/walk multi-frame  
- Campaign unlocks + emulator extraction/campaign/visual smokes  
- CI: core-tests + simulator + audio/weapon-vfx/animation/version gates  
- App version registry: **0.1.0** build **1** (pre-alpha)  
- **P8 Suspicion Director slice A** — `director_rules.json`, pure evaluator, spawn levers, receipt `directorDecisions`, `make director-check`  
- **P8 Dynamic City State slice A** — Wichita infrastructure graph, propagation, sensor-destroy hooks, receipt `cityStateEvents`, `make city-state-check`  
- **P8 Emergent Build Engine slice A** — upgrade tags, 5 synergies, explicit non-stat behaviors, `make build-engine-check`  
- **P8 Coordination Graph slice A** — lot capture cascade, interruptible links, `make coordination-check`  
- **P8 Run Story Compiler slice A** — receipt-grounded facts + summary, `make story-check`  
- Hallmark HUD token pass (#57)  
- **P9 interactables slice A** — 6 Wichita environmental interactables + utility activate  
- Continuation paste: [`CONTINUATION_PROMPT.md`](CONTINUATION_PROMPT.md)

**Not release-ready** until device acceptance evidence, ART device QA + owner ship note (#3), store owner fields, and (for full product audio) approved stems exist.

## Authority boundaries

```text
SurveillanceCore  → deterministic state, content, combat, receipts
SpriteKit         → projects snapshots + presentation motion; no gameplay truth
SwiftUI           → lifecycle, HUD, a11y, overlays, receipt persistence
versions.json     → app/build + compatibility integers (must match project.yml)
```

## Dual engineering lanes

### Launch lane (TestFlight / Review)

1. Physical-device acceptance protocol → DEVICE_TEST_LOG for tip SHA  
2. ART #3 device QA + ship note (checklist in ART_PRODUCTION_READINESS)  
3. Store: privacy/support URLs, SKU, copyright, age rating, screenshots  
4. Audio Batch 1 after owner ElevenLabs license (never system-sound placeholders)

### Systemic lane (post-slice identity — not a TF blocker)

Authority: ROADMAP **P8–P11** + roguelike assimilation doc.

1. ~~P8 contract stack A~~ complete · **P9** Big-Box proof in progress (interactables A)  
2. **P9** one-district systems proof (Big-Box Parking Expanse)  
3. **P10** ten-city rule projection  
4. **P11** replayability / mastery (no pure permanent damage inflation)

## Engineering priorities (detail)

### 1. Physical-device acceptance (P2)

Follow [`RELEASE_READINESS.md`](RELEASE_READINESS.md) + [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md).  
`make device-smoke` is deploy-only, not acceptance.  
GitHub #2 is closed; **evidence matrix may still be open**.

### 2. ART sign-off (P3 · issue #3)

Repo inventory is complete for expanded production set — see [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md).  
**Remaining:** device readability pass; owner ship note.  
Projectile/deployable decision: **attached** (#47/#49); shape fallbacks remain if texture missing.

### 3. Product audio (P4)

1. ~~Batch 0~~ **Done** — [`audio/AUDIO_WORK_RECEIPT.md`](audio/AUDIO_WORK_RECEIPT.md)  
2. Owner license review of ElevenLabs candidates  
3. Batch 1: exact 11 `runtime_required` stems  
4. Wire playback; silent fallback until masters approved  

`make audio-check` before/after audio work.

### 4. Store listing (P5)

Owner completes [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md).

### 5. Presentation polish (P7 · optional)

Five-district atlases, Atlanta boss env overlays, deployable 3-state strips, enemy multi-frame, city ambience packages.

### 6. Systemic architecture (P8 · partial)

P8 contract slices A are live: Director · City State · Build Engine · Coordination · Run Story  
([`P8_SUSPICION_DIRECTOR_CONTRACT.md`](P8_SUSPICION_DIRECTOR_CONTRACT.md), [`P8_CITY_STATE_CONTRACT.md`](P8_CITY_STATE_CONTRACT.md), [`P8_BUILD_ENGINE_CONTRACT.md`](P8_BUILD_ENGINE_CONTRACT.md), [`P8_COORDINATION_GRAPH_CONTRACT.md`](P8_COORDINATION_GRAPH_CONTRACT.md), [`P8_RUN_STORY_CONTRACT.md`](P8_RUN_STORY_CONTRACT.md)).

Do not invent gameplay scope that conflicts with assimilation rules:

- deterministic seed reproducibility;  
- no hidden damage/health scaling;  
- readable systemic consequences;  
- receipts never invent narrative events.

Systemic track: P8–P11 largely on main. Prefer launch-lane operator work next; agent polish only when boards or emulator coverage lag.

## Emulator-first while device offline

```bash
make version-check
make audio-check
make weapon-vfx-check
make animation-check
make director-check
make city-state-check
make build-engine-check
make coordination-check
make story-check
make interactables-check
make landmark-check
make clearing-builds-check
make city-rules-check
make challenge-contracts-check
make unlockables-check
make emulator-test
# CI-parity:
make validate
```

Does **not** replace physical-device acceptance.

## Current next frontier

**Autonomous / offline**

1. Keep boards accurate; refresh [`CONTINUATION_PROMPT.md`](CONTINUATION_PROMPT.md) tip SHA after merges.  
2. Emulator coverage for new UX (challenges, mastery) when app code changes.  
3. Optional P7 art only with inventory-first REUSE (multi-frame guards, RF overlays).  
4. Audio Batch 1 only after owner ElevenLabs license.  

**Operator-required**

1. Device ART QA + ship note → close #3.  
2. Device acceptance evidence for tip SHA (`DEVICE_TEST_LOG.md`).  
3. Privacy/support URLs + store fields.  
4. ElevenLabs license before audio generation.  
5. TestFlight internal once device + store gates clear.  

## Required local gate

```bash
make version-check
make audio-check
make weapon-vfx-check
make animation-check
make director-check
make city-state-check
make build-engine-check
make coordination-check
make story-check
make interactables-check
make landmark-check
make clearing-builds-check
make validate
```

Do not commit generated `SurveillanceSurvivor.xcodeproj/` or `.codebase-memory/`.
