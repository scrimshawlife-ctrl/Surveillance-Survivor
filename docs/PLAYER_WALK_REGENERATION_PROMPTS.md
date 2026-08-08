# Surveillance Survivor — Player Walk Cycle Regeneration

16 frames: four directions x four frames. **All four frames per direction must be
the same person in the same clothes.** That is the entire point of this batch.

## Why these are being regenerated

The frames currently in the game are four independent illustrations per direction.
Rendered at gameplay size they show four *different outfits* — grey jacket, olive
vest, teal sash, heavy vest — with nearly identical leg positions. Played at 9fps
the character appears to change clothes twice a second while barely walking. The
engine is fine; it cycles the frames correctly. The art is not a cycle.

Player walk is currently **held on frame 1** in code because a static character
looks correct and a costume strobe does not. It re-enables the moment these land.

The enemy walk batch delivered against this same format came back with **zero**
geometric drift and consistent uniforms across all 24 frames. Same rules here.

## Hard constraints

- **Frame 1 of each direction already exists and must NOT be regenerated.** It is
  the wardrobe and identity reference. Frames 2-4 must match it exactly.
- **Same outfit in every frame.** Same jacket, same vest, same straps, same colours,
  same visor glow, same boots. If frame 1 has a grey jacket, all four have that
  grey jacket. This is the constraint the previous batch failed.
- **Canvas:** exactly 414x596. Do not crop, pad or resize.
- **Feet baseline:** lowest opaque pixel at **y = 524 (+/-3)**. Non-negotiable —
  the character walks on a fixed ground line.
- **Content height:** within +/-6px of the frame-1 height listed per direction.
- **Horizontal centre:** within +/-6px of the frame-1 centre column.
- **Legs must actually move.** The stride is the deliverable. Frame 3 must have the
  legs visibly closer together than frames 2 and 4.
- Fully transparent background, RGBA with a real alpha channel (not RGB).
- **No magenta anywhere** (#FF00FF and neighbours) — the chroma sentinel rejects it.
- Pixel art matching frame 1 exactly: same palette, outline weight, shading steps.
- Lighting identical across frames. No frame brighter or darker than another.

## The cycle

Frame 1 is the neutral contact pose. Then:

- **Frame 2** — contact — left foot planted forward, right foot lifting off behind, weight over the front leg, arms counter-swinging.
- **Frame 3** — passing — legs closest together, the lifted foot passing the planted ankle, body at the top of its stride.
- **Frame 4** — contact mirrored — right foot planted forward, left foot lifting off behind, opposite arm leading.

Plays at 0.11s per frame. Frame 4 must loop cleanly into frame 1, so keep the
stride length identical between the two contact poses.

---

### `player_walk_down` — walking toward the camera, face and visor visible

- Canvas **414x596**, content height **456px (+/-6)**, feet_y **524 (+/-3)**, centre column **207 (+/-6)**
- Wardrobe reference: `player_walk_down.png`

  - `player_walk_down_2.png` — contact — left foot planted forward, right foot lifting off behind, weight over the front leg, arms counter-swinging.
  - `player_walk_down_3.png` — passing — legs closest together, the lifted foot passing the planted ankle, body at the top of its stride.
  - `player_walk_down_4.png` — contact mirrored — right foot planted forward, left foot lifting off behind, opposite arm leading.

### `player_walk_up` — walking away from the camera, back and hood visible

- Canvas **414x596**, content height **387px (+/-6)**, feet_y **523 (+/-3)**, centre column **207 (+/-6)**
- Wardrobe reference: `player_walk_up.png`

  - `player_walk_up_2.png` — contact — left foot planted forward, right foot lifting off behind, weight over the front leg, arms counter-swinging.
  - `player_walk_up_3.png` — passing — legs closest together, the lifted foot passing the planted ankle, body at the top of its stride.
  - `player_walk_up_4.png` — contact mirrored — right foot planted forward, left foot lifting off behind, opposite arm leading.

### `player_walk_left` — walking to the left in profile

- Canvas **414x596**, content height **458px (+/-6)**, feet_y **524 (+/-3)**, centre column **207 (+/-6)**
- Wardrobe reference: `player_walk_left.png`

  - `player_walk_left_2.png` — contact — left foot planted forward, right foot lifting off behind, weight over the front leg, arms counter-swinging.
  - `player_walk_left_3.png` — passing — legs closest together, the lifted foot passing the planted ankle, body at the top of its stride.
  - `player_walk_left_4.png` — contact mirrored — right foot planted forward, left foot lifting off behind, opposite arm leading.

### `player_walk_right` — walking to the right in profile

- Canvas **414x596**, content height **357px (+/-6)**, feet_y **524 (+/-3)**, centre column **207 (+/-6)**
- Wardrobe reference: `player_walk_right.png`

  - `player_walk_right_2.png` — contact — left foot planted forward, right foot lifting off behind, weight over the front leg, arms counter-swinging.
  - `player_walk_right_3.png` — passing — legs closest together, the lifted foot passing the planted ankle, body at the top of its stride.
  - `player_walk_right_4.png` — contact mirrored — right foot planted forward, left foot lifting off behind, opposite arm leading.

---

## Delivery

A flat folder of 12 PNGs named exactly as above (frames 2-4 only; frame 1 stays).
No subfolders, no `frame_01` style names.

On arrival each file is checked for canvas, content height, feet baseline, centre
column, alpha channel, absence of magenta, real frame-to-frame leg movement, and
**palette consistency against frame 1** — the check the last batch failed.
