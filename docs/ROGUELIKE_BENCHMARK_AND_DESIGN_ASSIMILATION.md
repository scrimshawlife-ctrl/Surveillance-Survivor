# Roguelike benchmark and design assimilation

```yaml
version: 1.0.0
status: approved
last_updated: 2026-07-26
supersedes: null
superseded_by: null
authority_scope: approved P8–P11 systemic roguelike design assimilation program
```

**Decision:** approved for planning on 2026-07-24.

**Authority:** this document defines the product-design expansion program derived from comparison with leading iPhone roguelikes. It does not override launch evidence gates in `ROADMAP.md`, `RELEASE_READINESS.md`, or `ART_PRODUCTION_READINESS.md`.

## Objective

Advance Surveillance Survivor from a competent survivor-like vertical slice into a distinctive systemic roguelite built around:

- a living, destructible surveillance city;
- Suspicion as a deterministic encounter director;
- strange combinatorial countermeasure builds;
- memorable run-generated stories;
- landmark-specific encounters and city identities;
- paranoid slapstick expressed through mechanics, audio, enemies, and environmental reactions.

## Benchmark set

| Reference | Primary lesson |
| --- | --- |
| Dead Cells | combat feel, animation, mastery |
| Vampire Survivors | pacing, escalation, build spectacle |
| Balatro | combinatorial synergies and replayability |
| Slay the Spire | decision density and legible tradeoffs |
| The Binding of Isaac | item interactions and run variance |
| Monster Train | layered build construction and meta systems |
| Dicey Dungeons | concentrated personality and readable rules |
| Downwell | mobile control economy and mechanical clarity |
| TMNT: Splintered Fate | premium mobile presentation reference |
| Endless Wander | mobile-first action controls and progression |

This is a design benchmark set, not a permanent App Store sales ranking.

## Assimilation rules

1. Preserve deterministic simulation authority.
2. Prefer interacting systems over isolated content quantity.
3. Every added system must produce readable player consequences.
4. Meta-progression unlocks verbs, modifiers, archetypes, and content rather than replacing skill with permanent stat inflation.
5. Each city changes rules, not only backgrounds and enemy skins.
6. Humor should be mechanically expressed wherever feasible.
7. Procedural variation remains seed-reproducible and receipt-observable.

## Approved epics

### E1 — Suspicion Director

Transform Suspicion `0...5` into a deterministic encounter-director input using explicit budgets, cooldowns, pressure windows, recent-event memory, district doctrine, and seed-derived selection.

The director may alter encounter composition, route pressure, checkpoint placement, response coordination, lockdown state, boss activation, and extraction constraints. It must not secretly modify player damage or enemy health.

### E2 — Dynamic City State

Create a district-state graph with infrastructure nodes and propagated consequences.

Initial node families:

- surveillance sensors;
- electrical power;
- communications and fiber;
- traffic control;
- access control and checkpoints;
- transit systems;
- civilian density and reporting pressure;
- emergency and contractor response.

Infrastructure disruption must create both opportunity and cost.

### E3 — Environmental Weaponization

Convert the environment from a decorative obstacle field into a systemic combat surface.

Candidate interactables include transformers, substations, traffic lights, parking gates, construction equipment, billboards, delivery robots, scooters, autonomous taxis, security vehicles, fiber cabinets, server trucks, hydrants, escalators, luggage systems, trains, sweepers, and garbage trucks.

Every interactable requires deterministic state, telegraph, collision behavior, consequence events, asset mapping, audio hooks, and a performance budget.

### E4 — Emergent Build Engine

Extend upgrades into a synergy graph based on tags, triggers, transforms, exclusions, thresholds, and evolutions.

Target families:

- signal disruption;
- social camouflage;
- bureaucratic warfare;
- physical disruption;
- mobility and vehicle modification;
- decoys and identity multiplication;
- infrastructure parasitism;
- high-Suspicion risk builds.

Builds must alter behavior, not merely increase damage.

### E5 — Enemy Coordination Graph

Model readable and interruptible coordination chains such as:

```text
sensor detects
→ dispatcher validates
→ patrol reroutes
→ blocker denies path
→ capture unit closes
```

Destroying, confusing, spoofing, or jurisdictionally separating a link must change the chain.

### E6 — Run Story Compiler

Record authoritative story facts and compress them into end-of-run summaries, shareable receipts, and narrative callbacks.

The compiler may describe only events present in the run receipt.

### E7 — Landmark Encounter Framework

Each landmark encounter defines:

- landmark ID and city relation;
- topology grammar;
- unique interactables;
- hazard schedule;
- enemy and faction modifiers;
- Suspicion Director modifiers;
- boss hooks;
- audio motif and ambience hooks;
- art projection package;
- deterministic validation fixture.

Landmarks must influence play rather than serve as static visual references.

### E8 — District Personality Contract

Each district defines exclusive or weighted lighting, weather, traversal grammar, infrastructure topology, civilian behavior, hazards, enemy composition, upgrade weighting, radio language, music, ambience, and satirical policy modifiers.

A city is incomplete when its identity exists only through textures.

### E9 — Adaptive Audio Director

Drive bundled, approved audio from Suspicion, district state, coordination state, landmark state, boss phase, and extraction pressure.

Planned surfaces:

- layered music intensity;
- scanner chatter;
- event-reactive emergency broadcasts;
- civilian and crowd responses;
- infrastructure hum, outage, and restoration states;
- city and landmark motifs;
- interruption-safe voice queues with repetition control.

No runtime generative dependency is required.

### E10 — Replayability and skill-preserving meta

Add seeded daily challenges, weekly city variants, policy mutators, challenge contracts, unlockable gadgets, archetypes, factions, weather, events, bosses, radio sets, cosmetics, and mastery records.

Avoid global permanent damage or health inflation as the primary progression model.

## Runtime contracts

Planned `RunState` extensions:

```yaml
RunState:
  district_state
  suspicion_director_state
  enemy_coordination_state
  run_story_facts
```

Planned content authorities:

- `infrastructure_nodes.json`
- `interactables.json`
- `director_rules.json`
- `coordination_graphs.json`
- `landmark_encounters.json`
- `district_personality.json`
- `story_fact_rules.json`

## Delivery phases

### A — Architecture and schemas

- Extend runtime state and domain events.
- Define JSON schemas and validators.
- Add deterministic fixtures and receipt fields.
- Establish performance budgets and fallback behavior.

### B — One-district proof

Implement the full stack in Big-Box Parking Expanse:

- three infrastructure node families;
- six interactables;
- one coordination chain;
- one landmark-scale set piece;
- twelve behavioral upgrades and four multi-system evolutions;
- Suspicion Director budgets;
- adaptive audio hooks;
- run-story summary.

### C — Ten-city projection

Project validated contracts across the campaign. Each city must gain distinct systemic rules before additional decorative content is prioritized.

### D — Replayability and polish

Add challenge rotations, expanded build pools, advanced animation, multi-stage landmark encounters, city audio packages, and balance passes.

## Acceptance gates

- identical seed and input trace reproduce director choices and city-state outcomes;
- no hidden difficulty scaling;
- every systemic consequence has a readable visual or audio signal;
- a full run generates a valid story receipt without invented events;
- at least three strategically distinct builds clear the proof district;
- infrastructure interactions create both benefits and costs;
- each coordination chain has at least two player counterplay points;
- city-specific systems remain inside physical-device performance budgets;
- device acceptance remains required for production claims.

## Implementation order

1. Suspicion Director contracts.
2. Dynamic City State.
3. Emergent Build Engine.
4. Enemy Coordination Graph.
5. Environmental Weaponization.
6. Adaptive Audio Director.
7. Run Story Compiler.
8. Landmark Encounter Framework.
9. District Personality projection.
10. Replayability systems.

## Scope boundary

These epics are approved roadmap additions, but they are not all TestFlight blockers. The first App Store candidate may ship after existing P2–P6 gates with a bounded subset while the larger systemic program proceeds through post-slice phases.