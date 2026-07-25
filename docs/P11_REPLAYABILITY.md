# P11 — Replayability and mastery program

```yaml
version: 1.2.0
status: slice_c_in_progress
last_updated: 2026-07-25
slice: C
tip_base: 5b6404e
```

**Authority:** [`ROADMAP.md`](ROADMAP.md) P11  
**Catalogs:** `challenge_contracts.json` · `unlockables.json`  
**Gates:** `make challenge-contracts-check` · `make unlockables-check`

## Goal

Add **replay surfaces and mastery records** without permanent damage/health inflation.

## Progress

| Slice | Deliverable | Status |
| --- | --- | --- |
| A | Contracts, resolver, sim mutators, receipt v11, mastery value types | **Done** (#74) |
| B | MasteryProgressStore + Daily/Weekly run-summary entry | **Done** (#75) |
| C | Unlockables catalog + mastery auto-grant (presentation only) | **This PR** |

### Slice B details

| Deliverable | Status |
| --- | --- |
| `MasteryProgressStore` (UserDefaults envelope) | **Done** |
| `GameScene.startChallengeRun` | **Done** |
| Run-summary Daily / Weekly buttons + mastery line | **Done** |
| Record mastery on every finished receipt | **Done** |

### Slice C details

| Deliverable | Status |
| --- | --- |
| `unlockables.json` (cosmetic / radio / weather / motif) | **Done** |
| Mastery-gated auto-grant on `record` | **Done** |
| Run-summary unlock count + new-unlock banner | **Done** |
| Runtime presentation wiring of cosmetics | Later (assets) |

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
- unlockable presentation ids (cosmetics, radio sets, weather packs, audio motifs)

App layer owns `UserDefaults` persistence (`MasteryProgressStore`).

## Non-goals

- Global permanent damage/health inflation  
- Closing device #3 from sim green  
- Full cosmetics marketplace / monetization  

## Next

- Wire presentationId cosmetics into SpriteKit/HUD when assets exist  
- Expand mutator palette (weather labels, radio sets) without stat inflation  
- Operator device #3 / TF launch lane (parallel) 
