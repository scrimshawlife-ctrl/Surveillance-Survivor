# WP2B — Redaction Ordinance and Identity Transponder Receipt

## Status

`IMPLEMENTED_PENDING_CI_AND_DEVICE_VALIDATION`

## Parent authority

- `docs/WEAPON_SYSTEM_DESIGN.md`
- PR #5 — deterministic countermeasure weapon authority
- Notion countermeasure specification: https://app.notion.com/p/3a53e8ba2f5c811e849dcfa7d95aa5ff

## Implemented contracts

### Redaction Ordinance

```yaml
weapon_id: redactionOrdinance
cadence_ticks: 90
range: 850
projectile_speed: 420
projectile_radius: 7
payload:
  disable_sensor_ticks: 180
targeting: nearest_camera
suspicion_profile: low
```

Effects:

- applies deterministic sensor-disable duration to camera poles;
- disabled cameras stop rotating;
- disabled cameras cannot generate scan contacts or sensor pressure;
- repeated applications use `max(current, incoming)` rather than additive stacking.

### Identity Transponder

```yaml
weapon_id: identityTransponder
cadence_ticks: 120
range: 760
projectile_speed: 360
projectile_radius: 8
payload:
  spoof_identity_ticks: 150
  suspicion_reduction: 4
targeting: nearest_camera_then_threat
suspicion_profile: low
```

Effects:

- applies deterministic identity-spoof duration to cameras, guards, or bosses;
- spoofed cameras cannot generate scan contact;
- spoofed guards stop pursuit while the status remains active;
- successful spoof impact reduces Suspicion without crossing below zero;
- repeated applications use `max(current, incoming)` duration semantics.

## State authority

`Entity` now owns bounded status counters:

- `sensorDisabledTicks`
- `identitySpoofedTicks`

Both counters decrement once per fixed simulation step. SpriteKit remains projection-only.

## Loadout injection

`RunState` and `Simulation` accept an explicit active-weapon list for deterministic testing and future upgrade application. Loadouts remain capped at four active systems.

## Events

Added `RunEvent.Kind.statusApplied` for deterministic feedback routing. Status application remains separate from kinetic hit events.

## Tests added

- Redaction applies a live camera disable.
- Identity Transponder spoofs a valid target.
- Loadouts truncate deterministically to four systems.
- Combined Redaction/Spoofer state and event streams replay exactly.
- Existing kinetic tests remain unchanged.

## Explicit exclusions

- no upgrade-selection UI;
- no persistent redaction field;
- no decoy target entity;
- no boss-specific immunity rules;
- no visual texture dependency;
- no audio or haptic implementation;
- no FOIA Swarm, Mirror Array, or Signal Flood.

## Required merge gate

- Swift package tests pass;
- XcodeGen project generation passes;
- simulator build passes;
- physical-iPhone readability and performance remain a later acceptance requirement.
