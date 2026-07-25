# Hallmark asset audit — full runtime art inventory

```yaml
version: 1.0.0
status: audit_complete
verb: hallmark audit
scope: all Resources/RuntimeSprites (179 PNGs) + style contracts
last_updated: 2026-07-25
genre: atmospheric
theme: terminal-grid (HUD) · pixel-dystopian-satire (world)
do_not_edit: true
```

**Stamp:** `/* Hallmark · audit: full-asset-inventory · genre: atmospheric · theme: terminal-grid / pixel-satire */`

**Method:** Visual sample of every family + quantitative chroma/alpha scan of all 179 runtime PNGs.  
**Authority contracts:** [`VISUAL_ASSETS_V0_1.md`](VISUAL_ASSETS_V0_1.md) · [`VISUAL_ASSETS_V0_2_INTAKE.md`](VISUAL_ASSETS_V0_2_INTAKE.md) · [`ART_PRODUCTION_READINESS.md`](ART_PRODUCTION_READINESS.md) · prior HUD audit [`HALLMARK_VISUAL_AUDIT.md`](HALLMARK_VISUAL_AUDIT.md).

**Audit does not edit assets.** This is a ranked punch list only.

---

## Pre-flight findings

| Signal | Found |
| --- | --- |
| Runtime inventory | **179** PNGs under `Resources/RuntimeSprites` |
| City foundation | 10 cities × 13 roles = **130** |
| Global env | **10** (`env_tile_*`, props, decals, parallax, retail mass) |
| Characters | player **24** multi-frame · guard **1** · boss **1** |
| Sensors | LPR **3** states |
| Combat / FX | projectile **1** · deployables **2** · blind spot **1** · suspicion glyphs **6** |
| Weapon VFX pipeline | `docs/weapon_vfx/` candidates exist; **not** all integrated into runtime |
| HUD tokens | `App/VisualDesignTokens.swift` (Hallmark #57) — locked phosphor + alarm |
| Style bible | Pixel dystopian satire · cyan Blind Spot · red surveillance · yellow warning |
| Intake rule | **no labels/borders** · transparent PNG · nearest-neighbor readable |

---

## Inventory by family

| Family | Count | Sampled | Overall grade |
| --- | ---: | --- | --- |
| City terrain | 20 | wichita arterial, oakland yard, env tiles | B− (style split) |
| City landmark | 41 | wichita hangar | C (projection clash) |
| City overlay | 30 | radar, mesh, SF fog | C− (chroma + density) |
| City skyline | 10 | NYC, Tulsa | B+ (strong art, wrong scale language) |
| City decal / prop | 29 | quantitative magenta scan | C (chroma leftovers) |
| Player | 24 | idle down | A− |
| Guard / boss | 2 | both | B / C+ |
| LPR states | 3 | intact, destroyed | B− (label violation) |
| Projectile / deployables | 3 | all three | C (style mismatch) |
| Blind Spot / suspicion | 7 | both | C (generic vector) |
| Global env | 10 | asphalt, downtown | B |

---

## Critical (ships as slop or contract-breaking)

| # | Tell | Where | Fix |
| ---: | --- | --- | --- |
| C1 | **Chroma-key / magenta plate leftovers** (baked pink/magenta fill instead of alpha) | Worst offenders by magenta fraction: `san_francisco_landmark_comms_tower_01` (~67%), `tulsa_overlay_behavioral_crude_flow_01` (~60%), `tulsa_landmark_deco_tower_distant_01` (~59%), `dayton_decal_test_lane_stripe_01` (~40%), `oakland_decal_container_rust_01` (~25%), `san_francisco_prop_av_shell_01` (~17%), plus `san_francisco_overlay_fog_band_01` (visual magenta plate) | Re-export through chroma key → true alpha; fail `assets-check` if magenta plate > threshold |
| C2 | **Style-language collision: smooth AI 3D / vector combat vs pixel characters** | `projectile_default` (smooth 128² dart) · `deployable_mirror_array` · `deployable_signal_flood` vs `player_*` / `guard_default` pixel | Rebuild combat props in same pixel grid + outline weight as LPR/player; one silhouette language |
| C3 | **Projection collision: isometric landmark vs top-down gameplay** | `wichita_landmark_aircraft_hangar_01` (iso 3D hangar) while playfield is orthographic top-down | Re-author landmarks as top-down or 3/4 consistent with entity sprites; or treat iso as parallax-only with dim opacity |
| C4 | **Baked text label in runtime sprite** | `lpr_intact.png` has readable **"LPR"** on housing | Intake forbids labels — re-export with icon-only marking (LED, plate lens, no glyphs) |
| C5 | **No multi-frame weapon / hit / flood VFX in runtime** | Only single-frame projectile + 2 deployables; `docs/weapon_vfx/` batches are inventory, not play | Integrate Batch 0–2 heroes into RuntimeSprites + `GameAssetName` or explicitly waive with art note |

---

## Major (reads AI-generated or pack-incoherent)

| # | Tell | Where | Fix |
| ---: | --- | --- | --- |
| M1 | **City skyline = painterly illustration; playfield = pixel tiles** | All `*_skyline_parallax_01` (1024×384 full-bleed) vs terrain 256² tiles | Keep skylines but desaturate / pixel-quantize to match tile bit depth; or treat strictly as far parallax with heavy blur/soft multiply so clash softens |
| M2 | **Generic AI “target reticle” Blind Spot** | `blind_spot_decal.png` — pure cyan concentric rings, no grit | Replace with glitch / scan-cancellation pocket (broken scan dashes, not Target logo geometry) |
| M3 | **Boss palette off-bible** | `boss_default.png` purple suit vs cyan/red/yellow satire bible | Recolor to municipal charcoal + alarm badge + phosphor trim; keep silhouette |
| M4 | **Deployable quality defects** | `deployable_mirror_array` black damage blob on top panel; high-gloss CGI feel | Clean hero plate; matte municipal materials; 3-state strip (inactive/active/expended) per P7 note |
| M5 | **Terrain double system** | Global `env_tile_*` **and** per-city `*_terrain_*` with different paint languages | Declare one ground authority per district; env tiles = fallback only; document in ENVIRONMENT_ART_MAP |
| M6 | **Baked surveillance beams in terrain** | `wichita_terrain_asphalt_arterial_01` purple scan wedges painted into asphalt | Move scan wedges to overlay role; keep terrain neutral for reuse |
| M7 | **Player canvas oversized / portrait frame** | All `player_*` at **436×640** with large empty margin | Crop to tight pixel bounds + consistent feet baseline for atlas packing |
| M8 | **Overlay readability at phone scale** | Dense full-frame meshes (`atlanta_overlay_nationwide_mesh_01`, radar rings) | Thin line weight; opacity ≤ 0.35 default; reduced-flash variants for seizure safety |
| M9 | **Single projectile for all weapons** | One dart stands for kinetic / redaction / FOIA / spoof | Distinct silhouettes per weapon family (bar, form-stack, spoof puck) — even single-frame |
| M10 | **HUD glyph pack unused / off-token** | `suspicion_tier_0…5` pink/magenta target rings | Either wire as optional icons under VisualDesignTokens colors or delete from runtime allow-list to avoid drift |

---

## Minor (taste / polish)

| # | Tell | Where | Fix |
| ---: | --- | --- | --- |
| m1 | Guard is stock “security polo” without city satire | `guard_default` | Later: roster skins (cadet / radio / clipboard) using archetype IDs already in sim |
| m2 | Skyline city identity is strong (good) but lighting time-of-day differs | NYC dusk vs Tulsa daylight | Optional: unify ambient band (dusk surveillance hour) across all 10 |
| m3 | Decal sheets vs individual city decals | `env_decal_sheet` + city decals | Prefer individual keyed sprites; sheet only for authoring |
| m4 | Landmark count high (41) vs prop count low (9) | city packs | Bias next batch toward interactable props (gates, booths, transformers) for P9 landmarks |
| m5 | No reduced-flash pairs for high-luminance overlays | radar / mesh / neon glow | Author `_rf` variants per weapon-vfx practice |
| m6 | Prior Hallmark HUD pass fixed chrome; world still rainbow-adjacent | overlays with cyan+yellow+magenta | Cap accent to bible: cyan / red / yellow only on overlays |

---

## Style consistency matrix (what’s fighting what)

```
Characters (pixel)  ──clash──►  Combat props (smooth CGI)
       │                              │
       │                              ▼
       └──────────clash────────►  Isometric landmarks
                                  │
Terrains (tile paint) ──ok/soft──►  Overlays (vector HUD-on-world)
                                  │
Skylines (painterly) ──scale───►  Everything (different DPI language)
```

**North star for redesign (when approved):** one **top-down pixel municipal** language:

1. Same outline weight as `lpr_*` / `player_*`  
2. Cyan = resistance / Blind Spot only  
3. Red = active surveillance only  
4. Yellow = municipal hazard only  
5. No baked text · no chroma plates · no iso 3D on the playfield layer  

---

## Quantitative chroma scan (auto)

Magenta-heavy plates (fraction of near-magenta opaque pixels) — re-key candidates:

| Asset | Magenta fraction | Size |
| --- | ---: | --- |
| `san_francisco_landmark_comms_tower_01.png` | 0.668 | 192×320 |
| `tulsa_overlay_behavioral_crude_flow_01.png` | 0.597 | 256×256 |
| `tulsa_landmark_deco_tower_distant_01.png` | 0.590 | 256×384 |
| `dayton_decal_test_lane_stripe_01.png` | 0.403 | 320×160 |
| `oakland_decal_container_rust_01.png` | 0.246 | 256×256 |
| `san_francisco_prop_av_shell_01.png` | 0.170 | 160×96 |
| (+ several overlays 3–6%) | | |

Full-opaque plates (expected for terrain/skyline; flag if used as prop): skylines + terrains correctly opaque.

---

## What is already strong (do not burn)

| Asset / family | Why keep |
| --- | --- |
| `player_*` silhouette + cyan goggles | Instant identity; satire-correct |
| `lpr_destroyed` cyan shatter | Readable payoff; matches bible |
| `deployable_signal_flood` hardware read | Clear municipal object (needs pixel pass only) |
| City skyline *concepts* (NYC bridge, Tulsa oil) | Strong city identity — fix language, not identity |
| `wichita_overlay_radar_sweep_01` | Good pressure metaphor if opacity-tuned |
| Global `env_tile_asphalt` hazard language | Solid base tile craft |

---

## Recommended remediation order (not executed)

1. **Gate:** add `scripts/validate_sprite_chroma.py` → fail on magenta plate > 2% for non-skyline sprites.  
2. **C1 batch:** re-key top 10 magenta offenders.  
3. **C4:** LPR intact label removal.  
4. **C2 + C5:** pixel projectile family + integrate weapon VFX heroes.  
5. **C3 + M1:** landmark projection pass (top-down) + skyline soft-compat.  
6. **M2 + M3:** Blind Spot + boss recolor.  
7. **P7:** deployable 3-state strips; guard roster skins.  

Device QA (#3) still required after any mass re-export — sim green ≠ ship.

---

## Counts

**5 critical · 10 major · 6 minor**

**Verdict:** Inventory is **production-attached and city-distinct**, but **not style-unified**. The pack reads as three generators stitched together (pixel characters · CGI combat · painterly/iso environments) with residual chroma-key failures. HUD Hallmark pass (#57) fixed chrome; **world art still fails atmospheric terminal-grid coherence**.

---

## Next verbs (opt-in)

| Command | Effect |
| --- | --- |
| `hallmark redesign` combat pack | Pixel projectile + deployables + Blind Spot |
| `hallmark redesign` chroma batch | Fix C1 list only |
| full regen | Requires owner art budget + device re-QA — do not auto-start |

*Audit complete. No asset files modified.*
