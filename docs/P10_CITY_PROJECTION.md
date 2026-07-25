# P10 — Ten-city systemic projection

```yaml
version: 1.0.0
status: in_progress
last_updated: 2026-07-25
slice: A
```

**Authority:** [`ROADMAP.md`](ROADMAP.md) P10 · city rule identity  
**Catalog:** `Sources/SurveillanceCore/Resources/Content/city_systemic_rules.json`  
**Gate:** `make city-rules-check`

## Goal

Each city gains **rule-level identity**, not only texture identity.

## Slice A (this PR)

| Deliverable | Status |
| --- | --- |
| `city_systemic_rules` for all 10 districts | **Done** |
| Forbid hidden damage/HP scaling | **Done** |
| Wichita full P9 proof status | **Done** |
| Louisville full systems projection (infra + coordination + landmark + ≥6 interactables) | **Done** |
| Deterministic Louisville seed fixture | **Done** |
| Remaining 8 cities rules-only scaffolding | **Done** |

## Per-city contract fields

| Field | Meaning |
| --- | --- |
| topologyGrammar | Traversal / lot grammar label |
| infrastructureProfile | City-state graph theme |
| weatherLightingModifier | Presentation / pressure flavor (not damage) |
| civilianReportingBias | Reporting pressure identity |
| enemyFactionWeighting | Roster flavor label |
| upgradeWeightingTags | Build-family preference tags |
| landmarkHookId | Optional landmark encounter id |
| radioLanguage | Satirical radio voice id |
| audioMotifId | Catalog motif (stems may be missing) |
| satiricalPolicyModifier | Policy mutator label |
| projectionStatus | `rules_only` · `slice_a_projected` · `full_p9_proof` |

## Projection status board

| District | Status |
| --- | --- |
| wichita | full_p9_proof |
| louisville | slice_a_projected |
| tulsa … atlanta | rules_only |

## Next slices

- Project Tulsa / Dayton (or next campaign order) to `slice_a_projected`
- Wire upgradeWeightingTags into upgrade offer bias (explicit, receipted)
- Device budget fixture per city (operator)

## Non-goals

- City 11
- Hidden damage/health inflation
- Closing device #3 from sim green
