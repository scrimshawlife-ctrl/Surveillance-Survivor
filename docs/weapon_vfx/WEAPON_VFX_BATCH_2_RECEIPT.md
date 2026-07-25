# Weapon / VFX work receipt — Batch 2 (P0 runtime intake)

| Field | Value |
| --- | --- |
| Batch | **2** — P0 runtime intake |
| Date (UTC) | 2026-07-25 |
| Runtime | **Integrated** stills for 3 stems |
| Shape fallbacks | Still available if texture missing |

## Installed

| Stem | RuntimeSprites | Imageset |
| --- | --- | --- |
| `projectile_default` | yes | yes |
| `deployable_mirror_array` | yes | yes |
| `deployable_signal_flood` | yes | yes |

Manifest status: `runtime_integrated` for the three P0 rows.
Allow-list updated in `scripts/validate_visual_assets.sh`.
Collision / sim radii **unchanged**.

## Gaps remaining

- Deployable multi-state (3 frames) not authored — single active pose.
- Pixel cohesion vs city packs may need future polish.
- Device readability still open (#3).

## Validation

```bash
make assets-check   # 179 PNGs with animation frames
make weapon-vfx-check
```
