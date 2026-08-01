# Physical-Device Test Log

Use one copy of this template per signed-development-build acceptance run. Do not replace a pending item with simulator evidence. Paste the output from **COPY RECEIPT JSON** after extraction.

Before installing, pin the candidate and preserve the output with the run:

```bash
git rev-parse HEAD
git status --short
make version-check privacy-check release-docs-check launch-gate-check art-qa-check
```

The recorded SHA must equal the installed build's SHA. A dirty checkout must be explained or rejected as release evidence.

## Run identity

```text
date and local time:
reviewer:
device model:
iOS version:
app version / build:
commit SHA:
build configuration:
seed:
git status --short output (expected empty):
screen recording location:
Xcode Instruments trace location:
```

## Acceptance observations

```text
run result: extracted / failed
automatic fire and LPR contact observed: pass / fail
three-choice upgrade selection observed: pass / fail
Shift Manager and Blind Spot extraction observed: pass / fail
backgrounded at least 10 seconds, then resumed: pass / fail
duplicate ticks, entities, upgrades, or effects after resume: none / describe
maximum supported projectile/deployable loadout exercised: pass / fail
frame p50 / p95 / maximum (ms):
p95 at or below 16.67 ms: pass / fail
thermal observation:
handedness, scale, opacity, reduced-motion/flash controls: pass / fail
VoiceOver labels and focus order for HUD, pause, settings, upgrade draft, and run summary: pass / fail
haptic observation:
known issues or follow-up:
```

## Audio device acceptance

Repository validation proves files, hashes, and runtime addressing. It does not prove the physical mix.

```text
speaker / headphones balance: pass / fail
mute, effects, music, and city ambience controls: pass / fail
silent mode behavior matches product decision: pass / fail
background interruption and recovery without duplicate loops: pass / fail
audio interruption (call/Siri/alarm) recovery: pass / fail
route change (speaker ↔ headphones/Bluetooth) recovery: pass / fail
dense-combat clipping, pumping, or masked critical cues: none / describe
city ambience and music transition without stacked stale loops: pass / fail
Atlanta boss movements advance monotonically through the fight: pass / fail / not exercised
```

## P11 challenge / mastery (optional but preferred)

```text
daily challenge started from run summary: pass / fail / not exercised
weekly challenge started from run summary: pass / fail / not exercised
challenge objective text visible mid-run: pass / fail / n/a
mastery line updates after run (extractions / streak / unlocks): pass / fail / n/a
presentation unlock (trail / vignette / radio label) if earned: pass / fail / n/a / not earned
city floor readable (not wallpaper clutter): pass / fail
```

## Combat readability (preferred on tip de0f632+)

Repo Art QA: [`ART_QA_COMBAT_READABILITY_AUDIT.md`](ART_QA_COMBAT_READABILITY_AUDIT.md). Physical check only — sim green does not close this.

```text
player silhouette primary over guards/LPR clutter: pass / fail
projectiles readable above bodies at combat density: pass / fail
scan cones do not white-out the field at max LPR density: pass / fail
boss readable vs processing tint (not same purple): pass / fail
Blind Spot distinct from landmark zone rings: pass / fail
reduced-flash flood / cones calmer: pass / fail / n/a
```

## Device receipt JSON

```json
{}
```

Keep the JSON unchanged after copying it from the completion overlay. Link the recording and Instruments trace above rather than embedding large binaries in the repository.

See [RELEASE_READINESS.md](RELEASE_READINESS.md) for the authoritative acceptance requirements.

## Deployment evidence

```text
date and local time: 2026-08-01 16:18–16:25 PDT
device: iPhone 17 Pro (iPhone18,1; UDID 00008150-000A6C120CB8401C), iOS 26.3.1
app version / build: 0.1.0 / 1
commit SHA: 7c400e7 (main tip at run — post-#153 playability + #148 rights + #151 allowlist + board packet)
build configuration: Debug, DEVELOPMENT_TEAM=X9M969D8M3
preflight: version-check, privacy-check, release-docs-check, launch-gate-check (LAUNCH_BLOCKED), art-qa-check (ART_EVIDENCE_INSUFFICIENT), repo-status-check PASS
result: FULL automated device path PASS on post-playability tip
  1) make device-smoke — dual-launch liveness PASS
  2) make device-test — dual-launch smoke + 14/14 UITests PASS (~231s)
  3) make device-accept — smoke + force-extract (BLIND SPOT REACHED + copy-receipt-json) PASS
  4) make launch-smoke — no -UITesting; splash → start menu → BEGIN RUN → chrome PASS (device)
scope: per DEVICE_AUTOMATION.md + LAUNCH_OPERATOR_PACKET §1 / OPERATOR_PHONE_SESSION §1 only.
  NOT live ART checklist. NOT non-force extract. NOT ART_SHIP_APPROVED.
  NOT physical audio listening / route / interruption acceptance.
artifacts: .device-smoke/device-receipt.json (status=pass, commit=7c400e7);
  .launch-smoke/launch-smoke-receipt.json (status=pass, commit=7c400e7)
```

```text
date and local time: 2026-07-30 20:13–20:20 PDT
device: iPhone (UDID 00008150-000A6C120CB8401C), iOS 26.3.1
app version / build: 0.1.0 / 1
commit SHA: 7be94e3 (splash + start menu + launch-smoke tip)
build configuration: Debug, DEVELOPMENT_TEAM=X9M969D8M3
result: automated device path PASS on launch-shell tip
  1) make launch-smoke — no -UITesting; menu → BEGIN RUN → chrome PASS (device)
  2) make device-test — dual-launch smoke + 14/14 UITests PASS (includes LaunchShellUITests)
  3) make device-accept — smoke + force-extract (BLIND SPOT REACHED + copy-receipt-json) PASS
scope: per DEVICE_AUTOMATION.md + LAUNCH_OPERATOR_PACKET §1 only.
  NOT live ART checklist. NOT non-force extract. NOT ART_SHIP_APPROVED.
  NOT physical audio listening / route / interruption acceptance.
artifacts: .device-smoke/device-receipt.json; .launch-smoke/launch-smoke-receipt.json
```

```text
date and local time: 2026-07-30 19:55–20:00 PDT
device: iPhone (UDID 00008150-000A6C120CB8401C), iOS 26.3.1
app version / build: 0.1.0 / 1
commit SHA: 8e1c2ed (main tip at run; dirty board-hygiene docs not in binary)
build configuration: Debug, DEVELOPMENT_TEAM=X9M969D8M3
result: automated device path PASS on post-gameplay tip
  1) make device-test — dual-launch smoke + 13/13 LaunchUITests PASS (~251s)
  2) make device-accept — smoke + force-extract (BLIND SPOT REACHED + copy-receipt-json) PASS
scope: per DEVICE_AUTOMATION.md + LAUNCH_OPERATOR_PACKET §1 only.
  NOT live ART checklist. NOT non-force extract. NOT ART_SHIP_APPROVED.
  NOT physical audio listening / route / interruption acceptance.
artifacts: .device-smoke/device-receipt.json status=pass; DeviceUITests.xcresult
```

```text
date and local time: 2026-07-26 16:54 PDT
device: iPhone 17 Pro (iPhone18,1; UDID 00008150-000A6C120CB8401C), iOS 26.3.1
app version / build: 0.1.0 / 1
commit SHA: 43396a6 (main tip at run)
build configuration: Debug, DEVELOPMENT_TEAM=X9M969D8M3
result: docs-maximum automated device path PASS
  1) make device-accept — smoke + force-extract (BLIND SPOT REACHED + copy-receipt-json) PASS
  2) make device-test — dual-launch smoke + 4/4 UITests PASS
scope: per DEVICE_AUTOMATION.md + LAUNCH_OPERATOR_PACKET §1 only.
  NOT live ART checklist. NOT non-force extract. NOT ART_SHIP_APPROVED.
artifacts: .device-smoke/device-receipt.json status=pass; DeviceUITests.xcresult (device-acceptance-extract-summary)
```

```text
date and local time: 2026-07-26 16:35 PDT
device: iPhone 17 Pro (iPhone18,1; UDID 00008150-000A6C120CB8401C), iOS 26.3.1
app version / build: 0.1.0 / 1
commit SHA: d0075e0 (main tip at run)
build configuration: Debug, DEVELOPMENT_TEAM=X9M969D8M3
result: make device-test PASS — dual-launch smoke + 4 UITests (Launch 3 + DeviceAcceptance 1)
scope: automated deploy + chrome + mechanical force-extract only. NOT ART visual checklist / ART_SHIP_APPROVED.
artifacts: .device-smoke/device-receipt.json status=pass; DeviceUITests.xcresult

```text
date and local time: 2026-07-26 15:51 PDT
device: iPhone 17 Pro (iPhone18,1; UDID 00008150-000A6C120CB8401C), iOS 26.3.1
app version / build: 0.1.0 / 1
commit SHA: 3923e2e (main tip at run)
build configuration: Debug, DEVELOPMENT_TEAM=X9M969D8M3
result: FULL automated device suite PASS
  1) make device-accept — smoke + force-extract (BLIND SPOT REACHED) PASS
  2) make device-test — dual-launch smoke + 4 UITests (Launch 3 + DeviceAcceptance 1) PASS
scope: automated deploy + chrome + mechanical extract only. NOT ART visual checklist / ART_SHIP_APPROVED.
artifacts: .device-smoke/device-receipt.json status=pass; DeviceUITests.xcresult
note: first device-test attempt failed while operator was using the phone (YouTube banners); re-run free → green.

```text
date and local time: 2026-07-26 15:28 PDT
device: iPhone 17 Pro (iPhone18,1; UDID 00008150-000A6C120CB8401C), iOS 26.3.1
app version / build: 0.1.0 / 1
commit SHA: 1ac2377 (main tip at run)
build configuration: Debug, DEVELOPMENT_TEAM=X9M969D8M3
result: FULL automated device suite PASS
  1) make device-accept — smoke + force-extract (BLIND SPOT REACHED) PASS
  2) make device-test — dual-launch smoke + 4 UITests (Launch 3 + DeviceAcceptance 1) PASS
scope: automated deploy + chrome + mechanical extract only. NOT ART visual checklist / ART_SHIP_APPROVED.
artifacts: .device-smoke/device-receipt.json status=pass; DeviceUITests.xcresult

```text
date and local time: 2026-07-26 14:22 PDT
device: iPhone 17 Pro (iPhone18,1; UDID 00008150-000A6C120CB8401C), iOS 26.3.1
app version / build: 0.1.0 / 1
commit SHA: 47b1f5b (main — device-accept #123)
build configuration: Debug, DEVELOPMENT_TEAM=X9M969D8M3
result: `make device-accept` PASS (smoke + DeviceAcceptanceUITests force-extract; BLIND SPOT REACHED).
scope: **mechanical automation only** — not live ART/extract acceptance for ship_gate.
artifacts: .device-smoke/device-receipt.json status=pass; xcresult screenshot device-acceptance-extract-summary

```text
date and local time: 2026-07-26 14:04 PDT
device: iPhone 17 Pro (iPhone18,1; UDID 00008150-000A6C120CB8401C), iOS 26.3.1
app version / build: 0.1.0 / 1
commit SHA: (see branch tip — device-accept automation)
build configuration: Debug, DEVELOPMENT_TEAM=X9M969D8M3
result: `make device-accept` PASS — dual-launch smoke + DeviceAcceptanceUITests force-extract (BLIND SPOT REACHED + copy-receipt-json).
scope: **mechanical extract automation only**. Does NOT complete ART_DEVICE_QA_CHECKLIST or ART_SHIP_APPROVED.
artifacts: .device-smoke/device-receipt.json, DeviceUITests.xcresult screenshot attachment device-acceptance-extract-summary

```text
date and local time: 2026-07-26 13:34 PDT
device: iPhone 17 Pro (iPhone18,1; UDID 00008150-000A6C120CB8401C), iOS 26.3.1
app version / build: 0.1.0 / 1
commit SHA: 7423f90 (main — LPR fixed LOS + chrome stability #121)
build configuration: Debug, DEVELOPMENT_TEAM=X9M969D8M3 automatic signing
result: `DEVICE_UDID=00008150-000A6C120CB8401C DEVELOPMENT_TEAM=X9M969D8M3 DEVICE_SUITE_SKIP_UI=1 make device-test` dual-launch liveness pass (pid 25219 after relaunch). Receipt status=pass kind=device-suite.
scope: **deployment proof only**. Full acceptance (ART checklist + extract + p95) remains operator-owned — play on this tip next.
operator notes:
  - Binary includes stationary LPR red LOS (no cone sweep); suspicion from standing in cone; guards/Shift Manager from elevated suspicion.
  - Ready for operator step 2 acceptance session (see LAUNCH_OPERATOR_PACKET step 2).

date and local time: 2026-07-26 13:16 PDT
device: iPhone 17 Pro (iPhone18,1; UDID 00008150-000A6C120CB8401C), iOS 26.3.1
app version / build: 0.1.0 / 1
commit SHA: 0699cb5 (LPR fixed LOS + UITesting chrome/settings stability)
build configuration: Debug, DEVELOPMENT_TEAM=X9M969D8M3 automatic signing
result: `DEVICE_UDID=00008150-000A6C120CB8401C DEVELOPMENT_TEAM=X9M969D8M3 DEVICE_SUITE_SKIP_UI=1 make device-test` dual-launch liveness pass (pid 25120 after relaunch). Receipt: .device-smoke/device-receipt.json status=pass kind=device-suite.
scope: **deployment proof only**. Full acceptance (ART_DEVICE_QA_CHECKLIST, combat readability, extract receipt, p95, resume) remains operator-owned.
operator notes:
  - Includes stationary LPR red LOS cones (no sweep); PTZ may still pan.
  - Simulator LaunchUITests green (pause/settings). Device UI automation still flaky (banner interruptions / settings sheet); not required for deploy proof.
  - ship_gate / launch gates remain EVIDENCE_INSUFFICIENT / LAUNCH_BLOCKED until operator ART + extract.

date and local time: 2026-07-25 19:17 PDT
device: iPhone 17 Pro (iPhone18,1; UDID 00008150-000A6C120CB8401C), iOS 26.3.1
app version / build: 0.1.0 / 1
commit SHA: 8a84315 (pause expanded SuspicionMeter + board hygiene #96 on main)
build configuration: Debug, DEVELOPMENT_TEAM=X9M969D8M3 automatic signing
result: `DEVELOPMENT_TEAM=X9M969D8M3 DEVICE_SUITE_SKIP_UI=1 make device-test` dual-launch liveness pass (pid 23427 after relaunch).
scope: **deployment proof only**. Full acceptance (ART_DEVICE_QA_CHECKLIST, combat readability, extract receipt, p95, resume) remains operator-owned.
operator notes:
  - Tip includes #94 device automation, #95 chrome residuals, #96 pause expanded SuspicionMeter.
  - Re-verify on device: compact live HUD; pause full meter; multi-kill queue cue; tokenized district list.
  - UI Automation not exercised this run (DEVICE_SUITE_SKIP_UI=1).

date and local time: 2026-07-25 18:58 PDT
device: iPhone 17 Pro (iPhone18,1; UDID 00008150-000A6C120CB8401C), iOS 26.3.1
app version / build: 0.1.0 / 1
commit SHA: 8b5d03a (pause expanded SuspicionMeter + board tip hygiene)
build configuration: Debug, DEVELOPMENT_TEAM=X9M969D8M3 automatic signing
result: `DEVELOPMENT_TEAM=X9M969D8M3 DEVICE_SUITE_SKIP_UI=1 make device-test` dual-launch liveness pass (pid 23412 after relaunch).
scope: **deployment proof only**. Full acceptance (ART_DEVICE_QA_CHECKLIST, combat readability, extract receipt, p95, resume) remains operator-owned.
operator notes:
  - Binary includes #94 device automation path, #95 chrome residuals (queue cue, district list, GameChrome receipt).
  - Pause overlay includes expanded SuspicionMeter (not live-HUD card).
  - UI Automation mode not exercised this run (DEVICE_SUITE_SKIP_UI=1).

date and local time: 2026-07-25 16:58 PDT
device: iPhone 17 Pro (iPhone18,1; UDID 00008150-000A6C120CB8401C), iOS 26.3.1
app version / build: 0.1.0 / 1
commit SHA: c468b90 (continue-ss closeout #92 on tip deb1d4f #91 multi-kill queue + chrome)
build configuration: Debug, DEVELOPMENT_TEAM=X9M969D8M3 automatic signing
result: `DEVICE_UDID=00008150-000A6C120CB8401C DEVELOPMENT_TEAM=X9M969D8M3 make device-smoke` built, installed, and foreground-launched via `xcrun devicectl` (bundle life.zerostate.surveillancesurvivor).
scope: **deployment proof only** for tip c468b90. Full acceptance (ART_DEVICE_QA_CHECKLIST, combat readability, extract receipt, p95, resume) remains pending for the operator on device.
operator notes for this tip (checklist still open):
  - Play binary includes compact HUD + fullscreen (#88), terminal settings chrome (#89), multi-kill upgrade queue + GameChrome buttons (#91).
  - Re-verify: playfield readable under compact strip; multi-kill drafts queue after first pick; COPY RECEIPT / next-district chrome polish residual only.

date and local time: 2026-07-25 15:22 PDT
device: iPhone 17 Pro (iPhone18,1; UDID 00008150-000A6C120CB8401C), iOS 26.3.1
app version / build: 0.1.0 / 1
commit SHA: 8578b1a (launch operator packet + art-qa-check #87)
build configuration: Debug, DEVELOPMENT_TEAM=X9M969D8M3 automatic signing
result: `DEVICE_UDID=00008150-000A6C120CB8401C DEVELOPMENT_TEAM=X9M969D8M3 make device-smoke` built, installed, and foreground-launched via `xcrun devicectl` (bundle life.zerostate.surveillancesurvivor).
scope: **deployment proof only** for tip 8578b1a. Full acceptance (ART_DEVICE_QA_CHECKLIST, combat readability, extract receipt, p95, resume) remains pending for the operator on device.
operator UX notes (2026-07-25, tip 8578b1a Debug landscape):
  - HUD left stack (status / suspicion / integrity / shards / loadout / seed) **blocks playfield** — Hallmark HUD audit C1; remediated compact strip in follow-up.
  - App presentation **not true fullscreen** (status bar / safe-area competition) — C2; status-bar hide + requires-fullscreen keys + root ignoresSafeArea.
  - Gameplay loop observed vs design: stationary LPR scan cones, destroy cameras → upgrade draft (shards), not a mid-run coin shop (see WEAPON_SYSTEM_DESIGN).
  - Full ART checklist / extract receipt still open after HUD redeploy.

date and local time: 2026-07-22 17:00 PDT
device: iPhone 17 Pro (iPhone18,1; UDID 00008150-000A6C120CB8401C), iOS 26.3.1
app version / build: 0.1.0 / 1
commit SHA: 669409d (manual pause, settings freeze, run-seed display)
build configuration: Debug, DEVELOPMENT_TEAM=X9M969D8M3 automatic signing
result: `make device-smoke` built, installed, and foreground-launched via `xcrun devicectl`.
scope: deployment proof only for main after PR #11. Full acceptance observations, frame p95, thermal, haptics, audio-route, screen recording, and Instruments evidence remain pending for the reviewer.

date and local time: 2026-07-22 15:34 PDT
device: iPhone 17 Pro (iPhone18,1; UDID 00008150-000A6C120CB8401C), iOS 26.3.1
app version / build: 0.1.0 / 1
commit SHA: 34a8157 (observe game scene state in root view)
build configuration: Debug, Xcode-managed development signing
result: `xcrun devicectl` confirmed the bundle was installed and foreground-launched; reviewer confirmed a countermeasure draft choice cleared and the run resumed.
scope: the upgrade-selection regression is physically verified fixed. Full-run gameplay, resume, performance, accessibility, haptics, audio, receipt extraction, screen recording, and Instruments evidence remain pending.

date and local time: 2026-07-22 15:16 PDT
device: iPhone 17 Pro (iPhone18,1; UDID 00008150-000A6C120CB8401C), iOS 26.3.1
app version / build: 0.1.0 / 1
commit SHA: 6d530e1 (dismiss selected upgrade draft immediately)
build configuration: Debug, Xcode-managed development signing
result: `xcrun devicectl` confirmed the bundle was installed and foreground-launched.
scope: superseded by the 15:34 PDT entry for the upgrade-selection regression; broader physical acceptance remains pending.

```
