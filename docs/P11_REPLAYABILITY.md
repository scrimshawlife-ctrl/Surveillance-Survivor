# P11 — Replayability and mastery program

```yaml
version: 1.0.0
status: slice_a_in_progress
last_updated: 2026-07-25
slice: A
tip_base: a81c23d
```

**Authority:** [`ROADMAP.md`](ROADMAP.md) P11  
**Catalog:** `Sources/SurveillanceCore/Resources/Content/challenge_contracts.json`  
**Gate:** `make challenge-contracts-check`

## Goal

Add **replay surfaces and mastery records** without permanent damage/health inflation.

## Slice A (this PR)

| Deliverable | Status |
| --- | --- |
| Challenge contracts catalog (daily + weekly mutators) | **Done** |
| Deterministic daily / weekly resolver (UTC day / week keys) | **Done** |
| Simulation mutator wiring (observation / spawn / guard / upgrade tags) | **Done** |
| Receipt `challenge` + schema **v11** | **Done** |
| MasteryProgress + RunHistoryEntry (pure value types) | **Done** |
| App-layer persistence / UI for challenges | Pending |
| Cosmetics / gadgets / archetype unlocks | Later |

## Mutator allow-list

| Kind | Effect |
| --- | --- |
| `observationPressureBonus` | Multiplies observation pressure (0…0.25) |
| `spawnIntervalMultiplier` | Scales guard spawn interval (0.5…1.5) |
| `guardTargetDelta` | Additive guard population target (−2…3) |
| `extraUpgradeWeightingTag` | Extra build-family tag for offer bias |

Forbidden: any damage/HP/hidden-difficulty scaling.

## Daily / weekly resolution

- **Daily key:** `YYYY-MM-DD` UTC  
- **Weekly key:** `YYYY-Www` UTC (Monday-based week)  
- Seed: stable mix of salt + key → district + contract selection  
- Identical day/week → identical `ChallengeInstance`

## Mastery

`MasteryProgress` is a pure Codable value type (like `CampaignProgress`):

- capped run history  
- challenge completion counts  
- daily streak (UTC day keys)  
- no sim-loop I/O  

App layer owns `UserDefaults` persistence in a later slice.

## Non-goals

- Global permanent damage/health inflation  
- Closing device #3 from sim green  
- Full cosmetics marketplace  

## Next

- App UI: Daily / Weekly entry points  
- Persist MasteryProgress envelope  
- Expand mutator palette (weather labels, radio sets) without stat inflation  
