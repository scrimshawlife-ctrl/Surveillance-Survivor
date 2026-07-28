# Emulator automation

Automated iOS Simulator coverage for Surveillance Survivor. This is **not** a substitute for physical-device acceptance in [`RELEASE_READINESS.md`](RELEASE_READINESS.md).

## Commands

| Target | What it does |
|---|---|
| `make simulator-test` | XcodeGen + unit tests + XCUITests on an iPhone Simulator |
| `make simulator-smoke` | Build, install, launch, settle, screenshot, process liveness |
| `make simulator-visual-stress` | Launch a deterministic max-density fixture and capture raw + normalized landscape screenshots |
| `make simulator-visual-matrix` | Run ordinary-combat and reduced-motion/reduced-flash fixtures in all ten cities; emit 20 screenshots, semantic receipt, and contact sheet |
| `make emulator-test` | Full suite: privacy → assets → package tests → simulator-test → simulator-smoke |
| `make validate` | CI-parity gate (package + simulator unit/UI tests; no launch smoke) |

Optional overrides:

```bash
SIMULATOR_UDID=<udid> make simulator-smoke
SIMULATOR_SMOKE_ARTIFACTS=/tmp/ss-smoke make simulator-smoke
SIMULATOR_SMOKE_SETTLE_SECONDS=5 make simulator-smoke
```

## Layers

1. **Package tests** (`make test`) — headless `SurveillanceCore` determinism on the host.
2. **Assets check** (`make assets-check`) — runtime PNG intake gates under `Resources/RuntimeSprites`.
3. **Simulator unit tests** — `GameScene` fixed-step smoke, pause/resume, upgrade draft, receipts, visual asset map contract (`VisualAssetMapTests`).
4. **Emulator extraction smoke** — force boss defeat → Blind Spot entry → run receipt → campaign unlock for Wichita and Louisville (`EmulatorExtractionSmokeTests`).
5. **Emulator visual asset smoke** — MVP textures load from the host bundle; player/LPR/Blind Spot project as mapped sprites (`EmulatorVisualAssetSmokeTests`).
6. **Emulator district catalog smoke** — all ten cities boot, project, and open authored Blind Spots; first-three campaign unlock chain (`EmulatorDistrictCatalogSmokeTests`).
7. **Emulator campaign UX** — unlock gating, picker resolution, audio cue mapping without asset bank (`EmulatorCampaignUXTests`).
8. **XCUITests** — 10 black-box journeys: launch, pause/resume, settings, reduced-motion persistence, upgrade selection, extraction, defeat, daily/weekly challenge launch, and dense-combat rendering.
9. **Launch smoke** — `simctl` install + launch + screenshot under `.simulator-smoke/`.
10. **Visual stress smoke** — deterministic 34-entity combat fixture with all guard/sensor families, all six projectile families, boss, mirror array, signal flood, scan cones, and status rings under `.simulator-visual-stress/`.
11. **All-city visual matrix** — captures ordinary and reduced-presentation fixtures for every `DistrictID`, validates unique catalog city identity plus district/scenario/accessibility receipts, screenshot dimensions and minimum size, and writes `.simulator-visual-matrix/matrix-receipt.json` with a labeled `contact-sheet.jpg`.

## Current baseline

| Layer | Passing count |
|---|---:|
| Swift package (`SurveillanceCore`) | 211 |
| Simulator-hosted Swift Testing suites | 318 |
| XCUITest black-box journeys | 10 |

Counts are a point-in-time QA baseline, not a substitute for behavior-level assertions or device acceptance.

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

The simulator job also uploads the 20-panel all-city matrix directory, generated contact sheet, and `visual-matrix.log`. Missing panels, duplicate/missing catalog identity, mismatched district/scenario/accessibility receipts, non-landscape images, undersized captures, or failed smoke make the job fail closed.

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
