# WP2A Countermeasure Implementation Receipt

## Outcome

The placeholder automatic dart has been generalized into deterministic countermeasure-system authority under `Sources/SurveillanceCore`.

## Implemented

- `WeaponID`
- `WeaponSystem`
- `TargetingRule`
- `CountermeasurePayload`
- authoritative `RunState.activeWeapons`
- one-to-four active weapon execution boundary
- stable distance-plus-entity-ID target ordering
- typed projectile source and payload metadata
- explicit `weaponFired` and `countermeasureHit` events
- bounded projectile count
- baseline Kinetic Countermeasure preserving the prior 15-tick cadence, 1,000-unit range, 600-unit speed, 5-unit radius, and 15 damage

## Verification coverage

- canonical baseline loadout
- exact firing cadence
- typed projectile metadata
- explicit hit events
- state and event replay equivalence
- projectile-cap enforcement
- pre-existing camera-destruction regression

## Deliberately deferred

- Redaction Ordinance
- Identity Transponder
- FOIA Swarm
- Mirror Array
- Signal Flood
- upgrade-choice UI
- manual aim
- art dependency

## Required merge gate

- `swift test`
- XcodeGen project generation
- iOS Simulator build
- CI green on the dedicated WP2A pull request
