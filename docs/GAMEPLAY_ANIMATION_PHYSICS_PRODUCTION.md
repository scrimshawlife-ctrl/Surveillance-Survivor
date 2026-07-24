# Surveillance Survivor — Gameplay Animation & Physics-Informed Presentation

**Authority:** presentation motion doctrine for landscape-iPhone SpriteKit.  
**Gameplay authority:** `Sources/SurveillanceCore` (unchanged by this document).  
**Weapon identity / still VFX:** [`WEAPON_VFX_ASSET_PRODUCTION.md`](WEAPON_VFX_ASSET_PRODUCTION.md) + [`WEAPON_VFX_ASSET_MANIFEST.json`](WEAPON_VFX_ASSET_MANIFEST.json).  
**Machine queue:** [`GAMEPLAY_ANIMATION_MANIFEST.json`](GAMEPLAY_ANIMATION_MANIFEST.json).  
**Agent workflow:** [`GAMEPLAY_ANIMATION_AGENT_EXECUTION.md`](GAMEPLAY_ANIMATION_AGENT_EXECUTION.md).  
**Entry plan:** [`GAMEPLAY_ANIMATION_PLAN.md`](GAMEPLAY_ANIMATION_PLAN.md).

Tone: **paranoid slapstick** built from surveillance hardware, municipal infrastructure, improvised countermeasures, and bureaucratic machinery.

This is **not** cinematic animation and **not** unrestricted physics simulation.

---

## 1. Authority boundary

### Simulation owns (authoritative)

position · velocity · heading · targeting · projectile trajectory · collision · hit timing · damage · status effects · destruction · weapon cadence · deployable lifetime · enemy behavior · boss phases · extraction state · randomness · gameplay receipts

### SpriteKit may

project and interpolate snapshots; select authored clips; apply **bounded** secondary motion (recoil, wobble, debris, springs, cables, cloth, squash, smoke, easing); emit decorative particles; run presentation-only state machines driven by sim state.

### SpriteKit must not independently decide

physics-body collisions · random impulses · gravity · uncontrolled joints · particle collisions · animation-completion gameplay callbacks · sprite-dimension hitboxes · visual debris damage · render-frame timing as combat truth

### Never changed by animation

hitboxes · attack range · movement speed · projectile speed/direction · damage windows · status duration · entity ownership · spawn/death timing

**Missing animation assets must preserve functional shape-node fallbacks.**

---

## 2. Physics doctrine

Use **realistic physical principles filtered through stylized gameplay readability**.

Communicate: mass, momentum, acceleration, drag, recoil, inertia, friction, compression, release, mechanical resistance, structural failure, material differences, energy transfer.

**Hierarchy (strict order):**

1. Gameplay timing  
2. Silhouette readability  
3. Input responsiveness  
4. Physical plausibility  
5. Decorative realism  

Do not pursue physically exact simulation when it harms responsiveness or readability.

**Recommended rule:** animation curves and bounded secondary motion for realism. Limit SpriteKit physics bodies to **disposable cosmetic debris only** — never weapons, enemies, projectiles, or hit resolution.

---

## 3. Motion language — player

Feel: light enough to evade · grounded (no skating) · alert · slightly improvised, not military-trained.

| Family | Approx. frames | Notes |
| --- | --- | --- |
| 4-dir idle | 4–8 | Subtle breathing / weight shift |
| 4-dir move | 6–10 | Speed from authoritative move speed |
| Damage | 3–6 | Brief |
| Defeat | 8–16 | No long lock after death beyond sim |
| Extraction entry | 8–16 | Readable entry into Blind Spot |

Also: acceleration lean · deceleration recovery · direction-change anticipation · brief attack recoil · status-disrupted motion.

**Requirements**

- Feet/body anchored to simulation position  
- No visual foot sliding  
- Animation rate derives from authoritative movement speed  
- Lean subtle; rapid reversal remains responsive  
- Blending must not delay control  
- No long anticipation before ordinary move/attack  

**Current repo:** 8 single-frame player PNGs (`player_idle_*` / `player_walk_*`) via `PlayerAtlasManifest` (`frameCount: 1`). Multi-frame cycles are production targets, not present.

---

## 4–9. Six countermeasures (motion identity)

Still-art silhouettes and stems: weapon VFX docs. **This section is motion only.**

| Weapon | Physics character | Key clips |
| --- | --- | --- |
| **Kinetic** | Very fast accel, low arc, minimal wobble, short trail, compact recoil | launcher compress/release, flight stabilize, diode flicker, hardware pierce, split/empowered branches |
| **Redaction** | Dense, heavy-ish, shutter/paper/mask, rectangular occlusion | cartridge discharge, black-bar flight, attach, field expand/sustain/collapse, chain, mobile field |
| **Identity Transponder** | Weighted drop, one bounce, rubber settle, antenna spring | deploy, bounce, arm, spoof pulse, false-target, active loop, overload, expire |
| **FOIA Swarm** | Light, high drag, flutter, clip wings | release, paper flight, orbit, process impact, chain, paper-storm, disassemble |
| **Mirror Array** | Moderate mass, hinge sequence, vibration after hit | drop → tripod → rise → unfold → align → shimmer → reflect → damage → collapse |
| **Signal Flood** | Heavy, low bounce, coil vibration, pressure pulse | deploy, charge, warning lights, pulse, residual jam, overload, expended |

**Shared projectile laws**

- Follow deterministic trajectory **exactly** (no ballistic drop unless sim defines it)  
- Align to authoritative velocity (no random spin)  
- Reflection visuals must match sim in/out vectors  
- Swarm paths owned by sim; visual flutter is **bounded**, seeded/deterministic, no collision change, off under reduced motion  
- Signal pulse radius/duration from sim; provide standard / reduced-flash / high-Suspicion / chain variants  
- Fields are **world-space** gameplay effects, not UI overlays; do not obscure player, enemies, exits, critical hazards  
- False targets ≠ playable character lookalikes  

---

## 10. Projectile and impact systems

Reusable: spawn · trail · hardware impact · hostile impact · shielded · critical · pierce continue · expire · reflected · signal cancel.

High-speed prioritization: stretched silhouette · motion streak · previous→current interpolation · brief impact hold. Do not rely on blur that hides the projectile.

---

## 11. Cameras / LPR hardware

| State | Motion |
| --- | --- |
| Idle | Restrained servo, aperture, indicator pulse, cable tension |
| Scanning | Pan from authoritative heading, focus lock, scan-cone, return |
| Damaged | Uneven servo, sparks, loose housing |
| Disabled | Seizure, freeze, cyan interference, minor smoke |
| Destroyed | Compression → lens fracture → housing → wire snap → sparks → pole recoil → debris (visual only) → inactive |

Debris: **no collision, no damage.**

---

## 12–13. Guards and bosses

**Guards:** idle · patrol · acquire · pursuit · attack · hit · confused · processing-slow · spoof redirect · defeat. Weight + equipment lag + restrained slapstick. State via silhouette/motion, not color alone.

**Bosses:** entrance · idle · move · primary/secondary telegraph · phase transition · stagger · damage · defeat. Telegraphs from **deterministic boss state**, not animation duration. Clear recovery windows; no ambiguous hit timing.

---

## 14. Blind Spot and extraction

Network severance · open · active loop · boundary · extraction-ready · player entry · surveillance collapse · success transition.

Feel: **absence of force** / phase cancellation / machines desyncing — not a magic portal. Inside field: soften hostile scan, slow/cancel particles, terminate signal lines, reduce ambient motion; player remains fully readable.

---

## 15. Environmental secondary motion

Modular, city-aware **parameters** (timing, density, material) on global systems: warning lights, beacons, cables, signs, fabric, paper, leaves, water, fog, steam, mist, airport/freeway lights, fans, bridge lights, displays, scanner housings.

Do not invent a fully separate animation engine per city.

---

## 16. Physics parameters (art direction)

| Class | Behavior |
| --- | --- |
| Heavy | Low bounce, slow rotation, longer settle, stronger contact, less high-freq chatter |
| Light | Fast turns, flutter, more drag, quick settle after small hits |
| Springs/hinges | Critically damped or slightly underdamped; no endless oscillation. Settle ~0.15–0.4s small · 0.4–0.8s deployable panels · 0.8–1.5s boss machinery |
| Recoil | Opposes emission; immediate; recovers faster than displace; **never** moves canonical entity position |
| Debris | Inherit impact dir; rapid speed loss; sparse; short life; no gameplay collision; cull under density |
| Smoke | Consistent drift; expand; fade; never cover hazards; reduce on low-effects |
| Metal / rubber / paper / glass | Sharp/rebound · compress/slow · flutter/fold · fracture/sparkle |

---

## 17. SpriteKit implementation doctrine

**Authored sprite animation:** walk cycles · attack cycles · deployable unfold · camera damage · destruction · boss phase · major extraction.

**Procedural presentation:** interpolation · recoil offsets · small rotations · spring settle · bounded wobble · impact shake · particles · opacity · scale pulses · trails · light intensity · env secondary.

Prefer custom interpolation + deterministic presentation params over `SKPhysicsWorld` for anything combat-adjacent.

```text
sim snapshot → presentation (prev/current) → interpolate pose
            → animation SM selects clip
            → secondary motion (bounded offsets)
            → VFX projector reacts to RunEvent
            → animation never emits gameplay events
```

---

## 18. Animation state machines (examples)

```text
player/entity: idle | moving | attacking | damaged | status_affected | defeated | extracting
deployable:    spawning | deploying | active | triggered | expiring | expended
camera:        idle | scanning | locked | damaged | disabled | destroying | destroyed
boss:          entering | phase_idle | telegraphing | attacking | recovering | staggered | transitioning | defeated
```

Transitions driven by **authoritative state**. Never infer critical gameplay from animation progress.

---

## 19. Performance budget (landscape iPhone)

Design may support: up to 4 active weapon systems · ~96 ordinary projectiles · ~24 swarm agents · ~8 persistent deployables · dense enemies + env FX.

**Requirements:** pool nodes · compact atlases · cap particles/debris · cull off-screen secondary · lower distant frame rates · batch textures · avoid large transparent overdraw · no full-screen additive flashes · sim continues when FX culled.

Quality tiers: **full | reduced | minimal** — reduced preserves gameplay communication.

---

## 20. Accessibility

Readable without color alone · reduced motion · reduced flash · small scale · dense combat.

**Reduced motion:** opacity/compact scale instead of large translations; less shake/overshoot/particles/orbits; **keep** attack/hazard telegraphs.

**Reduced flash:** lower peak luminance; expanding geometry not white flash; longer brightness transitions; no rapid red-white; no full-screen pulses; preserve threat timing.

---

## 21. Camera shake

Allowed only: major camera destruction · heavy Signal Flood · boss phase transition · major boss impact · final network collapse.

Short · low displacement · weight-matched · reduced-motion compatible · **no effect on gameplay coordinates** · never continuous · never routine rapid fire.

---

## 22. Deliverables (production checklist)

1. Animation identity board  
2. Motion-language guide  
3. Entity animation state diagrams  
4. Projectile animation sheets  
5. Deployable animation sheets  
6. Impact and field FX sheets  
7. Camera damage/destruction sheets  
8. Enemy animation families  
9. Boss animation templates  
10. Blind Spot animation package  
11. Environmental secondary-motion package  
12. Reduced-motion variants  
13. Reduced-flash variants  
14. SpriteKit integration guidance (this doc §17 + code)  
15. Frame and duration manifest (machine: `GAMEPLAY_ANIMATION_MANIFEST.json`)  
16. Anchor manifest (align with `VisualAssetMap` / atlas manifests)  
17. Texture-atlas recommendations  
18. Maximum-density performance plan  
19. iPhone-scale contact sheet  
20. Animation QA checklist  

**Filenames:** deterministic `snake_case` — e.g. `player_walk_down`, `projectile_kinetic_flight`, `deployable_mirror_array_unfold`, `fx_impact_surveillance_hardware`, `fx_signal_flood_pulse`, `lpr_destroy_sequence`, `guard_processing_slow`, `boss_phase_transition`, `fx_blind_spot_open`.

**Forbidden names:** final, final_final, new, copy, alternate, version2, unnamed exports.

---

## 23. Negative prompt

No military-shooter motion language · no realistic gun fetish · no gore · no uncontrolled ragdolls · no fantasy spellcasting · no giant explosions · no excessive screenshake · no floaty ungrounded motion · no long attack anticipation · no visual motion disagreeing with sim movement · no full physics-body gameplay authority · no animation-driven hits/damage · no sprite-size collision · no random projectile drift · no debris with gameplay collision · no city-exclusive weapon animation systems · no unreadable particle density · no full-screen flashing · no photoreal motion blur · no slow cinematic that harms control · no baked text/labels/UI/borders.

---

## 24. Success criteria

Complete only when:

- motion feels physically plausible **and** controls stay immediate  
- authoritative sim timing unchanged  
- player / enemy / projectile / deployable / FX readable at iPhone scale  
- projectile visuals match canonical trajectories  
- all six countermeasures have distinct motion identities  
- deployable mass/mechanisms feel believable  
- destruction is satisfying without clutter  
- Blind Spot feels like network pressure leaving  
- reduced-motion and reduced-flash preserve gameplay communication  
- max-density combat remains readable and performant  
- missing assets retain functional fallbacks  
- **no animation owns gameplay truth**
