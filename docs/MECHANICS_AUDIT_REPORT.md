# Gameplay mechanics audit — 2026-07-26

**Tip audited:** `2c63280` (main)  
**Fixes branch:** unlock-effect apply + swept projectile hits + spawn clearance  
**Gates:** package tests 176 pass; weapon-vfx/audio/art-qa/version PASS  
**ship_gate:** `ART_EVIDENCE_INSUFFICIENT` (device ART unchanged)

## Authority matrix

| Mechanic | Canonical source | Runtime owner | Projection owner | Test coverage | Status |
| --- | --- | --- | --- | --- | --- |
| Fixed-step 60 Hz sim | AGENTS.md, Simulation | SurveillanceCore | SpriteKit frame | `deterministicRunsMatch` | IMPLEMENTED_AND_VERIFIED |
| Seeded RNG | DeterministicRNG | SurveillanceCore | — | seed replay tests | IMPLEMENTED_AND_VERIFIED |
| Player movement / stick | BossCatalog speed, PlayerInput | SurveillanceCore | GameScene stick | movement/bounds/slide tests | IMPLEMENTED_AND_VERIFIED |
| LPR scan cones + rotation | EnemyCatalog, SuspicionCatalog | SurveillanceCore | EntityProjector | sensor contact / heading tests | IMPLEMENTED_AND_VERIFIED |
| Suspicion 0…5 tiers | suspicion.json | SurveillanceCore | HUD CompactSuspicionMeter | escalate + tier tests | IMPLEMENTED_AND_VERIFIED |
| Kinetic countermeasure | weapons.json + WEAPON_SYSTEM_DESIGN | Simulation.fireActiveWeapons | projectile sprites | fire + hit tests | IMPLEMENTED_AND_VERIFIED |
| Redaction / spoof / FOIA / mirror / flood | weapons.json | Simulation payloads | VFX / deployables | per-weapon unit tests | IMPLEMENTED_AND_VERIFIED |
| Multi-shot / pierce / homing upgrades | WEAPON_SYSTEM_DESIGN | — | — | — | DOCUMENTED_ONLY (not in upgrades.json) |
| Data shards + 3-choice draft | WEAPON_SYSTEM_DESIGN #1 | requestUpgradeOffer / queue | UpgradeDraftOverlay | multi-kill queue tests | IMPLEMENTED_AND_VERIFIED |
| addsWeapon first-pick effects | upgrades.json | applyUpgradeSelection | loadout HUD | **fixed this audit** | IMPLEMENTED_AND_VERIFIED |
| Build synergies (explicit) | build_synergies.json | BuildEngine | HUD/receipt | synergy receipt tests | IMPLEMENTED_AND_VERIFIED |
| Design synergies (Spoofer+Redaction etc.) | WEAPON_SYSTEM_DESIGN | tag engine only | — | — | PARTIAL (tag families, not pairwise weapon scripts) |
| Ten-city profiles | districts.json | DistrictCatalog | city art | district matrix suite | IMPLEMENTED_AND_VERIFIED |
| Boss + Blind Spot extract | bosses.json | activateShiftManager / resolveExtraction | boss/extract nodes | forced extraction suite | IMPLEMENTED_AND_VERIFIED |
| Pause / draft freezes sim | GameScene.update | GameScene (no step) | overlays | lifecycle tests | IMPLEMENTED_AND_VERIFIED |
| Projectile continuous collision | combat design | resolveProjectileHits | — | **fixed this audit** | IMPLEMENTED_AND_VERIFIED |
| Physical ART / extract log | RELEASE_READINESS | operator | — | DEVICE_TEST_LOG | NOT_COMPUTABLE (device) |
| Product audio stems | AUDIO_* | owner license | AudioCuePlayer | catalog only | DOCUMENTED_ONLY (binaries missing) |

## Findings repaired this pass

| ID | Severity | Issue | Fix |
| --- | --- | --- | --- |
| M-01 | High | `addsWeapon` unlocks appended baseline weapons **without** applying the upgrade card’s `effect` (cadence/damage/etc. lost on first pick of redaction/identity/FOIA/mirror/flood) | Apply `effect` when appending the new `WeaponSystem` |
| M-02 | High | Discrete projectile sample could **tunnel** through thin targets at high `projectileSpeed` | Swept segment–circle hit test reconstructing pre-step origin |
| M-03 | Medium | Signal flood FX marker always expired at +18 ticks while disable window was longer | Marker lifetime tracks payload duration (capped) |
| M-04 | Low | Guard spawn after world clamp could sit inside player clearance | Push spawn along ray to min clearance (no extra RNG) |

## Deferred / non-goals (honest)

| Item | Reason |
| --- | --- |
| Multi-shot / pierce / homing | Design aspirational; no content rows — would expand scope |
| Pairwise weapon synergies as unique scripts | Implemented via explicit tag/threshold engine, not 1:1 named pairs |
| Balance retune of Suspicion/city DPS | No A/B evidence package this pass; existing suite green |
| Physical-device ART ship gate | Operator evidence required |
| ElevenLabs audio binaries | Owner license |

## Validation evidence

```text
make test                 → 176 tests pass (was 175 + swept-hit case)
make weapon-vfx-check     → PASS
make audio-check          → PASS
make art-qa-check         → PASS ART_EVIDENCE_INSUFFICIENT
```

New/updated tests:

* `selectingRedactionOrdinanceAddsItToTheBoundedLoadout` asserts first-pick cadence reduction
* `highSpeedProjectileCannotTunnelThroughCameraPole` drives real `Simulation.step` with a tunneling trajectory

## Architecture integrity

No gameplay truth moved into SpriteKit, wall-clock timers, or SwiftUI. Collision remains simulation-owned.
