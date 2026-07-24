# Emulator automation

Automated iOS Simulator coverage for Surveillance Survivor. This is **not** a substitute for physical-device acceptance in [`RELEASE_READINESS.md`](RELEASE_READINESS.md).

## Commands

| Target | What it does |
|---|---|
| `make simulator-test` | XcodeGen + unit tests + XCUITests on an iPhone Simulator |
| `make simulator-smoke` | Build, install, launch, settle, screenshot, process liveness |
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
6. **Emulator campaign UX** — unlock gating, picker resolution, audio cue mapping without asset bank (`EmulatorCampaignUXTests`).
7. **XCUITests** — launch, pause/resume chrome, accessibility settings sheet.
8. **Launch smoke** — `simctl` install + launch + screenshot under `.simulator-smoke/`.

## Artifacts

`make simulator-smoke` and `make emulator-test` write:

- `.simulator-smoke/simulator-smoke.log`
- `.simulator-smoke/launch.png`
- `.simulator-smoke/receipt.txt`

The directory is gitignored.

## CI

The `simulator` job on macOS:

1. Generates the Xcode project
2. Boots an available iPhone Simulator
3. Runs unit + UI tests
4. Runs launch smoke and uploads `.simulator-smoke` artifacts

## Scope boundaries

- Automated emulator tests prove boot, shell chrome, and deterministic scene stepping.
- They do **not** claim thermal, haptic, audio-route, or outdoor touch acceptance.
- Physical evidence still requires `DEVICE_UDID=… make device-smoke` plus the protocol in `RELEASE_READINESS.md`.
