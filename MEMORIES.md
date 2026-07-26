# Bug-finding memory

Tracked critical bugs with open or rejected fix PRs. Do not re-open duplicates while status is open.

| Bug (location + root cause) | PR | Status | Recorded |
|---|---|---|---|
| `CampaignProgress.recordRunOutcome`: locked daily/weekly challenge extractions used `completedLevel >= frontier`, skipping the campaign unlock chain | https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/99 | open | 2026-07-26 |
| `CampaignProgressStore` / `MasteryProgressStore`: unsupported-future load returned `.initial` then next run save overwrote the preserved envelope | https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/99 | open | 2026-07-26 |
| `Simulation.applyUpgradeSelection`: early `return` on stale ineligible weapon choice left draft open; queue drain decremented before a successful offer | https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/99 | open | 2026-07-26 |
| `Simulation.step`: boss activation before death resolution respawned a live boss on the kill tick at totalVisibility | https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/99 | open | 2026-07-26 |
| `GameScene.update`: hitch catch-up used stale published upgrade choices, allowing extra sim steps after a draft opened | https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/99 | open | 2026-07-26 |
| `GameScene.bootstrapCampaignDistrictIfNeeded`: late onAppear could reset a progressed run when district differed | https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/99 | open | 2026-07-26 |
| `Simulation.applyOngoingCountermeasures`: FOIA tick damage omitted from `damageDealt` receipt totals | https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/99 | open | 2026-07-26 |
| `ChallengeResolver.weekKey`: gregorian calendar lacked ISO week settings at year boundaries | https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/99 | open | 2026-07-26 |
| `CoordinationEngine.advance`: terminal link emitted duplicate `.completed` events for the same link | https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/99 | open | 2026-07-26 |
