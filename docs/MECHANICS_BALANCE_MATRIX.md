# Mechanics balance matrix — audit 2026-07-26

**Policy:** No broad rebalance this pass. Values below are **catalog truth** after mechanical repairs (M-01–M-04). Tuning rows marked `unchanged` were measured as coherent under existing deterministic suites.

## Combat bounds (hard)

| Limit | Value | Source |
| --- | ---: | --- |
| Active weapons | 4 | `CombatLimits.maximumActiveWeapons` |
| Ordinary projectiles | 96 | `CombatLimits.maximumProjectiles` |
| Persistent deployables | 8 | `CombatLimits.maximumPersistentDeployables` |
| Fixed step | 1/60 s | `Simulation.fixedStep` |
| Player speed | 210 | `bosses.json` |

## Six countermeasures (baseline catalog)

| Weapon | Cadence (ticks) | Range | Payload | Targeting | Notes after M-01 |
| --- | ---: | ---: | --- | --- | --- |
| Kinetic Countermeasure | 15 | 420 | damage 15 | nearestCameraThenThreat | Workhorse; speed upgrades no longer tunnel (M-02) |
| Redaction Ordinance | 90 → **80** on first unlock card | 800 | disable 180t | nearestCamera | Unlock now applies cadenceReduction 10 / min 30 |
| Identity Transponder | 120 → **108** on unlock | 700 | spoof 240t @ 0.25 | nearestCamera | Unlock applies cadenceReduction 12 / min 45 |
| FOIA Swarm | 75 → **67** on unlock | 700 | processing DoT | nearestThreat | Unlock applies cadenceReduction 8 / min 30 |
| Mirror Array | 180 → **160** on unlock | 0 | reflect deploy | deploy | Unlock applies cadenceReduction 20 / min 90 |
| Signal Flood | 300 → **270** on unlock | 360 | radius 360, spike 10, disable 150t | area | Unlock applies cadenceReduction 30 / min 150; FX window M-03 |

*Unlock cadence after M-01 = `max(minimumCadence, baseline - cadenceReduction)` from `upgrades.json`.*

## Upgrade availability (loadout stages)

| Stage | Loadout size | Typical eligible | Blocked |
| --- | ---: | --- | --- |
| Open | 1 (kinetic) | kinetic upgrades, lowProfileRouting, any addsWeapon if slots free | evolutions (need weapon L≥3) |
| Mid | 2–3 | stack weapon upgrades + remaining unlocks | evolutions until L3 |
| Full | 4 | stack only; addsWeapon false once slots full | new unlocks when `activeWeapons.count == 4` and weapon absent |
| Evolution | weapon L≥3 | indictment / blackout / ghostProtocol / paperStorm once | already-owned evolution id |

## Suspicion economy (catalog)

| Lever | Behavior | Source |
| --- | --- | --- |
| Sensor contact | pressure × city × softener | `Simulation.updateSuspicion` + `suspicion.json` |
| Guard pressure | per-guard rate when present | suspicion.json |
| No-contact recovery | when contactWeight == 0 | + buildEngine.suspicionRecoveryBoost |
| Signal Flood | discrete +spike on fire | weapons.json suspicionSpike |
| Spoof | multiplies camera contribution | sensorSpoof.suspicionMultiplier |
| Redaction | sensor inactive → no contact weight | isSensorActive |

**Assessment:** Risk/reward remains viable without retune — spoof/recovery vs flood spikes tested in suite. No P0 stacking lock observed under 3600-tick escalate test.

## City differentiation (simulation profile)

| City | Level | Pressure | Boss HP | Boss contact | Guard max | Start sensors | Signature (authored) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Wichita | 1 | 1.00 | 1.00 | 1.00 | 40 | 4 | aircraft scanners / zoning |
| Louisville | 2 | 1.06 | 1.15 | 1.08 | 44 | 4 | hidden cameras / redaction |
| Tulsa | 3 | 1.12 | 1.30 | 1.16 | 48 | 4 | oil as data mining |
| Dayton | 4 | 1.18 | 1.45 | 1.24 | 52 | 4 | chained gateways |
| Oakland | 5 | 1.25 | 1.60 | 1.32 | 56 | 5 | borrowed jurisdiction |
| San Francisco | 6 | 1.32 | 1.80 | 1.42 | 60 | 4 | fog sensors |
| Columbus | 7 | 1.40 | 2.00 | 1.52 | 64 | 5 | jurisdiction split |
| New York City | 8 | 1.50 | 2.30 | 1.66 | 70 | 6 | borough phases |
| Los Angeles | 9 | 1.62 | 2.60 | 1.80 | 76 | 6 | public–private nets |
| Atlanta | 10 | 1.75 | 3.00 | 2.00 | 84 | 7 | nationwide convergence |

Escalation is multi-axis (pressure + boss + guard ceiling + sensor count), not a single scalar.

## Synergy engine vs design pairs

| Design pair (WEAPON_SYSTEM_DESIGN) | Implementation | Status |
| --- | --- | --- |
| Spoofer + Redaction | Tags socialCamouflage / signalDisruption / infrastructure | PARTIAL via tag thresholds |
| FOIA + Kinetic | bureaucraticWarfare + physicalDisruption tags | PARTIAL |
| Mirror + Piercing Kinetic | physicalDisruption tags; pierce not contented | PARTIAL / DOCUMENTED_ONLY pierce |
| Signal Flood + FOIA | highSuspicionRisk + bureaucraticWarfare | PARTIAL |
| Explicit quietCorridor / redactionLattice / paperTrailCascade / identityMultiplex | `build_synergies.json` | IMPLEMENTED_AND_VERIFIED |

## Tuning changes this audit

| Parameter | Old | New | Rationale | Suite impact |
| --- | --- | --- | --- | --- |
| Unlock weapon stats | baseline only | baseline + card effect | M-01 contract honesty | redaction cadence test |
| Projectile hit geometry | point sample | swept segment | M-02 fairness | tunnel test |
| Signal flood marker ticks | 18 | min(duration, 180) | M-03 readability | existing flood test |
| Guard spawn position | clamp only | clamp + clearance push | M-04 fairness | determinism preserved |

**No** player HP, enemy HP, or global damage multipliers were changed.
