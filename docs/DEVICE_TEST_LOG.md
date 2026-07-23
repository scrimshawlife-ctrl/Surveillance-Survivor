# Physical-Device Test Log

Use one copy of this template per signed-development-build acceptance run. Do not replace a pending item with simulator evidence. Paste the output from **COPY RECEIPT JSON** after extraction.

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
haptic observation:
audio interruption / route-change observation:
known issues or follow-up:
```

## Device receipt JSON

```json
{}
```

Keep the JSON unchanged after copying it from the completion overlay. Link the recording and Instruments trace above rather than embedding large binaries in the repository.

See [RELEASE_READINESS.md](RELEASE_READINESS.md) for the authoritative acceptance requirements.

## Deployment evidence

```text
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
