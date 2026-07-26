# Mechanics repair receipt — 2026-07-26

## Identity

| Field | Value |
| --- | --- |
| Baseline tip | `2c63280` |
| Fix commit (squash) | `146001c` — PR [#105](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/105) |
| Architecture | SurveillanceCore authoritative; SpriteKit/SwiftUI projection only |
| Schema changes | **None** (no save/version bumps) |

## Executive assessment

Mechanical core is **production-coherent for simulator/package validation** after M-01–M-04. Prior #101–#103 already closed death-tick, landmark floor, fire-cap, and boss-guard issues. Remaining ship blockers are **device ART**, **store OWNER fields**, and **audio binaries** — not missing combat systems.

**Production-readiness estimate:** Simulator-ready vertical slice; **not** App Store / TestFlight ready until operator + owner gates clear.

## Fixed this pass

| ID | Severity | Summary |
| --- | --- | --- |
| M-01 | P1 | Unlock upgrades apply effects on first acquisition |
| M-02 | P1 | Swept projectile collision (anti-tunnel) |
| M-03 | P2 | Signal flood FX marker duration |
| M-04 | P2 | Guard spawn player clearance |

## Deferred

| ID | Severity | Summary | Owner |
| --- | --- | --- | --- |
| M-D01 | P2 | Multi-shot / pierce / homing | Content design PR |
| M-D02 | P2 | Named pairwise synergies vs tags | Docs / future content |
| M-D03 | P1 | Physical ART + extract receipt | Operator |
| — | P1 | Store URLs / screenshots | Owner |
| — | P1 | ElevenLabs audio Batch 1 | Owner |

## Changed files (PR #105)

* `Sources/SurveillanceCore/Simulation.swift`
* `Tests/SurveillanceCoreTests/SimulationTests.swift`
* `docs/MECHANICS_AUDIT_REPORT.md`
* `docs/REPO_STATUS.md` (suggested next)

Follow-up docs (this receipt package):

* `docs/MECHANICS_FINDINGS.json`
* `docs/MECHANICS_BALANCE_MATRIX.md`
* `docs/MECHANICS_REPAIR_RECEIPT.md`

## Tests run

| Command | Result |
| --- | --- |
| `make test` | **176** pass |
| `make weapon-vfx-check` | PASS |
| `make audio-check` | PASS |
| `make art-qa-check` | PASS · `ART_EVIDENCE_INSUFFICIENT` |
| CI PR #105 | core-tests + simulator green |

Key new assertions:

* `selectingRedactionOrdinanceAddsItToTheBoundedLoadout` — cadence after unlock
* `highSpeedProjectileCannotTunnelThroughCameraPole` — real `Simulation.step` path

## Simulator evidence

* Package district matrix + forced extraction suites remain green (all ten cities).
* Deterministic seed replay tests still pass after clearance push (no extra RNG draws).

## Device evidence

| Item | Status |
| --- | --- |
| Dual-launch deploy smoke (prior tips) | Pass (historical `DEVICE_TEST_LOG`) |
| Tip-matched full acceptance on `146001c` | **Open** — operator |
| ART_DEVICE_QA_CHECKLIST | **Open** |
| Extract COPY RECEIPT | **Open** |

## Tuning / schema

* No hidden damage/HP scaling introduced.
* No `versions.json` / save schema changes.

## Unresolved risks

1. Operator must re-smoke + accept on tip ≥ `146001c`.
2. Design still documents multi-shot/pierce/homing without content — risk of player expectation mismatch if marketing quotes design doc.
3. Density stress beyond unit caps not re-profiled on device thermal.

## Handoff

* **Committed & merged:** yes (PR #105 → `146001c`)
* **Authority matrix:** `docs/MECHANICS_AUDIT_REPORT.md`
* **Machine findings:** `docs/MECHANICS_FINDINGS.json`
* **Balance snapshot:** `docs/MECHANICS_BALANCE_MATRIX.md`
