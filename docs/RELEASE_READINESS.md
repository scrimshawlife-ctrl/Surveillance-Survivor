# Release Readiness Evidence

## Authority and status

This checklist implements the [Notion verification strategy](https://app.notion.com/p/3a53e8ba2f5c813a942eeb17058f9ffd). It distinguishes reproducible repository evidence from observations that only a physical iPhone can establish.

Current status: **simulator-ready, physical-device evidence pending**. Do not represent the project as release-ready until every physical-device item has an attached, dated receipt.

## Reproducible local gate

Run from the repository root:

```bash
make validate
```

This gate performs the deterministic Swift package suite, generates the Xcode project, and runs the complete iOS Simulator test target. A passing gate proves the current code compiles and its core, receipt, settings, input, and completion-flow checks pass on the simulator. It does not prove physical-device performance or interaction quality.

## Evidence matrix

| Requirement | Repository evidence | Status |
|---|---|---|
| Fixed-step deterministic simulation and ordered receipts | `swift test`; deterministic receipt tests | Verified in CI/local gate |
| Suspicion, escalation, LPR destruction, upgrades, boss, and extraction | `Tests/SurveillanceCoreTests/SimulationTests.swift` | Verified in CI/local gate |
| Player contact damage, sensor disable freeze, and non-extract defeat path | Contact/disable/defeat tests in `SimulationTests.swift` | Verified in package/simulator gates; physical readability pending |
| Settings, touch input, completed-run receipt persistence, and diagnostics | `Tests/SurveillanceSurvivorTests/` | Verified in iOS Simulator gate |
| Signed Debug build, installation, and foreground launch | `DEVICE_UDID=<connected-iPhone-UDID> make device-smoke` | Verified on connected iPhone, 2026-07-22; deployment proof only |
| Frame-time p50/p95/max capture | `Game/Diagnostics/FrameTimeDiagnostics.swift` | Instrumented; physical values pending |
| One full accepted iPhone run | Device run receipt plus recording | Pending |
| 60 fps / 16.67 ms frame budget at maximum MVP density | Device receipt p50/p95/max plus Xcode Instruments trace | Pending |
| Thermal behavior, touch reachability, haptic clarity | Dated device test notes plus recording | Pending |
| Audio interruption and route-change recovery | Dated device test notes | Pending |
| Background/reopen without duplicated entities | Device receipt before/after interruption | Pending |
| Privacy manifest | `make privacy-check`, `App/PrivacyInfo.xcprivacy`, and bundled build | Implemented; re-review on SDK/data changes |
| App Store metadata scaffold | `docs/APP_STORE_METADATA.md` | Implemented; owner-provided legal/review fields pending |

## Physical-device protocol

Use a landscape iPhone running a signed development build. Record the device model, iOS version, app commit SHA, run seed, and test date with each receipt.

Use `DEVICE_UDID=<connected-iPhone-UDID> make device-smoke` before the protocol to reproduce the signed build, installation, and foreground launch. It deliberately stops short of claiming any acceptance item below.

1. Launch a fresh run and confirm movement, automatic fire, LPR scan contact, and tier escalation.
2. Destroy an LPR pole, select one of three offers, and confirm the resulting choice appears in the completed `DeviceRunReceipt`.
3. Defeat Shift Manager, enter the single Blind Spot, and confirm summary persistence after relaunch.
4. Repeat while backgrounding for at least 10 seconds; verify that resume does not duplicate simulation ticks, entities, upgrades, or effects.
5. Exercise the maximum supported projectile/deployable loadout. Capture the bounded p50, p95, and maximum frame timings; compare p95 to the 16.67 ms budget.
6. Confirm handedness, control scaling/opacity, reduced camera motion, and haptic toggle are reachable and legible.
7. Record audio interruption/route-change and haptic observations separately. Do not claim pass until observed.

The completion overlay displays p50, p95, and maximum frame time; use **COPY RECEIPT JSON** to retain the full bounded sample window with the acceptance record.

## Release receipt template

For a copyable, per-run evidence record, start from [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md). Keep the deterministic receipt JSON unchanged after exporting it from the completion overlay.

```text
date:
device model:
iOS version:
commit SHA:
build configuration:
seed:
run result: extracted / failed
run receipt location:
frame p50 / p95 / max (ms):
background-resume result:
touch/accessibility result:
thermal observation:
audio interruption / route-change result:
haptic observation:
reviewer:
```

## Known non-release blockers

- Physical-device acceptance run has not been captured in this repository.
- Owner-provided privacy/support URLs, age rating, rights information, screenshots, and App Store Connect privacy questionnaire remain incomplete.
- Simulator evidence does not substitute for thermal, touch, haptic, audio-route, or real frame-pacing validation.
