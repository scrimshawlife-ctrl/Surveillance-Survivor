# Mechanics balance matrix — tip `fcc0537`

**As of:** 2026-07-26  
**Baseline tip:** `2c63280`  
**Fix tips:** `146001c` (#105), `fcc0537` (#107)  
**Policy:** No broad rebalance. Values are **catalog + sim truth** after M-01–M-04.  
**Companion:** [`MECHANICS_FINDINGS.json`](MECHANICS_FINDINGS.json) · [`MECHANICS_REPAIR_RECEIPT.md`](MECHANICS_REPAIR_RECEIPT.md) · [`MECHANICS_AUDIT_REPORT.md`](MECHANICS_AUDIT_REPORT.md)

---

## Authority snapshot

| Layer | Owner | Notes |
| --- | --- | --- |
| Combat / progression truth | `SurveillanceCore` | Fixed-step 1/60, seeded RNG, hits, upgrades, receipts |
| Projection | SpriteKit `Game/` | No collision / damage authority |
| Shell / HUD | SwiftUI `App/` | Pause freezes `GameScene` steps; drafts block hitch catch-up |
| Content | `Resources/Content/*.json` | weapons, upgrades, districts, suspicion, synergies |

---

## Combat bounds (hard)

| Limit | Value | Source |
| --- | ---: | --- |
| Active weapons | 4 | `CombatLimits.maximumActiveWeapons` |
| Ordinary projectiles | 96 | `CombatLimits.maximumProjectiles` |
| Persistent deployables | 8 | `CombatLimits.maximumPersistentDeployables` |
| Fixed step | 1/60 s | `Simulation.fixedStep` |
| Player speed | 210 | `bosses.json` |

---

## Six countermeasures (baseline + M-01 unlock cadence)

| Weapon | Base cadence | After unlock card | Range | Payload | Targeting |
| --- | ---: | ---: | ---: | --- | --- |
| Kinetic | 15 | n/a (starter) | 420 | damage 15 | nearestCameraThenThreat |
| Redaction | 90 | **80** (red −10, min 30) | 800 | disable 180t | nearestCamera |
| Identity Transponder | 120 | **108** (−12, min 45) | 700 | spoof 240t @ 0.25 | nearestCamera |
| FOIA Swarm | 75 | **67** (−8, min 30) | 700 | processing DoT | nearestThreat |
| Mirror Array | 180 | **160** (−20, min 90) | 0 | reflect deploy | deploy |
| Signal Flood | 300 | **270** (−30, min 150) | 360 | r=360, spike 10, disable 150t | area |

*Unlock formula (M-01): `max(minimumCadence, baseline − cadenceReduction)` when `addsWeapon` first pick applies `UpgradeEffect`.*

### Projectile fairness (M-02 @ `fcc0537`)

| Rule | Implementation |
| --- | --- |
| Mid-flight tunnel | Continuous segment–circle via `firstIntersectionT` |
| Same-tick fire | No reverse phantom — origin only if projectile moved this step |
| Multi-target | Minimum positive t along path; tie-break by entity id |

---

## Upgrade availability (loadout stages)

| Stage | Loadout | Typical eligible | Blocked |
| --- | --- | --- | --- |
| Open | 1 kinetic | kinetic stacks, lowProfileRouting, unlock cards if slots free | evolutions (need weapon L≥3) |
| Mid | 2–3 | stack + remaining unlocks | evolutions until L3 |
| Full | 4 | stack only | new unlock when weapon absent and slots full |
| Evolution | weapon L≥3 | indictment / blackout / ghostProtocol / paperStorm once | already-owned evolution |

**Deferred content (not retuned):** multi-shot / pierce / homing — design prose only (`M-D01`).

---

## Suspicion economy

| Lever | Behavior | Source |
| --- | --- | --- |
| Sensor contact | pressure × city × softener | `updateSuspicion` + `suspicion.json` |
| Guard pressure | per-guard when present | suspicion.json |
| No-contact recovery | when contactWeight == 0 | + buildEngine recovery boost |
| Signal Flood | discrete spike on fire | weapons.json |
| Spoof | multiplies camera contribution | sensorSpoof |
| Redaction | inactive sensor → no contact weight | `isSensorActive` |

**Assessment:** Viable risk/reward under existing suites; **no** global pressure retune this pass.

---

## City differentiation (`districts.json` simulation profiles)

| City | Lvl | Pressure | Boss HP | Boss contact | Guard max | Start sensors | Signature |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Wichita | 1 | 1.00 | 1.00 | 1.00 | 40 | 4 | aircraft / zoning |
| Louisville | 2 | 1.06 | 1.15 | 1.08 | 44 | 4 | hidden cams / redaction |
| Tulsa | 3 | 1.12 | 1.30 | 1.16 | 48 | 4 | oil as data mining |
| Dayton | 4 | 1.18 | 1.45 | 1.24 | 52 | 4 | chained gateways |
| Oakland | 5 | 1.25 | 1.60 | 1.32 | 56 | 5 | borrowed jurisdiction |
| San Francisco | 6 | 1.32 | 1.80 | 1.42 | 60 | 4 | fog sensors |
| Columbus | 7 | 1.40 | 2.00 | 1.52 | 64 | 5 | jurisdiction split |
| New York City | 8 | 1.50 | 2.30 | 1.66 | 70 | 6 | borough phases |
| Los Angeles | 9 | 1.62 | 2.60 | 1.80 | 76 | 6 | public–private nets |
| Atlanta | 10 | 1.75 | 3.00 | 2.00 | 84 | 7 | nationwide convergence |

Multi-axis escalation (pressure + boss + guard ceiling + sensor count), not a single scalar.

---

## Synergies

| Design pair | Implementation | Status |
| --- | --- | --- |
| Named Spoofer+Redaction / FOIA+Kinetic / etc. | Tag/threshold `build_synergies.json` | PARTIAL (`M-D02`) |
| quietCorridor / redactionLattice / paperTrailCascade / identityMultiplex | Explicit behaviors | IMPLEMENTED_AND_VERIFIED |

---

## Tuning changes this audit

| Parameter | Before | After | Rationale | Tests |
| --- | --- | --- | --- | --- |
| Unlock weapon stats | baseline only | baseline + card effect | M-01 honesty | redaction cadence |
| Projectile hit geometry | point / reverse phantom / first-index | pre-move origin + min-t | M-02 fairness | tunnel + phantom + nearer |
| Signal flood marker ticks | hardcoded 18 | `min(duration, 180)` | M-03 readability | marker expiry test |
| Guard spawn | clamp only | clamp + clearance push | M-04 fairness | clearance test |

**No** player HP, enemy HP, or global damage multipliers changed. **No** save/schema version bump.

---

## Remaining CONFIRMED P0 / P1 (outside fixed M-01/M-02)

| ID | Sev | Status | Notes |
| --- | --- | --- | --- |
| — | P0 | **None open in code** after #101–#103, #105, #107 | Package + sim suites green |
| M-D03 | P1 | **DEFERRED — operator** | Physical ART + extract COPY RECEIPT; `ART_EVIDENCE_INSUFFICIENT` |
| M-D04 | P1 | **DEFERRED — owner** | Live privacy/support URLs + release screenshots |
| M-D05 | P1 | **REPOSITORY COMPLETE; DEVICE/OWNER OPEN** | 68/68 integrated; rights confirmation and physical-device listening remain |

No additional **CONFIRMED code** P0/P1 remaining that is agent-repairable without device/owner input or scope expansion.
