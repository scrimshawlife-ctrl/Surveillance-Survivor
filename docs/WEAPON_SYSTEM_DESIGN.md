# Surveillance Survivor — Countermeasure Weapon System & Upgrade Architecture

**Status:** canonical design authority  
**Platform:** iPhone-first  
**Runtime authority:** `Sources/SurveillanceCore`  
**Projection:** SpriteKit + SwiftUI  
**Version:** 1.0

## Purpose

This document defines the deterministic combat, countermeasure, projectile, status-effect, upgrade, and weapon-synergy architecture for **Surveillance Survivor**.

Weapons are not conventional firearms. They are absurd anti-surveillance countermeasures that damage, disable, spoof, redirect, reflect, or bureaucratically overload the grid.

## Design principles

1. **Grid-breaking first.** Cameras are the primary progression target because destroying or confusing them yields Data Shards and upgrade opportunities.
2. **Suspicion is a resource and a risk.** Aggressive tools accelerate escalation and rewards; stealth tools preserve control and reduce pressure.
3. **Strange synergies are mandatory.** Builds should emerge from explicit cross-weapon interactions, not isolated stat increases.
4. **Simulation authority is absolute.** Targeting, cadence, hits, effects, upgrades, and randomness execute in the fixed-step Swift core.
5. **iPhone readability matters.** Strong silhouettes, high contrast, bounded counts, and collision independent of artwork.
6. **Satire is mechanical.** Every countermeasure should roast procurement, bureaucracy, jurisdiction games, surveillance theater, or techno-solutionism.
7. **Loadouts remain bounded.** The vertical slice supports one to four active countermeasures.

## Existing baseline

The current simulation already provides:

- player, camera pole, guard, projectile, boss, and extraction entities;
- fixed-step automatic fire;
- nearest-camera targeting;
- projectile movement and contact damage;
- rotating camera scan cones;
- sensor-driven Suspicion;
- deterministic guard pursuit and spawning;
- camera destruction and Data Shard scaffolding.

The current automatic kinetic dart becomes **Kinetic Countermeasure level 1**.

## Canonical runtime model

```swift
public struct WeaponSystem: Codable, Equatable, Sendable {
    public let id: WeaponID
    public var level: Int
    public var cadenceTicks: Int
    public var cooldownTicks: Int
    public var targeting: TargetingRule
    public var payload: CountermeasurePayload
    public var projectile: ProjectileProfile?
    public var modifiers: WeaponModifiers
}
```

```swift
public enum WeaponID: String, Codable, CaseIterable, Sendable {
    case kineticCountermeasure
    case redactionOrdinance
    case identityTransponder
    case foiaSwarm
    case mirrorArray
    case signalFlood
}
```

```swift
public enum TargetingRule: Codable, Equatable, Sendable {
    case nearestCamera(maxRange: Double)
    case nearestThreat(maxRange: Double)
    case cameraThenThreat(maxRange: Double)
    case randomVisibleTarget(maxRange: Double)
    case areaAroundPlayer(radius: Double)
    case deployAtPlayer
}
```

```swift
public enum CountermeasurePayload: Codable, Equatable, Sendable {
    case damage(amount: Double)
    case disableSensor(durationTicks: Int, coneScale: Double)
    case spoof(durationTicks: Int, suspicionMultiplier: Double)
    case processing(durationTicks: Int, slowMultiplier: Double, damagePerTick: Double)
    case reflect(durationTicks: Int, damageMultiplier: Double)
    case signalFlood(radius: Double, durationTicks: Int, suspicionSpike: Double)
}
```

`RunState` owns active weapons, weapon modifiers, status effects, pending upgrade offers, Data Shards, upgrade history, and bounded projectile/deployable counts.

## Fixed-step weapon pipeline

1. Read player input.
2. Advance weapon cooldowns.
3. Select deterministic targets.
4. Spawn typed projectiles or deployables.
5. Move entities and projectiles.
6. Resolve projectile contacts.
7. Apply payloads and statuses.
8. Resolve deaths and camera destruction.
9. Award Data Shards.
10. Generate deterministic upgrade offers.
11. Evaluate camera contacts and Suspicion.
12. Emit `RunEvent` receipts.

SpriteKit must not own hit detection or outcome-changing randomness.

## MVP countermeasure roster

### Kinetic Countermeasure

Baseline workhorse for direct camera damage.

- nearest-camera targeting;
- threat fallback through upgrades;
- fast dart, 15 baseline damage;
- moderate Suspicion spike on destruction;
- upgrades: cadence, damage, piercing, homing, multi-shot, split targeting.

### Redaction Ordinance

Sensor denial and safe-zone creation.

- black-bar projectile or temporary field;
- narrows or disables camera cones;
- can slow or confuse guards;
- low-to-moderate Suspicion profile;
- upgrades: radius, duration, chaining, mobile field, permanent cone reduction.

### Plate Spoofer / Identity Transponder

Identity confusion and contact suppression.

- periodic pulse or decoy beacon;
- reduces camera contribution or clears lock;
- redirects guards toward deterministic false positions;
- low Suspicion profile;
- upgrades: radius, duration, persistent decoys, multi-pulse, elite susceptibility.

### FOIA / Paperwork Swarm

Crowd control and bureaucratic overload.

- seeking paper or clipboard entities;
- applies processing slow, delayed cadence, or damage over time;
- upgrades: swarm count, speed, stronger processing, chaining, paper-storm field.

### Mirror Array / Reflector Deploy

Defensive redirection and reflected damage.

- short-lived mirror deployable;
- reflects or disrupts beams and compatible projectiles;
- can damage or blind source cameras;
- upgrades: count, duration, mobility, amplified reflection, auto-deploy.

### Signal Flood / EMP Pulse

High-risk mass disable and escalation tool.

- area disable against cameras;
- large immediate Suspicion spike;
- designed for clusters, boss openings, and high-tier play;
- upgrades: radius, duration, chained pulses, targeted overload, residual jamming.

## Deferred concepts

- Violation Citation Launcher
- Golf Cart Hijack / Rogue Rover
- Jurisdiction Splitter Beacon
- Inflatable Ghost / Decoy Civilian
- Class Action Aura
- Procurement Freeze

These are candidates, not MVP commitments.

## Deterministic upgrade transaction

Each Data Shard offer presents three deterministic choices drawn from eligible definitions.

Choice types:

- add a new countermeasure;
- level an active countermeasure;
- select a behavior branch;
- add a global passive;
- unlock a cross-weapon synergy;
- accept a cursed high-power option with explicit Suspicion cost.

```swift
public struct UpgradeDefinition: Codable, Equatable, Sendable {
    public let id: UpgradeID
    public let rarity: UpgradeRarity
    public let eligibility: UpgradeEligibility
    public let mutation: UpgradeMutation
    public let tags: Set<UpgradeTag>
}
```

Offer generation must use run RNG only, reject ineligible terminal duplicates, produce materially distinct choices where possible, and record provenance in run receipts.

## Build archetypes

| Build | Countermeasures | Identity |
|---|---|---|
| Auditor / Gridbreaker | Kinetic + Signal Flood + Mirror | fast camera destruction and high shard density |
| Ghost / Untrackable | Spoofer + Redaction + Mirror | low contact and controlled extraction |
| Bureaucrat / Paper Pusher | FOIA + Redaction + Citation later | processing, control, systemic comedy |
| Chaos Agent / Suspicion Farmer | Signal Flood + aggressive Kinetic | deliberate tier acceleration and rapid power growth |

## Explicit synergies

- Spoofer + Redaction → untrackable kill zones.
- FOIA + Kinetic → processing increases kinetic damage.
- Mirror + Piercing Kinetic → reflected chain darts.
- Signal Flood + FOIA → disabled cameras attract accelerated swarm processing.
- Spoofer + FOIA → enemies process false targets.
- Redaction + Signal Flood → temporary safe pocket after an escalation spike.

Synergies must be data definitions, not hidden conditional coupling.

## Suspicion economy

Every weapon and upgrade declares one profile:

- **Stealth:** suppress contacts or increase decay.
- **Neutral:** ordinary damage with bounded escalation.
- **Aggressive:** increases Suspicion for faster clearing and rewards.
- **Cursed:** exceptional power paired with persistent pressure.

Both low-tier and high-tier builds must remain viable.

## City and boss resonance

Base weapons remain valid across every city. City modifiers alter context, not basic viability.

- Wichita: open lanes favor physical and piercing systems.
- San Francisco: fog and dense sensors favor spoofing and redaction.
- Columbus: interagency swarms favor processing and jurisdiction effects.
- Atlanta: linked networks favor flood, chaining, and node-severing mechanics.

All MVP weapons must contribute to bosses through damage, disable, phase opening, add control, survival, or extraction support.

## Performance budgets

- four active weapon systems maximum;
- 96 ordinary live projectiles maximum;
- 24 swarm agents maximum;
- eight persistent deployables maximum;
- bounded status list per entity;
- pooled projection nodes where practical;
- deterministic simulation remains complete even when effects are visually culled.

## Accessibility and feedback

- distinct shape and motion language; color is supplementary;
- haptic events for firing, disabling, destruction, upgrades, and tier escalation;
- reduced-flash alternatives for signal bursts;
- accessible labels for status and upgrades;
- collision geometry never derives from sprite pixels.

## Asset namespace additions

```swift
static let projectileKinetic = "projectile_kinetic"
static let projectileRedaction = "projectile_redaction"
static let deployIdentityTransponder = "deploy_identity_transponder"
static let swarmFOIA = "swarm_foia"
static let deployMirror = "deploy_mirror"
static let pulseSignalFlood = "pulse_signal_flood"
```

## Verification gates

Required deterministic tests:

- identical seed and input produce identical weapon state, projectiles, effects, offers, and events;
- exact cadence boundaries;
- stable target tie-breaking;
- payloads apply exactly once where specified;
- statuses expire on exact ticks;
- three-choice offers reproduce exactly;
- upgrade mutations preserve invariants;
- caps fail closed;
- pause/resume never duplicates fire or effects;
- every weapon contributes against representative boss states.

Required device evidence:

- combat remains readable on a landscape iPhone;
- effects remain distinguishable without color alone;
- sustained bounded density meets frame-time targets;
- haptics are discrete rather than continuous;
- virtual-stick response remains stable at maximum density.

## Delivery sequence

### WP2A — Generalized weapon authority

- add `WeaponSystem`, `WeaponID`, targeting, payloads, and loadout state;
- convert the current dart into Kinetic Countermeasure level 1;
- add typed projectile resolution and tests.

### WP2B — Stealth countermeasures

- implement Redaction Ordinance;
- implement Identity Transponder;
- integrate sensor statuses and Suspicion modifiers.

### WP3A — Upgrade transaction

- implement Data Shard collection and deterministic three-choice offers;
- implement weapon addition, leveling, and branches;
- add SwiftUI offer projection without moving authority outside the core.

### WP3B — Control and escalation

- implement FOIA Swarm;
- implement Mirror Array;
- implement Signal Flood;
- complete pooling and density validation.

### WP4 — Vertical-slice integration

- verify against the first district boss and Blind Spot extraction;
- tune low- and high-Suspicion build viability;
- publish simulator, physical-device, performance, and replay receipts.

## Explicit exclusions

- no inventory grid;
- no required manual aiming for ordinary attacks;
- no server-authored balance;
- no physics-engine authority over canonical hits;
- no unbounded projectile or swarm spawning;
- no city-exclusive weapon required for completion;
- no hidden synergy conditions outside data definitions.

## Notion authority

Canonical companion page: [Countermeasure Weapon System & Upgrade Architecture v1.0](https://app.notion.com/p/3a53e8ba2f5c811e849dcfa7d95aa5ff)
