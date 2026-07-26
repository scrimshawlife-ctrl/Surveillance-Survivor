# Bug-finding memory

Tracked critical bugs with open or rejected fix PRs. Do not re-open duplicates while status is open.

| Bug (location + root cause) | PR | Status | Recorded |
|---|---|---|---|
| Sensor escalation budget used live `cameraPole` count − startingSensors, so kills reopened/cycled deployment | #116 | open | 2026-07-26 |
| Landmark hazard de-dupe keyed by `Int(seconds)`, colliding same-kind hazards in one integer second | #116 | open | 2026-07-26 |
| `Simulation(state:)` ignored `buildEngine.selectedUpgradeIds`, wiping synergies on next upgrade | #116 | open | 2026-07-26 |
| Suspicion Director treated `windowStartedElapsed == 0` as uninitialized, resetting in-window budget | #116 | open | 2026-07-26 |
