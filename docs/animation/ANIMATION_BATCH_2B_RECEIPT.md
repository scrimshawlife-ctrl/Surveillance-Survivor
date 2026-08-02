# Gameplay animation work receipt — Batch 2B (player idle quality)

| Field | Value |
| --- | --- |
| Batch | **2B** — Player idle continuity fix (prop-stable `_2` frames) |
| Date (UTC) | 2026-08-01 |
| Official ladder note | Quality pass on Batch 2 player cycles; does **not** replace ladder Batch 3 (projectile/impact) |
| Video pipeline | **Blocked** — ZDR requires `output.upload_url` for `image_to_video` |
| Fallback | Keyframe `image_edit` from existing base stills |

## Audit findings addressed

| ID | Finding | Resolution |
| --- | --- | --- |
| A-01 | Idle `down` device prop popped between f1/f2 | Replaced all `player_idle_{dir}_2` with prop-stable breath frames |
| A-03 (partial) | Masters incomplete for idle | Idle bases + `_2` written under `Resources/Animation/Masters/Player/` |
| A-02 | Under target frame counts | **Deferred** — needs video-first harvest for walk 6–10 / idle 4–8 |
| A-04 | Not video-first | Documented ZDR block; next expansion waits on video upload path |

## Delivered

| Asset | Action |
| --- | --- |
| `player_idle_down_2.png` | Replaced (device prop continuous, subtle breath) |
| `player_idle_left_2.png` | Replaced |
| `player_idle_right_2.png` | Replaced |
| `player_idle_up_2.png` | Replaced |
| Masters/Player idle bases + `_2` | Synced from runtime |
| xcassets imagesets | Updated PNG payloads |
| Walk banks | **Unchanged** (4f remain; keyframe pilots not shipped) |

Canvas remains **414×596** RGBA, black key, nearest-neighbor friendly.

## Flip test (idle down)

1. Base: standing, cyan device in hand.  
2. `_2`: same device presence, subtle posture/weight shift.  
3. Loop 2→1: prop does not vanish (continuity pass vs prior bank).

## Validation

```bash
make animation-check   # PASS
make assets-check      # PASS (194 runtime PNGs)
```

## Not in this batch

- Walk density expansion to 6–10 frames  
- Damage / defeat / extract / LPR / boss multi-frame  
- Weapon flight sheets (ladder Batch 3 / VFX track)  

## Next

When video generation is available (non-ZDR or signed `upload_url`):

1. `image_to_video` from `player_walk_down` / `player_idle_down` bases, camera locked, in place.  
2. Harvest `fps=12`, select full gait / breath period.  
3. Clean + package all four directions.  
4. Update `PlayerAtlasManifest` frameCounts if counts change.  
