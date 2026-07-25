# P10 — Ten-city systemic projection

```yaml
version: 1.5.0
status: systems_board_complete
last_updated: 2026-07-25
slice: offer_bias
tip_base: 2c5741e
```

**Authority:** [`ROADMAP.md`](ROADMAP.md) P10 · city rule identity  
**Catalog:** `Sources/SurveillanceCore/Resources/Content/city_systemic_rules.json`  
**Gate:** `make city-rules-check`

## Goal

Each city gains **rule-level identity**, not only texture identity.

## Progress

| Slice | Deliverable | Status |
| --- | --- | --- |
| A | Rules for all 10 + Louisville full systems | **Done** (#69) |
| B | Tulsa + Dayton full systems projection | **Done** (#70) |
| C | Oakland + San Francisco full systems | **Done** (#71) |
| D+E | Columbus → Atlanta full systems (10/10) | **Done** (#72) |
| F | Upgrade offer bias from `upgradeWeightingTags` | **This PR** |
| — | Device budget fixture per city | Operator |

## Projection status board

| District | Status | Landmark | Coordination |
| --- | --- | --- | --- |
| wichita | full_p9_proof | wichita_big_box_anchor | lot_capture_cascade |
| louisville | slice_a_projected | louisville_redaction_corridor | redaction_cascade |
| tulsa | slice_a_projected | tulsa_extraction_yard | crude_extract_cascade |
| dayton | slice_a_projected | dayton_gateway_cluster | gateway_chain_cascade |
| oakland | slice_a_projected | oakland_port_sanctuary | jurisdiction_borrow_cascade |
| sanFrancisco | slice_a_projected | sf_fog_warrant_band | fog_warrant_cascade |
| columbus | slice_a_projected | columbus_six_hundred_eye | jurisdiction_split_cascade |
| newYorkCity | slice_a_projected | nyc_omnigaze_nexus | borough_sync_cascade |
| losAngeles | slice_a_projected | la_private_lot_nexus | private_network_cascade |
| atlanta | slice_a_projected | atlanta_server_cathedral | hive_converge_cascade |

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

## Full systems package (projected cities)

For each `slice_a_projected` / `full_p9_proof` district:

- ≥3 infrastructure node families (graph ≥6 nodes preferred)
- ≥6 environmental interactables
- Coordination chain with ≥2 counterplay links
- Landmark-scale set piece (pressure levers only)
- Deterministic seed fixture

## Upgrade offer bias (slice F)

- Source: `CitySystemicRule.upgradeWeightingTags` (build-family tags)
- Engine: `UpgradeOfferBias.pickOffers` — preferred weight 3× vs neutral 1×
- Receipt: `RunReceipt.upgradeOfferBiasEvents` (schema **v10**)
- No damage/HP scaling; bias is draft composition only

## Next

- Device budget fixture per city (operator)
- Optional: promote selected cities to `full_p9_proof` with device evidence

## Non-goals

- City 11
- Hidden damage/health inflation
- Closing device #3 from sim green
