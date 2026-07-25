# P8 — Enemy Coordination Graph contract (slice A)

```yaml
version: 1.0.0
status: in_progress
last_updated: 2026-07-25
authority_scope: Interruptible coordination chains with ≥2 counterplay points
```

**Roadmap:** P8 systemic runtime architecture  
**Design authority:** [`ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md`](ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md) E5  
**Content:** `Sources/SurveillanceCore/Resources/Content/coordination_graphs.json`  
**Runtime:** `CoordinationCatalog` · `CoordinationEngine` · `RunState.coordination`  
**Gate:** `make coordination-check`

---

## Objective

Model readable, interruptible enemy response chains:

```text
sensor detects → dispatcher validates → patrol reroutes → blocker denies → capture closes
```

Destroying, spoofing, disabling sensors, or disrupting guards must break the chain.

## Slice A scope

| Piece | Role |
| --- | --- |
| `lot_capture_cascade` | Wichita default 5-link chain |
| Counterplay | ≥2 links with interrupt signals |
| Levers | guardTargetDelta, observationPressureBonus, spawnIntervalMultiplier |
| Forbidden | damage/HP/hidden difficulty |
| Receipt | schema v6 `coordinationEvents` + final `coordination` |

## Acceptance

- [x] Python + Swift validation  
- [x] Start on sensor contact; interrupt on sensor destroy  
- [x] Timer advance between links  
- [x] Sim hooks + receipt evidence  
- [x] CI `coordination-check`  
- [ ] Per-city chain variants (P10)  
- [ ] Full blocker topology / path denial geometry (later)

## Non-goals

- Closing #3 / device acceptance  
- Secret difficulty scaling  
