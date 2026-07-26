# Bug-finding memory

Tracked critical bugs with open or rejected fix PRs. Do not re-open duplicates while status is open.

| Bug (location + root cause) | PR | Status | Recorded |
|---|---|---|---|
| `Simulation.step`: lethal contact still ran suspicion/director/spawn before `resolveDeaths` | (pending) | open | 2026-07-26 |
| `LandmarkEncounterEngine`: `minimumTierRaw` authored/validated but never applied while inside | (pending) | open | 2026-07-26 |
| `LandmarkEncounterEngine`: `timeInsideSeconds` / fired hazards persisted across exits, so dwell hazards could fire immediately on re-entry | (pending) | open | 2026-07-26 |
| `AudioCueResolver.resolve`: adaptive tier gain hooks unused; cues always used base `cue.gain` | (pending) | open | 2026-07-26 |
