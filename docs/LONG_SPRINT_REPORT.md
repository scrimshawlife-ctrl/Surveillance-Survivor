# Long sprint report — campaign integrity, lifecycle hardening, emulator evidence

## Identity

| Field | Value |
|---|---|
| Branch | `agent/long-sprint-campaign-hardening` |
| Starting SHA | `9fdcadb745bc8122c40308b349d261705efed19d` |
| Ending SHA | `1391ed75ce686c5e52e6ec7ac6100d5b20572480` |
| Started | 2026-07-24T15:30:21Z |
| Report time | 2026-07-24T15:47:05Z |

## Work packages

| WP | Status | Commit |
|---|---|---|
| A Docs reconciliation | **Completed** | `docs: reconcile implementation status and remaining frontiers` |
| B Content graph integrity | **Completed** | `test(content): enforce referential integrity across gameplay catalogs` |
| C Campaign persistence | **Completed** | `fix(campaign): harden unlock persistence and migration behavior` |
| D Ten-district matrix | **Completed** | `test(core): add deterministic ten-district campaign matrix` |
| E Adapter isolation | **Completed** | (bundled with platform commit) |
| F Interruption / projection | **Completed** | (bundled with platform commit) |
| G Emulator receipts | **Completed** | (bundled with platform commit) |
| H Bounded fixes | **Completed** (only evidenced) | pooled node reset + public `Simulation(state:)` |
| I Final delivery | **Completed** | this report + draft PR |

## Behavioral changes

1. **Campaign store** writes versioned `CampaignProgressRecord`; legacy bare JSON migrates; future schema fails closed to initial unlocks with diagnostics.
2. **ContentGraphValidator** checks district order, final trilogy, guard ceilings, archetype refs, upgrades/evolutions, audio cues.
3. **HapticFeedback** records resolved kinds and play counts for tests; disabled mode suppresses platform output only.
4. **EntityProjector.prepareForReuse** clears userData, color blend, and shape presentation residue.
5. **Simulation(state:rngSeed:)** is public for host-driven smokes/tests.
6. **Emulator suite** writes `emulator-receipt.json` (schema 1) on pass or fail; smoke path also emits JSON receipt.

## Test additions

- `ContentGraphIntegrityTests` (package)
- `DistrictCampaignMatrixTests` (package)
- `EmulatorReceiptSchemaTests` (package)
- `CampaignPersistenceHardeningTests` (app)
- `AdapterIsolationTests` (app)
- `InterruptionLifecycleTests` (app)

## Final verification (local)

| Command | Result |
|---|---|
| `make privacy-check` | pass (baseline) |
| `make assets-check` | pass (18 PNGs on main tip at start) |
| `swift test` | **88** tests pass |
| `make validate` | pass (baseline + post-change simulator-test pass) |
| `make simulator-test` | pass after platform tests |
| `make emulator-test` | pass at baseline; post-change suite should be re-run by CI |

Simulator used in baseline: `CACB3927-A76E-43A5-9ACA-C389EB38C0C3` (iPhone 17 Pro).

Artifacts: `.simulator-smoke/` (gitignored), including `launch.png`, logs, and `emulator-receipt.json` when suite/smoke run.

## Documentation and issues

- README: campaign unlocks no longer "Not started"; bootstrap uses `main`; frontier section added.
- `ISSUE_RECONCILIATION.md` + comments on GitHub issues #2 and #3 (keep open; device/art remaining).
- `CAMPAIGN_PERSISTENCE.md` storage contract.
- `EMULATOR_AUTOMATION.md` receipt schema.
- ONE_SHOT / CONTINUATION / RELEASE_READINESS aligned without deleting historical intent.

## Defects fixed

| Defect | Cause | Fix | Evidence |
|---|---|---|---|
| Stale README claim campaign unlocks "Not started" | Docs lag | Reconcile status table | WP-A |
| Future/corrupt campaign JSON could decode unsafely | Bare progress decode | Versioned envelope + fail-closed | CampaignPersistenceHardeningTests |
| Pooled nodes could retain tint/userData | Incomplete reset | prepareForReuse expansion | Interruption + visual smokes |
| Emulator runs lacked machine-readable evidence | Logs only | emulator-receipt.json | EmulatorReceiptSchemaTests |

## Deferred (operator / assets)

- Full physical-iPhone acceptance (thermal, 60fps, haptics feel, audio route, touch)
- Production audio binaries (map only; no system sounds)
- Guard/boss art PR #25 merge/review if still open; projectile/deployable art
- App Store owner fields (URLs, SKU, rights, screenshots, age rating)
- Legal likeness approvals

## Recommended next three engineering actions

1. Operator: physical-device acceptance protocol with dated `DEVICE_TEST_LOG` entry on current main/PR tip.
2. Merge or rebase open art PR #25 (guard/boss) if still separate; re-run assets-check.
3. Enable product audio only after approved CAF/AAC bank + `setAvailableAssets`.

## Architecture invariants preserved

SurveillanceCore authority, fixed timestep, no I/O in fixed-step, SpriteKit/SwiftUI projection-only, shape fallbacks, no placeholder product audio, collision independent of art.
