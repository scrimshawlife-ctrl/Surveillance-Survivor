# Surveillance Survivor — Weapon, Projectile & VFX Asset Production

## Status and authority

- **Authority:** canonical visual-production specification for weapons, projectiles, deployables, and combat FX
- **Gameplay authority:** `docs/WEAPON_SYSTEM_DESIGN.md` and `Sources/SurveillanceCore`
- **Runtime visual authority:** `Game/Rendering/VisualAssetMap.swift` and `Game/Rendering/GameAssetName.swift`
- **Machine queue:** `docs/WEAPON_VFX_ASSET_MANIFEST.json`
- **Platform:** landscape iPhone, SpriteKit, nearest-neighbor presentation

This document is audit-visible. Agents must inventory and reuse existing assets before generation, must not invent mechanics, and must not claim a reserved asset is runtime-integrated until its logical role, projection mapping, binary intake, and tests exist together.

## 1. Current implementation boundary

The canonical weapon roster contains six countermeasures:

1. Kinetic Countermeasure
2. Redaction Ordinance
3. Identity Transponder / Plate Spoofer
4. FOIA / Paperwork Swarm
5. Mirror Array
6. Signal Flood

The current runtime visual namespace exposes only:

- `projectile_default`
- `deployable_mirror_array`
- `deployable_signal_flood`

Shape-node fallbacks remain authoritative when binaries are absent. The remaining families in this document are production requirements or reserved integration targets, not proof of current runtime support.

## 2. Art thesis

The visual language is **improvised anti-surveillance sabotage**, not conventional firearms and not fantasy magic.

Core materials:

- compact relays, sensor glass, shielded cable, stamped metal, industrial plastic, rubber, tape, clamps, warning paint, hacked retail electronics, paper, clipboards, mirrored panels, optical filters, signal emitters, utility hardware
- cool player signal language: cyan, pale green, muted electric blue, warning white, restrained amber
- hostile institutional language: surveillance red, sodium amber, procedural magenta used sparingly
- strong silhouettes and motion logic; color is supplementary

The tone is paranoid slapstick: clever, tactile, dry, municipal, bureaucratic, and absurd without becoming novelty comedy.

## 3. Global generation prompt

Use this shared prefix for all asset generation:

> Create production-ready 2.5D top-down pixel-art runtime assets for the landscape-iPhone SpriteKit roguelite Surveillance Survivor. Crisp silhouette-first design, nearest-neighbor compatible, transparent background, clean alpha, consistent three-quarter top-down perspective, readable at small gameplay scale, restrained detail, improvised anti-surveillance technology built from municipal hardware, relays, optics, stamped metal, industrial plastic, paper, shielding, warning paint, and hacked retail electronics. No conventional firearm fetish, no fantasy magic, no generic cyberpunk neon, no gore, no text, no UI, no presentation board, no backdrop, no watermark, no baked hitbox or gameplay radius.

Universal negative prompt:

> No realistic assault rifle, no shell-casing emphasis, no fantasy spell, no wizard effect, no gore, no blood, no giant explosion, no heavy opaque smoke, no photoreal blur, no military branding, no real manufacturer logo, no city-specific skin, no labels, no grids, no callout arrows, no decorative background, no mockup device frame.

## 4. Reuse and duplication rules

Every requested asset receives exactly one status:

- `REUSE_EXACT`
- `REUSE_VARIANT`
- `COMPOSE_FROM_EXISTING`
- `GENERATE_MISSING`
- `REJECT_DUPLICATE`
- `RESERVED_INTEGRATION`

Rules:

1. Hash-audit all existing runtime sprites, source exports, and approved generated images.
2. Do not generate city-specific projectile packs; all six base weapons are globally viable.
3. Do not duplicate an existing semantic role under a new filename.
4. Animated sequences share one canvas, anchor, scale, and orientation.
5. Sprite bounds never define collision, damage radius, field radius, or targeting.
6. Reduced-flash alternatives are mandatory for bright signal bursts.
7. Important repeatable effects should provide three variants when practical.

## 5. Production dimensions and anchors

These are intake targets, not simulation geometry:

| Family | Canvas | Anchor | Notes |
|---|---:|---:|---|
| projectile core | 128×128 | 0.5, 0.5 | oriented toward local +X; runtime may rotate |
| swarm agent | 128×128 | 0.5, 0.5 | common canvas across variants |
| deployable | 256×256 | 0.5, 0.25 | visible ground contact |
| muzzle/emission FX | 192×192 | 0.25, 0.5 | origin near firing point |
| impact FX | 256×256 | 0.5, 0.5 | transparent, centered |
| field/pulse frame | 512×512 | 0.5, 0.5 | visual extent only, not authoritative radius |
| destruction FX | 384×384 | 0.5, 0.35 | debris remains bounded |

Use sRGB PNG, real alpha, nearest-neighbor filtering, and safe transparent padding.

## 6. Canonical weapon families and prompts

### 6.1 Kinetic Countermeasure

**Gameplay identity:** fast direct camera damage; later piercing, homing, multi-shot, and split targeting.

**Projectile prompt:**

> Compact top-down kinetic anti-surveillance dart, improvised but precise, short shielded metal shaft, ceramic optics-breaking tip, tiny cyan tracking diode, black industrial polymer fins, not conventional ammunition, narrow high-speed silhouette, readable at 16–32 pixels, transparent background.

**Muzzle prompt:**

> Dry compact mechanical launcher emission, compressed spring snap, tiny white-cyan impulse wedge, two restrained metal flecks, no gunpowder flame, no large starburst, transparent background.

**Trail prompt:**

> Very short pale-cyan kinetic streak with one broken data-dash fragment and minimal particulate flecks, designed for dense rapid fire, transparent background.

**Impact prompt:**

> Compact anti-surveillance dart impact on camera hardware: sharp metal tick shape, lens-chip fragments, tiny cyan electrical cancellation pop, restrained sparks, no explosion, transparent background.

### 6.2 Redaction Ordinance

**Gameplay identity:** sensor denial, cone narrowing, temporary safe zones, guard confusion.

**Projectile prompt:**

> Top-down redaction projectile shaped like a dense black document bar folded around a compact mechanical cartridge, matte black core, white paper edge, small magenta-red scanner cancellation line, instantly distinct from kinetic ammunition, transparent background.

**Field prompt:**

> Modular redaction field FX: overlapping matte-black rectangular masks with softened torn-paper edges, subtle scanner lines collapsing inward, sparse cool-gray interference particles, world-space effect rather than UI, transparent background, reduced-flash compatible.

**Impact prompt:**

> Redaction impact: mechanical shutter closes, black paper strip snaps across sensor glass, scan beam breaks into clipped fragments, dry and readable, no magical darkness cloud, transparent background.

### 6.3 Identity Transponder / Plate Spoofer

**Gameplay identity:** pulse or decoy beacon that suppresses contacts, clears lock, and redirects guards.

**Deployable prompt:**

> Compact top-down identity-spoofing transponder beacon, rugged puck-like device assembled from a license-plate reflector fragment, shielded antenna loop, cyan and pale-green status LEDs, adhesive rubber feet, municipal-service hardware aesthetic, transparent background.

**Active-state prompt:**

> Armed identity transponder with rotating segmented cyan identifier ring, two false-position blips splitting away, subtle relay glow, clear active silhouette, no holographic text, transparent background.

**Pulse prompt:**

> Identity spoof pulse: restrained circular packet wave made of broken registration-like bars and duplicated locator dots, pale cyan and green, low opacity, no readable characters, transparent background, reduced-flash alternative included.

### 6.4 FOIA / Paperwork Swarm

**Gameplay identity:** seeking paper or clipboard entities applying processing slow, cadence delay, damage over time, chaining, or paper storm.

**Swarm-agent prompt:**

> Tiny top-down autonomous paperwork drone: folded request form with reinforced corners, miniature binder clip wings, stamped-metal spine, one cyan tracking light, comic bureaucratic menace without a face, strong readable paper silhouette, transparent background.

**Variant prompts:**

> Create three coherent swarm variants on the same canvas: folded form dart, clipboard micro-drone, stapled packet spinner. Preserve shared palette, scale, and top-down angle.

**Processing-impact prompt:**

> Bureaucratic processing impact FX: forms stamp themselves in a tight spiral, binder clip snaps, tiny receipt-printer strip curls around the target, muted white, copier gray, cyan accent, no readable writing, transparent background.

**Paper-storm field prompt:**

> Controlled top-down paper storm field made from a bounded ring of abstract forms, clipped folders, and binder tabs, directional rotation with clear center, no readable text, low visual opacity for gameplay readability, transparent background.

### 6.5 Mirror Array

**Gameplay identity:** short-lived reflector deployable that redirects beams/projectiles and may blind source cameras.

**Base deployable prompt:**

> Top-down portable mirror array deployable, three hinged angular reflective panels on a compact weighted municipal tripod, scuffed chrome, dark rubber feet, cyan alignment LEDs, practical improvised construction, strong triangular silhouette, transparent background.

**Active-state prompt:**

> Mirror array active state with panels unfolded into a clear three-way reflector, narrow controlled reflection highlights, faint cyan alignment geometry, no giant lens flare, transparent background.

**Reflect FX prompt:**

> Compact beam reflection FX: incoming red or amber surveillance line strikes a mirrored panel and exits as a sharper cool-cyan redirected line, tiny optical prism fragments at contact, transparent background, reduced-flash variant.

**Expended-state prompt:**

> Mirror array expended state, panels misaligned and lightly cracked, LEDs dark, still readable as the same device, no large debris cloud, transparent background.

### 6.6 Signal Flood / EMP Pulse

**Gameplay identity:** high-risk area disable, large Suspicion spike, cluster and boss opening tool, residual jamming.

**Base deployable prompt:**

> Top-down signal-flood emitter, compact industrial coil and capacitor assembly inside a rugged circular municipal utility housing, exposed shielded cable, warning amber and cyan indicators, heavy but portable, not a sci-fi bomb, transparent background.

**Charge-state prompt:**

> Signal-flood emitter charging: segmented coil lights illuminate in sequence, restrained cyan-white corona hugs the device, small warning-amber relay flashes, no opaque glow ball, transparent background.

**Pulse prompt:**

> Large but readable top-down signal-flood pulse: concentric broken interference rings, relay-grid fragments, camera scan lines collapsing outward, cyan-white core with restrained amber warning edge, transparent background, reduced-flash variant with lower luminance and thicker geometry.

**Residual-jam prompt:**

> Persistent residual jamming field: low-opacity broken concentric rings, subtle static grains and interrupted scan dashes, clear center and boundary, designed not to obscure characters, transparent background.

## 7. Shared FX prompts

### Camera disabled / frozen

> Surveillance camera disabled-state FX: servo motion locks, lens aperture freezes half-closed, compact cyan interference brackets and tiny gray relay smoke, readable without flashing, transparent background.

### Camera destruction

> LPR camera destruction FX: lens glass fractures, small metal housing panels separate, wire snap, servo sparks, short hollow pole resonance visualized as a restrained ring, no fireball, bounded debris, transparent background.

### Enemy or boss hit

> Compact hit confirmation on institutional target: stamped-metal tick, clipped red procedural shards, small cyan cancellation accent, no gore, no large bloom, transparent background.

### Critical / empowered hit

> Empowered anti-surveillance impact: same base impact silhouette with doubled mechanical snap geometry, sharper cyan-white core and brief relay-chain fragments, still compact and readable, transparent background.

### Blind Spot opening

> Blind Spot opening FX: hostile red and amber scan fragments pull apart and phase-cancel, cool cyan quiet pocket emerges at center, sparse softened interference rings, hopeful but temporary, no fantasy portal, transparent background.

### Blind Spot active

> Seamless active Blind Spot field frames: low-opacity cool cyan boundary, surrounding scan dashes bend and dissolve at the edge, quiet center, restrained motion, reduced-flash safe, transparent background.

### Network severance

> Network-link severance FX: taut procedural data line snaps at a relay node, both ends retract into broken square packets, cool cyan release spark, no explosive energy, transparent background.

## 8. Runtime and reserved asset matrix

### Current runtime-addressable roles

| Asset stem | Role | Production priority |
|---|---|---|
| `projectile_default` | current generic projectile projection | P0 |
| `deployable_mirror_array` | Mirror Array projection | P0 |
| `deployable_signal_flood` | Signal Flood projection | P0 |

### Reserved canonical stems

| Asset stem | Canonical role |
|---|---|
| `projectile_kinetic` | Kinetic Countermeasure core |
| `projectile_redaction` | Redaction Ordinance core |
| `deploy_identity_transponder` | Identity Transponder base |
| `swarm_foia` | FOIA swarm agent |
| `deploy_mirror` | future typed Mirror Array alias, only if namespace migration is approved |
| `pulse_signal_flood` | Signal Flood pulse |

Do not add reserved stems to runtime maps without updating `GameAssetName`, `VisualAssetMap`, projector resolution, intake manifests, and tests together.

## 9. Animation minimums

| Family | Required frames |
|---|---:|
| projectile core | 1; optional 3-frame flicker/spin |
| swarm agent | 3-frame flutter/spin |
| deployable inactive→active | 2–4 frames |
| muzzle/emission | 3–5 frames |
| impact | 4–6 frames |
| field pulse | 6–10 frames |
| camera destruction | 6–8 frames |
| Blind Spot opening | 8–12 frames |

Every sequence must include frame order, frame duration recommendation, canvas, anchor, and loop/non-loop status in the manifest receipt.

## 10. Accessibility requirements

- Distinguish weapon families by silhouette and motion, not color alone.
- Supply reduced-flash variants for Signal Flood, reflection, critical hits, boss pulses, and Blind Spot opening.
- Avoid rapid full-screen luminance changes.
- Preserve player silhouette at maximum projectile density.
- Effects may be visually culled without altering deterministic simulation.
- Validate on a physical landscape iPhone at maximum supported density: 96 ordinary projectiles, 24 swarm agents, and eight persistent deployables.

## 11. Intake workflow

1. Inventory all existing source and runtime visual files.
2. Compute SHA-256 hashes and detect exact duplicates.
3. Compare semantic roles and reject near-duplicate generation.
4. Generate P0 runtime-addressable assets first.
5. Review silhouettes at gameplay scale before animation expansion.
6. Produce approved transparent PNG masters.
7. Record prompt, negative prompt, dimensions, anchor, frame count, status, source, license, and hash.
8. Add binaries to `Resources/RuntimeSprites/` and Xcode asset catalog only after approval.
9. Update logical namespace and visual roles only when required.
10. Run visual asset validation, package tests, simulator tests, and physical-device readability checks.

## 12. Completion criteria

The pack is complete only when:

- P0 runtime roles have approved binaries or are explicitly deferred;
- every asset has an inventory and deduplication status;
- all six canonical weapon families have approved identity designs;
- animation canvases and anchors are consistent;
- reduced-flash alternatives exist;
- player, hostile, and extraction FX remain distinguishable without color;
- no city-specific duplicate weapon pack exists;
- no sprite changes simulation geometry;
- manifests, hashes, prompts, and licenses are recorded;
- device evidence confirms readability at maximum bounded density.
