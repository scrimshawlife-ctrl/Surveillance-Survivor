# Bug-finding memory

Tracked critical bugs with open or rejected fix PRs. Do not re-open duplicates while status is open.

| Bug (location + root cause) | PR | Status | Recorded |
|---|---|---|---|
| `Simulation.fireActiveWeapons`: projectile-cap `break` skipped later deployable/projectile weapons in the same tick | https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/101 | open | 2026-07-26 |
| `Simulation.activateShiftManagerIfNeeded`: boss could spawn after same-tick player defeat / runCompleted | https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/101 | open | 2026-07-26 |
| `Simulation` damage metrics: projectile/mirror/contact overkill inflated `damageDealt`/`damageTaken` vs actual health lost | https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/101 | open | 2026-07-26 |
