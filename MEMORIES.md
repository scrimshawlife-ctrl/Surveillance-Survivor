# Bug-finding memory

Tracked critical bugs with open or rejected fix PRs. Do not re-open duplicates while status is open.

| Bug (location + root cause) | PR | Status | Recorded |
|---|---|---|---|
| `CityStateEngine.applyHit` propagated requested hit amount, so offline nodes still damaged downstream | #115 | open | 2026-07-26 |
| `GameScene.resetSession` / install never snapped `followCamera`, so district changes eased from stale pose | #115 | open | 2026-07-26 |
| Signal flood suspicion spike skipped tier sync; same-tick defeat early-return left stale tier | #115 | open | 2026-07-26 |
| `CoordinationEngine.startIfNeeded` wiped interrupted/completed counts on chain restart | #115 | open | 2026-07-26 |
| Haptics fired once per same-tick camera destroy | #115 | open | 2026-07-26 |
| Player animation marked `.extracting` whenever extraction was open, not only near Blind Spot | #115 | open | 2026-07-26 |
| Upgrade/Enemy/Audio catalogs accepted empty/invalid domains (empty upgrade effects, scanHalfAngle > π, negative adaptive gain) | #115 | open | 2026-07-26 |
