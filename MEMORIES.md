# Bug-finding memory

Tracked critical bugs with open or rejected fix PRs. Do not re-open duplicates while status is open.

| Bug (location + root cause) | PR | Status | Recorded |
|---|---|---|---|
| `Simulation.triggerSignalFlood` emitted both `guardDisrupted` and `sensorDisabled` whenever any target was hit, falsely interrupting coordination counterplay links | pending | open | 2026-07-26 |
| `Simulation.resolveProjectileHits` consumed projectiles on the first overlapping body even when payload was incompatible (redaction/FOIA wasted on wrong kinds) | pending | open | 2026-07-26 |
| Radio Guy speed aura ignored `health` / `disruptedUntilTick`, so disrupted support still buffed nearby guards | pending | open | 2026-07-26 |
| Guard/sensor spawn clamped to bounds but not obstacles; bodies could start stuck inside solids | pending | open | 2026-07-26 |
| Interactables evaluated before movement integration → utility range used stale player pose | pending | open | 2026-07-26 |
| `MasteryProgress.sanitized` left `currentDailyStreak > dailyBestStreak` (clamp was a no-op) | pending | open | 2026-07-26 |
| `GameScene.setRunPaused(true)` left `requestedUtilityActivation` set → stale activate on resume | pending | open | 2026-07-26 |
| `HapticFeedback` played damage + defeat pulses in the same lethal batch | pending | open | 2026-07-26 |
| RootView challenge start closures re-called `Date()` and could diverge from displayed daily/weekly at UTC rollover | pending | open | 2026-07-26 |
