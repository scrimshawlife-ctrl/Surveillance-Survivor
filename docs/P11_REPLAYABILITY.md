# P11 — Replayability and mastery program

```yaml
version: 1.3.0
status: slice_d_in_progress
last_updated: 2026-07-25
slice: D
tip_base: 8920bac
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
| C | Unlockables catalog + mastery auto-grant (presentation only) | **Done** (#76) |
| D | Presentation wiring for unlock cosmetics / radio / weather | **This PR** |

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

### Slice D details

| Deliverable | Status |
| --- | --- |
| `UnlockPresentationResolver` profile | **Done** |
| GameScene unlock presentation publish | **Done** |
| HUD radio / weather / trail labels | **Done** |
| Redaction vignette overlay | **Done** |
| Motif id registered on audio bank when unlocked | **Done** (silent until stems) |

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
Presentation resolves via `UnlockPresentationResolver` into HUD/overlays only.

## Non-goals

- Global permanent damage/health inflation  
- Closing device #3 from sim green  
- Full cosmetics marketplace / monetization  

## Next

- ~~SpriteKit lot-ghost trail~~ (soft afterimages, this PR)  
- ~~Expand mutator palette (radio / weather / motif labels)~~ (this PR)  
- Floor remediation from [`HALLMARK_FLOOR_AUDIT.md`](HALLMARK_FLOOR_AUDIT.md) (optional)  
- Operator device #3 / TF launch lane (parallel)  
