# Mechanics repair receipt — tip `fcc0537` (refreshed @ `0796da4`)

## Identity

| Field | Value |
| --- | --- |
| Baseline tip | `2c63280` |
| Fix commits | `146001c` (#105), **`fcc0537`** (#107) |
| Docs package | `f8ef146` (#106) + tip refresh @ `0796da4` |
| Post-fix lineage | #109–#116 systems repairs (not reopening M-01–M-04) |
| Architecture | SurveillanceCore authoritative; SpriteKit/SwiftUI projection only |
| Schema / `versions.json` | See open #117 for registry split (orthogonal to M-01–M-04) |

## Executive assessment

Mechanical core is **simulator-production-coherent** after M-01–M-04 (with M-02 hardened on #107 for pre-move origins + earliest-t). Prior #101–#103 closed death-tick halt, landmark suspicion floor, fire-cap continue, and post-death boss guard.

**Ship blockers remaining:** operator device ART + extract receipt; owner store URLs/screenshots; owner ElevenLabs audio — **not** missing sim combat systems.

**Production-readiness:** Simulator-ready vertical slice · **not** App Store / TestFlight ready.

## Fixed findings

| ID | Sev | Summary | Tip |
| --- | --- | --- | --- |
| M-01 | P1 | `addsWeapon` unlock applies `UpgradeEffect` on first pick | `146001c` |
| M-02 | P1 | Swept hits: true pre-move origin, no reverse phantom, min-t target | `fcc0537` |
| M-03 | P2 | Signal flood FX marker tracks payload duration (capped 180) | `146001c` |
| M-04 | P2 | Guard spawn pushes out of player clearance (no extra RNG) | `146001c` |

## Deferred (explicit IDs)

| ID | Sev | Summary | Why not fixed now |
| --- | --- | --- | --- |
| M-D01 | P2 | Multi-shot / pierce / homing | DOCUMENTED_ONLY — no `upgrades.json` rows; scope expansion |
| M-D02 | P2 | Named pairwise synergies vs tags | PARTIAL by design — tag engine is canonical post-P8 |
| M-D03 | P1 | Physical ART + extract receipt | Operator device evidence only |
| M-D04 | P1 | Store privacy/support URLs + screenshots | Owner |
| M-D05 | P1 | ElevenLabs → Audio Batch 1 | Owner |

### Remaining CONFIRMED P0/P1 inventory (code)

**None open.** Package suite covers determinism, extraction exclusivity, death-tick shutdown, multi-kill upgrade queue, ten-city forced extract, six weapons, build synergies. No additional CONFIRMED agent-fixable P0/P1 identified outside M-01/M-02 after #107.

## Changed files (code)

### #105 (`146001c`)
* `Sources/SurveillanceCore/Simulation.swift` — M-01, initial M-02, M-03, M-04
* `Tests/SurveillanceCoreTests/SimulationTests.swift`
* `docs/MECHANICS_AUDIT_REPORT.md`

### #107 (`fcc0537`)
* `Sources/SurveillanceCore/Simulation.swift` — `projectileOriginsThisStep`, `firstIntersectionT`, min-t selection
* `Tests/SurveillanceCoreTests/SimulationTests.swift` — phantom / nearer / M-03 / M-04 tests
* findings + audit report updates

### Docs package
* `docs/MECHANICS_FINDINGS.json`
* `docs/MECHANICS_BALANCE_MATRIX.md` (this tip)
* `docs/MECHANICS_REPAIR_RECEIPT.md` (this tip)

## Gates at `fcc0537` lineage

| Command | Result | Evidence |
| --- | --- | --- |
| `make test` | **180** pass | package suite |
| `make weapon-vfx-check` | PASS | 20 assets / 6 weapons |
| `make audio-check` | PASS | catalog dry-run |
| `make art-qa-check` | PASS · `ART_EVIDENCE_INSUFFICIENT` | honesty gate |
| `make build` | PASS | xcodebuild iphonesimulator |
| `make simulator-test` | PASS | unit + LaunchUITests |
| `make simulator-smoke` | PASS | install/launch/screenshot |
| `make emulator-test` | PASS | full emulator suite |
| `make validate` | PASS | CI-parity local |
| CI #105 / #107 | green | core-tests + simulator |

Key assertions (real `Simulation.step` path):

* `selectingRedactionOrdinanceAddsItToTheBoundedLoadout` — M-01 cadence
* `highSpeedProjectileCannotTunnelThroughCameraPole` — mid-flight tunnel
* `sameTickFiredProjectileDoesNotInventReversePhantomHit` — M-02 phantom
* `sweptProjectileHitsNearestTargetAlongPathNotArrayOrder` — M-02 min-t
* `signalFloodMarkerExpiresWithPayloadDurationNotHardcoded18` — M-03
* `guardSpawnMaintainsPlayerClearance` — M-04 (player on spawn ring; **spawn-tick only**; requires a near-ring spawn so push path is forced)

### Tip-matched simulator re-run (post-#107/#108)

| Command | Receipt commit | Result |
| --- | --- | --- |
| `make simulator-smoke` | `c42f1d9` | PASS |
| `make emulator-test` | `c42f1d9` | PASS |
| `make validate` | `c42f1d9` lineage | PASS |

Logs: implementer scratch `gate-smoke-emulator-tip-matched.log`, `emulator-receipt-tip-matched.json`, `gate-validate-tip-matched.log`.

## Device evidence

| Item | Status |
| --- | --- |
| Dual-launch deploy smoke (historical tips) | Pass — `DEVICE_TEST_LOG` |
| Tip-matched full acceptance on `0796da4`+ | **Open** — operator |
| `ART_DEVICE_QA_CHECKLIST` | **Open** |
| Extract COPY RECEIPT | **Open** |
| `ship_gate` | **ART_EVIDENCE_INSUFFICIENT** |

## Tuning / schema

* No hidden damage/HP scaling.
* No `versions.json` / save schema changes.
* See balance matrix for before/after of M-01–M-04 only.

## Unresolved risks

1. Operator must accept ART + extract on tip ≥ `0796da4`.
2. Design still lists multi-shot/pierce/homing without content (`M-D01`).
3. Device thermal / max-density not re-profiled on physical iPhone this pass.

## Handoff

| Item | Value |
| --- | --- |
| Branch / commit | Fix tip **`fcc0537`**; main refresh **`0796da4`** |
| Fixed | M-01, M-02, M-03, M-04 |
| Deferred | M-D01…M-D05 |
| Authority matrix | `docs/MECHANICS_AUDIT_REPORT.md` |
| Findings | `docs/MECHANICS_FINDINGS.json` |
| Balance | `docs/MECHANICS_BALANCE_MATRIX.md` |
| Committed / PR | Code #105 + #107 merged; this receipt/matrix tip update in follow-up docs PR |
