# Continuation plan

**Product sequencing:** [`ROADMAP.md`](ROADMAP.md)  
**Live board:** [`REPO_STATUS.md`](REPO_STATUS.md)  
**Device evidence:** [`RELEASE_READINESS.md`](RELEASE_READINESS.md)  
**ART inventory:** [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md)

## Current vertical-slice state

Implemented on `main`:

- Fixed-step, seeded simulation with structured run receipts  
- The Ghost, Suspicion tiers, Contract Security, automated surveillance, Shift Manager, Blind Spot extraction  
- Six MVP countermeasures, twelve base upgrades, four evolutions  
- Catalog-backed integrity, guard/boss contact, non-extract defeat  
- Sensor disable/disrupt freeze  
- SpriteKit projection, stick input, accessibility, haptics, summary persistence, pause/resume  
- `VisualAssetMap` + runtime player/LPR/Blind Spot/tiers/guard/boss  
- Global environment package v1 + **all ten city foundation packs** (13 each; 160 PNGs)  
- Audio event-map + ElevenLabs manifest/queue/`make audio-check` (binaries still missing)  
- **Audio Batch 0** complete: inventory / dedup / receipts under [`audio/`](audio/) (0 binaries; dirs scaffolded)  
- Campaign unlocks + emulator extraction/campaign smokes  
- CI core-tests + simulator  

**Not release-ready** until device acceptance, ART device QA/owner decisions, store owner fields, and (for full product audio) approved stems exist.

## Authority boundaries

```text
SurveillanceCore  → deterministic state, content, combat, receipts
SpriteKit         → projects snapshots; no gameplay truth
SwiftUI           → lifecycle, HUD, a11y, overlays, receipt persistence
```

## Engineering priorities (aligned with roadmap)

### 1. Physical-device acceptance (P2 · issue #2)

Follow [`RELEASE_READINESS.md`](RELEASE_READINESS.md) + [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md).  
`make device-smoke` is deploy-only, not acceptance.

### 2. ART sign-off (P3 · issue #3)

Inventory is largely complete — see [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md).  
Remaining: device readability pass; projectile/deployable shape-first decision; owner ship note.

### 3. Product audio (P4)

1. ~~Batch 0: inventory/dedup/receipts~~ **Done** — [`audio/AUDIO_WORK_RECEIPT.md`](audio/AUDIO_WORK_RECEIPT.md)  
2. Owner license review of ElevenLabs candidates  
3. Batch 1: exact 11 `runtime_required` stems  
4. Integrate playback; keep silent fallback until masters approved  

Never ship system-sound placeholders as product audio.  
`make audio-check` before/after audio work.

### 4. Store listing (P5)

Owner completes [`APP_STORE_METADATA.md`](APP_STORE_METADATA.md): live privacy/support URLs, SKU, copyright, age rating, screenshots from release build, ASC privacy answers.

### 5. Optional polish (P7)

Five-district atlases, Atlanta boss-phase env overlays, reserved entity art, city music/ambience packages.

## Emulator-first while device offline

```bash
make emulator-test
# or CI-parity:
make validate
```

Does **not** replace physical-device acceptance.

## Current next frontier

**Autonomous / offline**

1. Keep docs boards accurate (this file, REPO_STATUS, ROADMAP).  
2. Audio Batch 1 only after owner ElevenLabs license OK (see Batch 0 receipt).  
3. Optional reserved projectile/deployable art only after owner decision.  

**Operator-required**

1. Device acceptance (#2).  
2. ART device QA + ship decision (#3).  
3. Privacy/support URLs + store fields.  
4. ElevenLabs license approval before Batch 1 generation.  

## Required local gate

```bash
make audio-check
make validate
```

Do not commit generated `SurveillanceSurvivor.xcodeproj/` or `.codebase-memory/`.
