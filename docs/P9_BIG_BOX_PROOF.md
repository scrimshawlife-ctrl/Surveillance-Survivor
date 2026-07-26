# P9 — Big-Box Parking Expanse systems proof

```yaml
version: 1.0.2
status: in_progress
last_updated: 2026-07-26
district: wichita
title: The Panopticon of the Plains / Big-Box Parking Expanse
```

**Authority:** [`ROADMAP.md`](ROADMAP.md) P9 · assimilation E2/E3/E5/E6  
**Continuation:** [`CONTINUATION_PROMPT.md`](CONTINUATION_PROMPT.md)

## Proof checklist

| # | Requirement | Status |
| ---: | --- | --- |
| 1 | ≥3 infrastructure node families | **Met** — Wichita graph (power, fiber, sensors, access, civilian, emergency) |
| 2 | 6 deterministic environmental interactables | **Core + app wired** — `interactables.json` + `PlayerInput.activateUtility` + `activate-utility` chrome (device evidence still open) |
| 3 | Coordination chain ≥2 counterplay | **Met** — `lot_capture_cascade` |
| 4 | Landmark-scale set piece | **Slice A** — `landmark_encounters.json` + runtime levers + receipt v9 |
| 5 | 12 upgrades + 4 evolutions | **Met** — content catalogs |
| 6 | Suspicion Director budgets | **Met** — director_rules |
| 7 | Adaptive audio hooks | Partial — event map only; stems missing |
| 8 | Authoritative run story summary | **Met** — story_fact_rules / receipt |
| 9 | Three distinct clearing builds | **Slice A** — `clearing_builds.json` + BuildEngine proofs |
| 10 | Physical-device performance receipt | Operator |

## Landmark contract (slice A)

- Content: `Sources/SurveillanceCore/Resources/Content/landmark_encounters.json`
- Engine: `LandmarkEncounter.swift` — enter/exit/hazard; **pressure levers only**
- Levers: guard target delta, observation bonus, spawn interval multiplier, suspicion nudge
- Gate: `make landmark-check`
- Receipt: `landmarkEvents` + `landmarkEncounter` (schema **v9**)

## Clearing builds (slice A)

| id | strategy | expected synergies |
| --- | --- | --- |
| `quiet_ghost` | evasion_camouflage | quietCorridor, identityMultiplex |
| `paper_bureaucracy` | foia_process | paperTrailCascade |
| `flood_risk` | high_risk_signal | floodRiskBargain |

- Gate: `make clearing-builds-check`
- Receipt: `matchedClearingBuildId` when selected upgrades cover a proof set

## Interactables — core vs app wiring

| Layer | Status |
| --- | --- |
| Content | `interactables.json` — six Wichita defs, linked infrastructure nodes |
| Engine | `InteractableEngine.tryActivate` when `PlayerInput.activateUtility == true` |
| Simulation | `Simulation.evaluateInteractables` → city-state hits + receipt samples |
| Tests | `InteractableTests` drive `activateUtility: true` directly |
| **App / GameScene** | **Wired** — `RootView` `activate-utility` button → `GameScene.requestUtilityActivation()` → `PlayerInput.activateUtility` on the next fixed step |

Physical-iPhone reachability evidence for the utility control remains an open Hallmark/device gate.

Related input contract: `autoFireEnabled` is honored in `Simulation.step` and forced `false` under launch arg `-UITesting` so AFK kinetic fire cannot cover chrome with upgrade drafts. It is not a user-facing settings toggle.

## Non-goals

- Ten-city systemic projection (P10) — see [`P10_CITY_PROJECTION.md`](P10_CITY_PROJECTION.md)
- Closing #3 from simulator evidence
- Invented narrative or hidden stat scaling
- Physical-device evidence for utility control reachability / Hallmark thumb conflict
