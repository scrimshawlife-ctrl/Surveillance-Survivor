# ART production readiness

Tracks GitHub issue **[#3](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/issues/3)** against **repository inventory**. Device readability and owner approval remain human gates.

**Related:** [`VISUAL_ASSET_MAP.md`](VISUAL_ASSET_MAP.md) · [`VISUAL_ASSETS_V0_2_INTAKE.md`](VISUAL_ASSETS_V0_2_INTAKE.md) · [`ENVIRONMENT_ART_MAP.md`](ENVIRONMENT_ART_MAP.md) · [`ROADMAP.md`](ROADMAP.md)

**As of:** 2026-07-24 · `make assets-check` → **160** runtime PNGs green.

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
| Player atlas: 4 dir idle + walk, transparent, deterministic names | **Met** | `player_idle_*`, `player_walk_*` (8 files) |
| LPR intact / damaged / destroyed, common canvas intent | **Met** | `lpr_intact`, `lpr_damaged`, `lpr_destroyed` |
| Suspicion meter native (not baked HUD bitmap) | **Met** | SwiftUI/SpriteKit meter; optional `suspicion_tier_0…5` glyphs attached |
| No labels/borders in runtime sprites | **Met by contract** | City/intake docs; validate via review |
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
| Projectile | `projectile_default` | **Reserved — shape fallback** |
| Deployables | `deployable_mirror_array`, `deployable_signal_flood` | **Reserved — shape fallback** |

### City foundation completeness

| Prefix | On main | Docs folder |
| --- | --- | --- |
| `wichita_*` … `atlanta_*` | Yes (13 each) | `docs/cities/<city>/` |

Optional later (not #3 blockers): five-district modular atlases, Atlanta boss-phase environment overlays.

---

## Reserved families — owner decision required

Record one line on issue #3 when decided:

```text
Projectile / deployable art: [ ] attach under V0.2 intake   [ ] accept shape-first for MVP forever
Decision date / reviewer:
```

Until decided, projectors correctly use shape fallbacks; **do not** invent textures without intake.

---

## Device ART QA checklist (operator)

Use after a signed Debug install (`make device-smoke` then play).

```text
date:
device / iOS:
commit:
player silhouettes readable in landscape motion: pass / fail
LPR states readable at play scale: pass / fail
guard / boss readable vs parking clutter: pass / fail
city pack (sample 3 cities) distinct without labels: pass / fail
Blind Spot readable under combat density: pass / fail
no white fringe / wrong alpha on dark asphalt: pass / fail
suspicion meter legible: pass / fail
icon recognizable at home-screen size: pass / fail
reviewer:
```

Paste into [`DEVICE_TEST_LOG.md`](DEVICE_TEST_LOG.md) or a comment on #3.

---

## Automated gates (repo-available)

```bash
make assets-check    # filename contract + PNG decode + sRGB/alpha family checks
make validate        # includes assets + package + simulator
```

These prove **attachment and contract**, not device readability.

---

## Closing issue #3

Do **not** close until:

- [x] Required v0.1 exports attached (repo)  
- [x] Expanded foundation art attached (repo)  
- [ ] Projectile/deployable decision recorded  
- [ ] Device ART QA checklist filed  
- [ ] Owner ship approval recorded  

---

## Non-goals for ART sign-off

- Generating marketing concept art as runtime  
- Closing #3 because city packs merged  
- Treating README hero as store screenshots  
- Audio binaries (tracked under audio roadmap, not #3)  
