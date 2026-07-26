# Bug-finding memory

Tracked critical bugs with open or rejected fix PRs. Do not re-open duplicates while status is open.

| Bug (location + root cause) | PR | Status | Recorded |
|---|---|---|---|
| `CampaignProgress.recordRunOutcome`: locked daily/weekly challenge extractions used `completedLevel >= frontier`, skipping the campaign unlock chain | https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/99 | open | 2026-07-26 |
| `CampaignProgressStore` / `MasteryProgressStore`: unsupported-future load returned `.initial` then next run save overwrote the preserved envelope | https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/99 | open | 2026-07-26 |
| `Simulation.applyUpgradeSelection`: early `return` on stale ineligible weapon choice left draft open; queue drain decremented before a successful offer | https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/99 | open | 2026-07-26 |
