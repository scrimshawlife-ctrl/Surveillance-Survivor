# Player walk/idle feet normalization — 2026-08-05

## Problem (field audit G-03)

Player walk banks shared a 414×596 canvas after #159, but **content bounding boxes**
differed by facing (content height ~380–487px; feet line drifted). Stretching the
full canvas to `displaySize` 54×72 made the avatar **hop and resize when turning**.

Batch 6 receipt still correctly notes multi-outfit wardrobe inconsistency within
frames — that needs art regen. This pass only **locks feet** and unifies scale.

## Method

For each `player_walk_*` and `player_idle_*` frame (24 PNGs):

1. Crop to alpha bbox  
2. Scale with nearest neighbor so tallest content fits under feet line  
3. Paste onto transparent 414×596 with **feet at y = 524** (~anchor 0.12 from bottom)  
4. Write both `Resources/RuntimeSprites/` and matching `Assets.xcassets` imagesets  

## Result

- Feet bottoms: ~523–524 across all walk/idle facings  
- Within-direction content height stable  
- Cross-direction height still varies with pose (expected foreshortening)  
- **Does not** fix wardrobe/outfit identity — separate art task  

## Related

- Field audit: `docs/CONTINUATION_REPORT_2026-08-05_graphics_playability_field_audit.md` G-03  
- G-02 carpet α 0.88 → 0.48 / secondary 0.30 → 0.18 (same change set)  
