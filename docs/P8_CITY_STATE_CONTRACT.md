# P8 — Dynamic City State contract (slice A)

```yaml
version: 1.0.0
status: in_progress
last_updated: 2026-07-25
authority_scope: Infrastructure node graph + deterministic propagation
```

**Roadmap:** P8 systemic runtime architecture  
**Design authority:** [`ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md`](ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md) E2  
**Content:** `Sources/SurveillanceCore/Resources/Content/infrastructure_nodes.json`  
**Runtime:** `CityStateCatalog` · `CityStateEngine` · `RunState.districtState`  
**Gate:** `make city-state-check`

---

## Objective

Represent each district as an **infrastructure graph** whose disruption creates **both opportunity and cost**, with seed-deterministic propagation and **no hidden damage/health scaling**.

## Slice A scope

| Piece | Role |
| --- | --- |
| `infrastructure_nodes.json` | Authored nodes/edges for Wichita (Big-Box proof district) |
| Eight node families | sensors, power, fiber, traffic, access, transit, civilian reporting, emergency |
| Propagation | BFS along edges with `propagationWeight` |
| Sensor destroy hook | Hits primary `surveillanceSensors` node integrity |
| Observation lever | Softens suspicion *pressure only* when sensor grid degrades/offline |
| Receipt | `cityStateEvents` + final `districtState` (schema v4) |

## Acceptance (this slice)

- [x] Bundled graph validates in Python + Swift  
- [x] Opportunity + cost labels on every node  
- [x] Deterministic hit + propagation fixtures  
- [x] Sensor destroy → city-state events on receipt  
- [x] CI `city-state-check`  
- [ ] Ten-city graphs (P10)  
- [ ] Environmental interactables (E3) wired to nodes  

## Non-goals

- Closing #3 / device acceptance  
- Full Big-Box systems proof (P9)  
- Secret difficulty scaling  
