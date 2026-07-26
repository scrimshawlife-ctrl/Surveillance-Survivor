# Bug-finding memory

Tracked critical bugs with open or rejected fix PRs. Do not re-open duplicates while status is open.

| Bug (location + root cause) | PR | Status | Recorded |
|---|---|---|---|
| `resolveDeaths` still granted camera shards/upgrades/city-state/coordination after same-tick player defeat | #111 | open | 2026-07-26 |
| Spent projectiles marked health=0 were counted in `deathsByArchetype` and emitted `.entityDestroyed` | #111 | open | 2026-07-26 |
| Spoof/FOIA status merge extended duration but overwrote stronger effect values with weaker in-flight payloads | #111 | open | 2026-07-26 |
| `GameScene.didMove` always `addChild(followCamera)` → crash on SpriteView reattach | #111 | open | 2026-07-26 |
| Extraction open+complete in one batch double-fired haptic/audio success cues | #111 | open | 2026-07-26 |
|