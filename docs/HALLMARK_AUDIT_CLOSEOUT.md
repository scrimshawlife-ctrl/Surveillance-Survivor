# Hallmark asset audit — closeout board

```yaml
version: 1.0.0
status: agent_closeout_complete
last_updated: 2026-07-25
main_tip_at_write: 939e094
```

Source audit: [`HALLMARK_ASSET_AUDIT.md`](HALLMARK_ASSET_AUDIT.md)  
Prior remediations: [`HALLMARK_ASSET_REMEDIATION_RECEIPT.md`](HALLMARK_ASSET_REMEDIATION_RECEIPT.md) · [#64](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/64) · [#65](https://github.com/scrimshawlife-ctrl/Surveillance-Survivor/pull/65)

---

## Closed this session (closeout)

| ID | Item | Evidence |
| ---: | --- | --- |
| M6 | Baked scan beams off Wichita arterial terrain | `wichita_terrain_asphalt_arterial_01` cleaned |
| M7 | Player canvas tight-crop | All 24 `player_*` → **414×596**; `PlayerAtlasManifest.canvasPoints` updated |
| M9 | Distinct projectiles per family | `projectile_redaction` / `identity` / `foia` + projector wiring |
| M1 | Skyline soft-compat | All 10 city skylines + `env_parallax_skyline` desat/pixel-pass |
| M5 | Terrain dual-system authority | `ENVIRONMENT_ART_MAP.md` M5 table — city pack wins |
| M10 | Suspicion glyphs off-token | Rebuild solid tier rings matching `VisualDesignTokens` ramp |
| C5 | Multi-frame weapon VFX | **Waived** → [`weapon_vfx/WEAPON_VFX_MULTI_FRAME_WAIVER.md`](weapon_vfx/WEAPON_VFX_MULTI_FRAME_WAIVER.md) |

## Already closed (prior PRs)

| ID | Item | PR |
| ---: | --- | --- |
| C1 | Magenta chroma plates + gate | #64 |
| C2 | Pixel combat stills | #64 |
| C3 | Landmark top-down (41) | #64 + #65 |
| C4 | LPR baked text | #64 |
| M2 | Blind Spot glitch | #64 |
| M3 | Boss charcoal recolor | #64 |
| M4 | Deployable 3-states | #64 |
| HUD | Hallmark terminal-grid tokens | #57 |

## Open remaining (cannot close from agent alone)

| ID | Severity | Item | Why still open | Owner |
| ---: | --- | --- | --- | --- |
| **#3** | launch | Device ART QA + ship note | Emulator ≠ device; nearest-neighbor on physical iPhone | Operator |
| **C5-full** | major | Multi-frame muzzle/hit/flood sequences | Waived until P7 art budget + reduced-flash device pass | Agent+owner after license/budget |
| **m1** | minor | Guard roster skins (6 archetypes) | Only `guard_default`; sim has full roster | Optional P7 |
| **m2** | minor | Unify skyline time-of-day band | Soft-compat done; identity lighting still varies | Optional polish |
| **m3** | minor | Prefer individual decals over `env_decal_sheet` | Sheet still attached for authoring | Optional |
| **m4** | minor | More interactable props vs landmarks | Prop count low vs 41 landmarks | Optional content |
| **m5** | minor | Reduced-flash overlay pairs (`_rf`) | High-luminance overlays lack RF variants | Optional a11y |
| **m6** | minor | Overlay accent discipline (cyan/red/yellow only) | Soft residual multi-hue on some overlays | Optional |
| **M8-full** | major | Overlay phone-scale density pass | Opacity/line-weight not fully re-authored per overlay | Optional P7 |
| Device log | launch | `DEVICE_TEST_LOG` for tip SHA | Operator | Operator |
| Audio Batch 1 | launch | ElevenLabs stems | Owner license | Operator |

## Agent-complete verdict

All Hallmark **audit items that can be closed without physical device or owner license** are closed or explicitly waived.

**Remaining list = operator launch lane + optional P7 polish only.**

### Gates expected

```bash
make assets-check
make sprite-chroma-check
make test
```
