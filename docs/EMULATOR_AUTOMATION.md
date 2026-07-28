# Emulator automation

Automated iOS Simulator coverage for Surveillance Survivor. This is **not** a substitute for physical-device acceptance in [`RELEASE_READINESS.md`](RELEASE_READINESS.md).

## Commands

| Target | What it does |
|---|---|
| `make simulator-test` | XcodeGen + unit tests + XCUITests on an iPhone Simulator |
| `make simulator-smoke` | Build, install, launch, settle, screenshot, process liveness |
| `make simulator-visual-stress` | Launch a deterministic max-density fixture and capture raw + normalized landscape screenshots |
| `make simulator-visual-matrix` | Run ordinary-combat and reduced-motion/reduced-flash fixtures in all ten cities; emit 20 screenshots, semantic receipt, contact sheet, and non-golden triage/history summaries |
| `make emulator-test` | Full suite: privacy → assets → package tests → simulator-test → simulator-smoke |
| `make validate` | CI-parity gate (package + simulator unit/UI tests; no launch smoke) |
| `make qa-baseline-check` | Parse package, simulator-unit, and UI logs and require exact agreement with `qa/non-device-baseline.json` |
| `make qa-baseline-refresh` | Refresh increased/unchanged counts and the validated commit from those logs |

Optional overrides:

```bash
SIMULATOR_UDID=<udid> make simulator-smoke
SIMULATOR_SMOKE_ARTIFACTS=/tmp/ss-smoke make simulator-smoke
SIMULATOR_SMOKE_SETTLE_SECONDS=5 make simulator-smoke
SIMULATOR_VISUAL_MATRIX_SETTLE_SECONDS=2 make simulator-visual-matrix
SIMULATOR_VISUAL_MATRIX_WORKERS=2 make simulator-visual-matrix
```

## Layers

1. **Package tests** (`make test`) — headless `SurveillanceCore` determinism on the host.
2. **Assets check** (`make assets-check`) — runtime PNG intake gates under `Resources/RuntimeSprites`.
3. **Simulator unit tests** — `GameScene` fixed-step smoke, pause/resume, upgrade draft, receipts, visual asset map contract (`VisualAssetMapTests`).
4. **Emulator extraction smoke** — force boss defeat → Blind Spot entry → run receipt → campaign unlock for Wichita and Louisville (`EmulatorExtractionSmokeTests`).
5. **Emulator visual asset smoke** — MVP textures load from the host bundle; player/LPR/Blind Spot project as mapped sprites (`EmulatorVisualAssetSmokeTests`).
6. **Emulator district catalog smoke** — all ten cities boot, project, and open authored Blind Spots; first-three campaign unlock chain (`EmulatorDistrictCatalogSmokeTests`).
7. **Emulator campaign UX** — unlock gating, picker resolution, audio cue mapping without asset bank (`EmulatorCampaignUXTests`).
8. **XCUITests** — 11 black-box journeys: launch, pause/resume, settings, reduced-motion persistence, upgrade selection, extraction, defeat, daily/weekly challenge launch, dense-combat rendering, and mechanical force-extract receipt presentation.
9. **Launch smoke** — `simctl` install + launch + screenshot under `.simulator-smoke/`.
10. **Visual stress smoke** — deterministic 34-entity combat fixture with all guard/sensor families, all six projectile families, boss, mirror array, signal flood, scan cones, and status rings under `.simulator-visual-stress/`.
11. **All-city visual matrix** — builds once, installs once per worker, then captures ordinary and reduced-presentation fixtures for every `DistrictID`; validates unique catalog city identity plus district/scenario/accessibility receipts, screenshot dimensions and minimum size; and writes `.simulator-visual-matrix/matrix-receipt.json` with execution metadata and a labeled `contact-sheet.jpg`. The measured default is one worker with a one-second deterministic-fixture settle: 69.9 seconds locally versus the prior roughly 140-second matrix. Two-worker identical simulator replicas remain opt-in because CoreSimulator contention made them slower on the measured host; replicas are always bounded to four and deleted on exit.
12. **Visual triage** — downsamples each panel to stable luminance/RGB metrics and fingerprints, rejects only nearly blank/flat captures, compares paired variants, and emits `visual-triage.json`, `visual-triage.md`, and a compact `visual-history-entry.json`. These are diagnostics, not pixel-perfect release gates.
13. **Cross-run trend** — when `VISUAL_HISTORY_BASELINE` names a prior history entry, the analyzer emits `visual-trend.json` and `visual-trend.md` with aggregate deltas and advisory anomaly annotations. CI restores the latest branch-local history through `actions/cache`, then retains the current entry under a run-unique key. A cold cache is valid and reports `no-baseline`.
14. **Reviewer anomaly bundle** — schema-2 history retains per-city combat/reduced luminance and contrast metrics. Compatible baselines attribute material shifts to districts and emit `anomaly-review.json`, `.md`, and a standalone `.html` linking the exact current panels. Legacy aggregate baselines remain supported and point reviewers to the full contact sheet.
15. **Unified QA index** — `qa/non-device-baseline.json` is the point-in-time authority for the 251 package / 379 simulator / 11 UI baseline. Every matrix run validates it and emits `qa-index.json`, `.md`, and `.html`, linking the contact sheet, receipts, trend report, and anomaly review from one page. Commit mismatches or missing evidence fail closed.
16. **Automated count authority** — CI uploads the package, simulator-unit, and UI logs into a dependent `baseline-counts` job. `refresh_qa_baseline.py` extracts their final suite totals and rejects any registry mismatch. Increases use `make qa-baseline-refresh`; decreases additionally require `--approve-decrease "review reason"` and persist the previous/new counts plus reviewed commit.

## Current baseline

| Layer | Passing count |
|---|---:|
| Swift package (`SurveillanceCore`) | 211 |
| Simulator-hosted Swift Testing suites | 319 |
| XCUITest black-box journeys | 10 |

Counts are a point-in-time QA baseline, not a substitute for behavior-level assertions or device acceptance. CI derives them from completed test logs instead of duplicating the numbers in workflow code.

To refresh after adding tests:

```bash
make qa-baseline-refresh \
  QA_SWIFT_LOG=swift-test.log \
  QA_SIMULATOR_LOG=unit-xcodebuild.log \
  QA_UI_LOG=ui-xcodebuild.log
```

If a deliberate test consolidation reduces any count, call the script directly with `--write --approve-decrease "reason"`; an unreviewed decrease fails closed.

## Artifacts

`make simulator-smoke` and `make emulator-test` write under `.simulator-smoke/` (gitignored):

| File | Meaning |
|---|---|
| `emulator-suite.log` / `simulator-smoke.log` | Console log for the run |
| `launch.png` | Post-launch screenshot |
| `launch-landscape.png` | Review-ready landscape normalization of portrait-encoded `simctl` captures |
| `receipt.txt` | Human-readable smoke summary |
| `emulator-receipt.json` | Machine-readable evidence (**schemaVersion 1**) |

### `emulator-receipt.json`

| Field | Meaning |
|---|---|
| `schemaVersion` | Currently `1` |
| `status` | `pass` / `fail` |
| `commit` | Short git SHA |
| `swiftVersion` / `xcodeVersion` | Toolchain strings when available |
| `simulatorId` | Selected iPhone Simulator UDID |
| `startedAt` / `endedAt` | UTC timestamps |
| `steps` | Ordered `{name,status,exitCode,durationSeconds}` |
| `screenshot` | Relative filename when present |
| `landscapeScreenshot` | Relative normalized landscape screenshot when present |
| `notes` | Always states simulator ≠ physical acceptance |

On suite failure the receipt is still written with `status: fail` and the failing step recorded, then the process exits nonzero (fail-closed).

CI uploads the artifact directory with existing simulator logs.

The simulator job uploads the complete matrix directory, including `qa-index.html` as the one-click entry point. Missing panels, mismatched receipts, invalid baseline structure, missing linked evidence, non-landscape images, undersized/blank/flat captures, or failed smoke make the job fail closed. The dependent baseline-count job verifies the registry's exact counts from test logs. Fingerprint, paired-color, aggregate, and city-level differences remain reviewer diagnostics and do not fail CI.

## CI

The `simulator` job on macOS:

1. Generates the Xcode project
2. Boots an available iPhone Simulator
3. Runs unit + UI tests
4. Runs launch smoke and uploads `.simulator-smoke` artifacts

## `-UITesting` and auto-fire

XCUITests and chrome smokes launch with `-UITesting`. `GameScene` sets `PlayerInput.autoFireEnabled = false` in that mode so AFK kinetic fire cannot open upgrade drafts over pause/settings chrome.

| Constraint | Detail |
| --- | --- |
| Honored in | `Simulation.step` — weapons fire only when `autoFireEnabled` is true |
| Not a settings toggle | Players always run with auto-fire on; the flag exists for tests/hosts |
| Pitfall | If the gate is removed, LaunchUITests flake as upgrade overlays cover chrome |

Physical-device chrome tests use the same launch arg — see [`DEVICE_AUTOMATION.md`](DEVICE_AUTOMATION.md).

## Scope boundaries

- Automated emulator tests prove boot, shell chrome, and deterministic scene stepping.
- They do **not** claim thermal, haptic, audio-route, or outdoor touch acceptance.
- Dense simulator evidence proves fixture rendering and chrome reachability, not physical-device frame budget or perceptual ART acceptance.
- Physical automation: [`DEVICE_AUTOMATION.md`](DEVICE_AUTOMATION.md) (`make device-test`). Full ART/extract acceptance still requires the protocol in `RELEASE_READINESS.md`.
