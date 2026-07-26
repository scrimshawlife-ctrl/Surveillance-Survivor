# Bug-finding memory

Tracked critical bugs with open or rejected fix PRs. Do not re-open duplicates while status is open.

| Bug (location + root cause) | PR | Status | Recorded |
|---|---|---|---|
| `SuspicionDirector.evaluate` left prior `applied*` levers sticky when no candidates remained (cooldown/budget gaps) | pending | open | 2026-07-26 |
| `applyLandmarkSuspicionFloor` raised tier after `updateSuspicion` without emitting `.tierChanged` | pending | open | 2026-07-26 |
| Signal flood always emitted `.countermeasureHit` even with zero disrupted targets (false hit SFX/receipt) | pending | open | 2026-07-26 |
| RootView held campaign/mastery stores as `@State` class refs; summary could miss updated progress after receipt processing | pending | open | 2026-07-26 |
