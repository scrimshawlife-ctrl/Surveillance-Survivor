# Bug-finding memory

Tracked critical bugs with open or rejected fix PRs. Do not re-open duplicates while status is open.

| Bug (location + root cause) | PR | Status | Recorded |
|---|---|---|---|
| Receipt suspicion timeline under-sampled short peaks; story `peak` used timeline max only | #112 | open | 2026-07-26 |
| Dead guards (`health <= 0`) still counted in spawn population and suspicion pressure before `resolveDeaths` | #112 | open | 2026-07-26 |
| `tierChanged` emitted on suspicion recovery (decrease), mapping to tier-up audio/haptics | #112 | open | 2026-07-26 |
| SuspicionDirector reused stale low-tier budget across tier escalations within a pressure window | #112 | open | 2026-07-26 |
| Secondary motion offsets applied to projectiles/sensors/deployables/extraction, drifting from sim pose | #112 | open | 2026-07-26 |
