# Test Automation Contract

## Purpose

This repository uses layered automation so deterministic gameplay failures are isolated from simulator, presentation, and device failures.

## Lanes

### 1. Contract validators

Fast Python and shell validators verify version alignment, manifests, systemic rules, challenge contracts, unlockables, launch gates, and Art QA package integrity.

### 2. Deterministic Swift core

`swift test --parallel` runs the complete `SurveillanceCoreTests` package suite on Linux and macOS.

`AutomationInvariantTests.swift` adds deliberately stable automation invariants:

- identical seed + identical input transcript produces identical events, state, and receipt;
- completed runs reject all further mutation;
- fixed-step elapsed time and receipt ticks remain aligned;
- authoritative `RunState` survives deterministic Codable round trips;
- receipt event sequence and tick order remain monotonic.

These tests avoid balancing constants and authored-content counts so agents can repeat them during refactors without creating false failures from legitimate content tuning.

### 3. iPhone simulator contract

The macOS lane generates the Xcode project, boots an available iPhone simulator, runs application-layer unit tests, and performs the existing install/launch/liveness smoke.

Physical-device acceptance remains separate because it requires signing, a connected unlocked iPhone, and operator visual review.

## Stable entry point

```bash
bash scripts/run_automation_tests.sh
```

Environment controls:

| Variable | Default | Purpose |
|---|---:|---|
| `AUTOMATION_REPEAT_COUNT` | `3` | Repeats the stable automation invariants to expose nondeterminism. |
| `AUTOMATION_RUN_VALIDATORS` | `1` | Set to `0` for a Swift-only local loop. |
| `AUTOMATION_ARTIFACT_DIR` | `.automation-test-results` | Destination for logs and `summary.json`. |

Example focused refactor loop:

```bash
AUTOMATION_RUN_VALIDATORS=0 AUTOMATION_REPEAT_COUNT=10 \
  bash scripts/run_automation_tests.sh
```

## Machine-readable receipt

Every runner invocation writes `summary.json` with:

- schema version;
- pass/fail status and failed phase;
- exit code;
- UTC start and finish timestamps;
- repetition count;
- platform, Python, Swift, and Git commit provenance.

GitHub Actions uploads the receipt and phase logs even when a test fails.

## GitHub Actions policy

`.github/workflows/automation-tests.yml` runs:

- on relevant pull-request changes;
- on pushes to `main`;
- nightly with ten deterministic repetitions;
- manually with a caller-selected repetition count.

Concurrency cancellation prevents stale runs from consuming macOS capacity. Each job has a hard timeout and retains evidence for fourteen days.

## Failure triage

1. Read `summary.json` and identify `failed_phase`.
2. Inspect the matching phase log.
3. Reproduce through `scripts/run_automation_tests.sh` with validators disabled only when the failure is confirmed to be Swift-specific.
4. Do not weaken deterministic assertions to conceal drift. Change the invariant only when the authoritative simulation contract intentionally changes.
