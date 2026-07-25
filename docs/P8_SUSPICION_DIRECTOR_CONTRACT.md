# P8 — Suspicion Director contract (slice A)

```yaml
version: 1.0.0
status: in_progress
last_updated: 2026-07-25
authority_scope: Suspicion Director content authority + deterministic evaluation
```

**Roadmap:** P8 systemic runtime architecture  
**Design authority:** [`ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md`](ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md) E1  
**Content:** `Sources/SurveillanceCore/Resources/Content/director_rules.json`  
**Runtime:** `SuspicionDirectorCatalog` · `SuspicionDirector` · `RunState.suspicionDirector`  
**Gate:** `make director-check`

---

## Objective

Turn Suspicion tiers into an **explicit, seed-deterministic encounter director** with budgets, cooldowns, pressure windows, and readable levers — **without** hidden player damage or enemy health scaling.

## Contract surface

| Piece | Role |
| --- | --- |
| `director_rules.json` | Bundled authority: tiers 0…5, actions, levers, forbidden keys |
| `SuspicionDirector.evaluate` | Pure evaluation; mutates only director state |
| `RunState.suspicionDirector` | Active levers applied to spawn cadence |
| `RunReceipt.directorDecisions` | Authoritative decision log (schema v3) |
| `RunEvent.Kind.directorDecision` | In-run event sequence evidence |

### Allowed levers (v1)

- `guardTargetDelta` — additive guard population pressure (still ceiling-clamped)
- `spawnIntervalMultiplier` — scales guard spawn interval
- `sensorCadenceMultiplier` — scales sensor deployment interval

### Forbidden (must remain true)

- `forbidHiddenStatScaling: true`
- Reserved keys: `playerDamageScale`, `enemyHealthScale`, `playerHealthScale`, `hiddenDifficulty`, `secretStatMultiplier`

## Acceptance (this slice)

- [x] Bundled rules validate in Python + Swift
- [x] Seed + input trace reproduces director decisions
- [x] Receipt records decisions that match events (no invented narrative)
- [x] CI `director-check` on core + simulator jobs
- [ ] Full P9 Big-Box systems proof (later)
- [ ] City State / Build Engine / Coordination Graph (later P8 epics)

## Emulator evidence

Package tests cover determinism. Simulator / `make emulator-test` proves the app host still loads with the extended receipt schema.

## Non-goals

- Closing ART #3 or device acceptance from this work
- Adaptive difficulty via secret stats
- Full coordination graph or infrastructure graph
