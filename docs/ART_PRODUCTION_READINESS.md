# ART production readiness

Tracks GitHub issue **[#3](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/issues/3)** against **repository inventory**. Device readability and owner ship approval remain human gates.

**Related:** [`VISUAL_ASSET_MAP.md`](VISUAL_ASSET_MAP.md) · [`VISUAL_ASSETS_V0_2_INTAKE.md`](VISUAL_ASSETS_V0_2_INTAKE.md) · [`ENVIRONMENT_ART_MAP.md`](ENVIRONMENT_ART_MAP.md) · [`ROADMAP.md`](ROADMAP.md) · [`weapon_vfx/`](weapon_vfx/) · [`animation/`](animation/)

**As of:** 2026-07-30 · current main `bbf39b2` · `make assets-check` green · [`ART_QA_PERCEPTION_AUDIT.md`](ART_QA_PERCEPTION_AUDIT.md) (`ship_gate: ART_EVIDENCE_INSUFFICIENT`) · operator [`LAUNCH_OPERATOR_PACKET.md`](LAUNCH_OPERATOR_PACKET.md).

---

## Sign-off definition

**ART signed off** when all of the following are true:

1. Every **issue #3 required export** is attached under the intake contract **or** explicitly waived in writing.  
2. A **physical iPhone** landscape session confirms nearest-neighbor readability (no mushy upscale, no unreadable clutter).  
3. Owner records **ship approval** for the attached set (can be a short note on #3 or in DEVICE_TEST_LOG).  

Simulator-only green **does not** complete sign-off.

---

## Issue #3 original requirements

| Requirement | Repo status | Path / evidence |
| --- | --- | --- |
| App icon 1024×1024 sRGB, opaque, no baked radius | **Met** | `Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` |
| Player atlas: 4 dir idle + walk, transparent, deterministic names | **Met + multi-frame** | Base 8 + walk `_2.._4` + idle `_2` (Batch 2 #49) |
| LPR intact / damaged / destroyed, common canvas intent | **Met** | `lpr_intact`, `lpr_damaged`, `lpr_destroyed` |
| Suspicion meter native (not baked HUD bitmap) | **Met** | SwiftUI/SpriteKit meter; optional `suspicion_tier_0…5` glyphs attached |
| No labels/borders in runtime sprites | **Met by contract** | City/intake docs; signal-flood candidate re-keyed for no text |
| Names match `GameAssetName` | **Met** | `GameAssetName.swift` + allow-list |
| Nearest-neighbor crisp on **physical** iPhone | **Pending** | Device QA only |
| Source boards archived separately from runtime | **Met** | `docs/cities/*/assets/` boards; runtime under `Resources/` |

---

## Expanded production inventory (beyond v0.1)

| Family | Count / names | Status |
| --- | --- | --- |
| Blind Spot decal | `blind_spot_decal` | Attached |
| Guard / boss | `guard_default`, `boss_default` | Attached |
| Global env package v1 | `env_tile_*` (5), props, decals, parallax, retail mass | Attached |
| City foundation packs | 10 cities × 13 textures | Attached (Wichita…Atlanta) |
| Visual role map | `VisualAssetMap` + tests | Done |
| Presentation pipeline | `Game/Presentation/*` | Done (#46) |
| Player multi-frame | idle 2f + walk 4f × 4 dirs | Attached (#49) |
| Projectile | `projectile_default` | **Attached** (#49) · `runtime_integrated` |
| Deployables | `deployable_mirror_array`, `deployable_signal_flood` | **Attached** (#49) · single-frame heroes |

### City foundation completeness

| Prefix | On main | Docs folder |
| --- | --- | --- |
| `wichita_*` … `atlanta_*` | Yes (13 each) | `docs/cities/<city>/` |

Optional later (not #3 blockers): five-district modular atlases, Atlanta boss-phase environment overlays, deployable 3-state strips, enemy/boss multi-frame.

---

## Projectile / deployable decision (repo record)

```text
Projectile / deployable art: [x] attach under V0.2 intake   [ ] accept shape-first for MVP forever
Decision date / reviewer: 2026-07-25 — repo intake via #47 candidates + #49 runtime integration
Shape fallbacks: still coded if texture missing
```

Owner may still reject silhouettes and request regenerate before ship approval on #3.

### Kinetic projectile still — MVP waive

```text
Kinetic projectile still: [x] use projectile_default as kinetic family hero
Dedicated projectile_kinetic.png: [ ] deferred (optional P7)
Rationale: redaction / identity / FOIA already have distinct stills; kinetic is the
default countermeasure and owns the shared default still by design.
Date: 2026-07-25 · tip package after Art QA F-P2-01
```

---

## Device ART QA checklist (operator)

Use after a signed Debug install (`make device-smoke` then play) on the candidate release tip.

```text
date:
device / iOS:
commit: candidate release SHA
player silhouettes readable in landscape motion: pass / fail
player walk multi-frame cycles readable (not mushy): pass / fail
LPR states readable at play scale: pass / fail
guard / boss readable vs parking clutter: pass / fail
city pack (sample 3 cities) distinct without labels: pass / fail
projectile_default readable at combat scale: pass / fail
deployable_mirror_array / signal_flood readable: pass / fail
Blind Spot readable under combat density: pass / fail
no white fringe / wrong alpha on dark asphalt: pass / fail
suspicion meter legible: pass / fail
icon recognizable at home-screen size: pass / fail
player draws above hostiles (not buried under LPR clutter): pass / fail
projectiles stay readable above bodies: pass / fail
scan cones / flood do not white-out at high density: pass / fail
boss not same purple as processing tint: pass / fail
landmark zone not confused with Blind Spot cyan: pass / fail
reviewer:
ship approval (yes/no):
```

Paste into [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) or a comment on #3.

---

## Automated gates (repo-available)

```bash
make assets-check       # 194 runtime PNGs expected at current manifest/state
make weapon-vfx-check   # P0 runtime_integrated
make animation-check    # multi-frame + architecture statuses
make validate           # full local CI-parity
```

---

## Close criteria for #3

| Gate | Status after #49 |
| --- | --- |
| v0.1 required exports attached | **Met** |
| Guard/boss/env/cities | **Met** |
| Projectile/deployable textures | **Met** (single-frame) |
| Player multi-frame | **Met** |
| Physical-device readability log | **Open** |
| Owner ship approval note | **Open** |

**Keep #3 open** until device QA + owner ship note exist. Do not close from simulator alone.
