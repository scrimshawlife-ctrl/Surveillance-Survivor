# P8 — Emergent Build Engine contract (slice A)

```yaml
version: 1.0.0
status: in_progress
last_updated: 2026-07-25
authority_scope: Upgrade tags + synergy graph + explicit non-stat behaviors
```

**Roadmap:** P8 systemic runtime architecture  
**Design authority:** [`ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md`](ROGUELIKE_BENCHMARK_AND_DESIGN_ASSIMILATION.md) E4  
**Content:** `Sources/SurveillanceCore/Resources/Content/build_synergies.json`  
**Runtime:** `BuildEngineCatalog` · `BuildEngine` · `RunState.buildEngine`  
**Gate:** `make build-engine-check`

---

## Objective

Turn the upgrade pool into a **synergy graph** (tags, thresholds, exclusions) so builds alter **readable behavior**, not only numeric damage.

## Slice A scope

| Piece | Role |
| --- | --- |
| Eight families | signal, camouflage, bureaucracy, physical, mobility, decoys, infrastructure, high-risk |
| `upgradeTags` | Every `UpgradeChoice` tagged |
| `synergies` | Required tags, min counts, exclusions, min selection count |
| Allowed behaviors | `suspicionRecoveryBoost`, `observationSoftener`, `directorBudgetRelief` |
| Forbidden | damage/HP/hidden difficulty levers |
| Receipt | schema v5 `buildSynergyActivations` + `buildEngine` |

## Acceptance

- [x] Python + Swift validation  
- [x] Deterministic evaluation fixtures  
- [x] Exclusion rules (e.g. flood risk vs camouflage)  
- [x] Mild sim hooks (recovery / observation / director budget)  
- [x] CI `build-engine-check`  
- [ ] Multi-system evolutions beyond existing four  
- [ ] Full transform/trigger scripting language (later)

## Non-goals

- Closing #3 / device acceptance  
- Pure permanent damage inflation as progression  
