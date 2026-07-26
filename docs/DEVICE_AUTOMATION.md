# Device automation

Automated **physical iPhone** coverage for Surveillance Survivor. This is **not** a substitute for operator ART / extract acceptance in [`RELEASE_READINESS.md`](RELEASE_READINESS.md) and [`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md).

Simulator counterpart: [`EMULATOR_AUTOMATION.md`](EMULATOR_AUTOMATION.md).

## Commands

| Target | What it does |
| --- | --- |
| `make device-smoke` | Signed build → install → launch → settle → process liveness → receipt |
| `make device-ui-test` | XCUITests (`LaunchUITests`) on the connected iPhone |
| `make device-test` | Full suite: lock check → generate → device-smoke → UI tests → `device-receipt.json` |
| `make device-accept` | Smoke + **DeviceAcceptanceUITests** (mechanical force-extract summary + copy receipt). **Not** ART ship. |

`DEVICE_UDID` is **optional**. When omitted, `scripts/select_connected_iphone.sh` picks the first paired connected physical iPhone (wired preferred).

```bash
# Auto-detect phone
DEVELOPMENT_TEAM=X9M969D8M3 make device-test

# Explicit UDID
DEVICE_UDID=00008150-000A6C120CB8401C DEVELOPMENT_TEAM=X9M969D8M3 make device-smoke
```

Optional overrides:

| Env | Default | Meaning |
| --- | --- | --- |
| `DEVICE_UDID` | auto | Hardware UDID for `xcodebuild` / `devicectl` |
| `DEVELOPMENT_TEAM` | `X9M969D8M3` in suite | Automatic signing team |
| `DEVICE_SUITE_ARTIFACTS` / `DEVICE_SMOKE_ARTIFACTS` | `.device-smoke/` | Artifact directory |
| `DEVICE_SMOKE_SETTLE_SECONDS` | `3` | Post-launch settle before process check |
| `DEVICE_SUITE_SKIP_UI` | `0` | `1` = smoke only (no XCUITest / no automation mode) |
| `DEVICE_SUITE_UI_SOFT` | `0` | `1` = UI fail → receipt `partial`, exit 0 |
| `DEVICE_SUITE_UI_RETRIES` | `2` | Retries when enabling UI automation times out |
| `DEVICE_ACCEPTANCE_ONLY` | `0` | `1` = only `DeviceAcceptanceUITests` (used by `make device-accept`) |
| `DERIVED_DATA_PATH` | `/private/tmp/surveillance-survivor-device-*-derived-data` | Signed build products |

### UI Automation trust (first run)

XCUITests need the phone to enter **automation mode**. If you see:

`Timed out while enabling automation mode`

then on the iPhone: unlock + stay awake, trust this Mac, Developer Mode ON, and accept any **Enable UI Automation** dialog. Retry `make device-ui-test` within 15s of the suite prompt, or use:

```bash
DEVICE_SUITE_SKIP_UI=1 make device-test          # deploy dual-launch only
DEVICE_SUITE_UI_SOFT=1 make device-test          # smoke required; UI optional
```

## Layers

1. **select_connected_iphone** — CoreDevice list → hardware UDID (not simulator).
2. **lock-check** — `devicectl device info lockState` (fail if never unlocked this boot).
3. **device-smoke** — signed Debug build, install, **dual** launch (cold + relaunch), settle, process still running each cycle.
4. **device-ui-tests** — chrome XCUITests (`pause` / `settings` / launch) and/or acceptance force-extract.
5. **device-accept** — launch arg `-UITestingForceExtract` completes a Blind Spot in-process, asserts `run-summary` + `copy-receipt-json`, screenshots. Mechanical only.
6. **device-receipt.json** — machine-readable evidence (**schemaVersion 1**, `kind: device-suite` or `device-smoke`).

### Honesty boundary

| Automated | Still human |
| --- | --- |
| Deploy liveness | ART combat readability eyes |
| Force-extract summary UI | Owner #3 ship yes/no |
| Chrome pause/settings (when green) | Thermal / real touch comfort |
| Tip SHA on smoke receipt | Pasting operator narrative into DEVICE_TEST_LOG for ART gate |

## Artifacts

Written under `.device-smoke/` (gitignored):

| File | Meaning |
| --- | --- |
| `device-suite.log` / `device-smoke.log` | Console log |
| `device-receipt.json` | Machine receipt |
| `receipt.txt` | Human smoke summary |
| `processes.json` | Post-launch process list snapshot |
| `lock-state.json` | Lock state at suite start |
| `DeviceUITests.xcresult` | XCTest result bundle (includes screenshots) |

### `device-receipt.json`

| Field | Meaning |
| --- | --- |
| `schemaVersion` | Currently `1` |
| `kind` | `device-smoke` or `device-suite` |
| `status` | `pass` / `fail` |
| `commit` | Short git SHA |
| `deviceUdid` | Hardware UDID |
| `steps` | Ordered `{name,status,exitCode,durationSeconds}` |
| `notes` | Always states automated ≠ full physical acceptance |

## What this proves

- App **builds and codesigns** for the connected device
- **Install + launch** succeed via CoreDevice
- Process stays up after settle (no immediate crash)
- **HUD chrome** reachable under `-UITesting` (pause / settings round-trip)

## What this does **not** prove

- Tip-matched **ART_DEVICE_QA_CHECKLIST** combat readability
- Full extract **COPY RECEIPT** gameplay acceptance
- Thermal, haptics, audio-route, outdoor touch
- `ART_SHIP_APPROVED` (still requires operator evidence paths)

## Prerequisites

1. Paired iPhone, **unlocked**, Developer Mode on  
2. Cable (or reliable wireless CoreDevice tunnel)  
3. Valid Apple Development identity + `DEVELOPMENT_TEAM`  
4. `xcodegen` installed  
5. Xcode with device support for the phone’s iOS version  

## Operator path after automation

1. Run `make device-test` and keep `.device-smoke/device-receipt.json`.  
2. Manually complete [`ART_DEVICE_QA_CHECKLIST.md`](ART_DEVICE_QA_CHECKLIST.md) + extract receipt in [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md).  
3. Only then may an agent set `device_evidence_paths` and flip `ship_gate` under `make art-qa-check` honesty rules.
