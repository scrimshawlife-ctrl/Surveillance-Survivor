# Surveillance Survivor — Enemy Walk-Cycle Frames

24 frames. These are the only assets standing between the enemies and animation:
the engine already cycles guard and boss banks, finds no `_2`, and holds the still.
Drop these PNGs beside the existing ones and the enemies animate with no code change.

## Read this first — it is why the player walk cycle had to be repaired

The player walk frames were generated as four independent illustrations. Each came
back at its own zoom and its own position on the canvas: frame 1 was 485px tall,
frames 2-4 were about 340px. Played back, the player jumped 30% in size and hopped
up to 100px every step. The wardrobe also drifted — frame 1 wore a grey jacket,
frame 4 an olive vest — so the character appeared to change clothes while walking.

**A walk cycle is one drawing shown in four poses, not four drawings of a walk.**
Every frame below must be the same individual, same outfit, same colours, same
camera distance. Only the limbs move.

## Hard constraints — all frames

- **Frame 1 already exists and must not be regenerated.** It is the reference.
- **Canvas:** exactly as stated per archetype. Do not crop, pad or resize.
- **Content height:** within ±4px of the stated frame-1 height. This is the
  single most important number — it is what keeps the character from resizing.
- **Feet baseline:** the lowest opaque pixel must sit within ±3px of the stated
  `feet_y`. The character walks on a fixed ground line.
- **Horizontal centre:** body centred within ±5px of the stated centre column.
- **Background:** fully transparent. RGBA with a real alpha channel, not RGB.
- **No magenta anywhere** (`#FF00FF` and neighbours) — the chroma sentinel
  rejects it, since magenta is used as a keying colour elsewhere in the pipeline.
- **Style:** pixel art matching the existing sprite exactly — same palette, same
  outline weight, same shading steps, same level of detail. Top-down three-quarter
  view, consistent with the frame-1 PNG supplied as reference.
- **Lighting:** unchanged across frames. No frame may be brighter or darker.

## The cycle

Frame 1 (existing) is the neutral **down-contact** pose. The three new frames are:

- **Frame 2** — contact — left foot planted forward, right foot lifting off behind, weight shifting onto the front leg, arms beginning to counter-swing.
- **Frame 3** — passing — legs closest together, the lifted foot passing the planted ankle, body at the top of its stride, arms near neutral.
- **Frame 4** — contact mirrored — right foot planted forward, left foot lifting off behind, the opposite arm leading.

Played at 0.11s per frame, matching the player. Frame 4 must loop cleanly back
into frame 1, so keep the stride length identical between the two contact poses.

---

## Guards — 7 archetypes x 3 frames = 21 files

### `guard_default`

Generic mall-cop security guard: navy uniform shirt, dark utility trousers, duty belt, peaked cap.

- Canvas **256x320**, content height **214px (±4)**, feet_y **260 (±3)**, centre column **126 (±5)**
- Reference: `guard_default.png`

  - `guard_default_2.png` — contact — left foot planted forward, right foot lifting off behind, weight shifting onto the front leg, arms beginning to counter-swing.
  - `guard_default_3.png` — passing — legs closest together, the lifted foot passing the planted ankle, body at the top of its stride, arms near neutral.
  - `guard_default_4.png` — contact mirrored — right foot planted forward, left foot lifting off behind, the opposite arm leading.

### `guard_clipboard_enforcer`

Officious inspector clutching a clipboard to the chest, lanyard ID, short-sleeve uniform shirt.

- Canvas **256x320**, content height **212px (±4)**, feet_y **252 (±3)**, centre column **128 (±5)**
- Reference: `guard_clipboard_enforcer.png`

  - `guard_clipboard_enforcer_2.png` — contact — left foot planted forward, right foot lifting off behind, weight shifting onto the front leg, arms beginning to counter-swing.
  - `guard_clipboard_enforcer_3.png` — passing — legs closest together, the lifted foot passing the planted ankle, body at the top of its stride, arms near neutral.
  - `guard_clipboard_enforcer_4.png` — contact mirrored — right foot planted forward, left foot lifting off behind, the opposite arm leading.

### `guard_flashlight_cadet`

Young rookie sweeping a heavy flashlight low, oversized uniform, tall lanky frame.

- Canvas **256x320**, content height **256px (±4)**, feet_y **293 (±3)**, centre column **129 (±5)**
- Reference: `guard_flashlight_cadet.png`

  - `guard_flashlight_cadet_2.png` — contact — left foot planted forward, right foot lifting off behind, weight shifting onto the front leg, arms beginning to counter-swing.
  - `guard_flashlight_cadet_3.png` — passing — legs closest together, the lifted foot passing the planted ankle, body at the top of its stride, arms near neutral.
  - `guard_flashlight_cadet_4.png` — contact mirrored — right foot planted forward, left foot lifting off behind, the opposite arm leading.

### `guard_radio_guy`

Stocky guard holding a shoulder radio to the mouth, bulky vest, thick forearms.

- Canvas **256x320**, content height **185px (±4)**, feet_y **241 (±3)**, centre column **129 (±5)**
- Reference: `guard_radio_guy.png`

  - `guard_radio_guy_2.png` — contact — left foot planted forward, right foot lifting off behind, weight shifting onto the front leg, arms beginning to counter-swing.
  - `guard_radio_guy_3.png` — passing — legs closest together, the lifted foot passing the planted ankle, body at the top of its stride, arms near neutral.
  - `guard_radio_guy_4.png` — contact mirrored — right foot planted forward, left foot lifting off behind, the opposite arm leading.

### `guard_segway_sentinel`

Guard standing on a two-wheeled personal transporter, knees slightly bent, hands on the stalk grips.

- Canvas **256x320**, content height **192px (±4)**, feet_y **250 (±3)**, centre column **132 (±5)**
- Reference: `guard_segway_sentinel.png`

  - `guard_segway_sentinel_2.png` — contact — left foot planted forward, right foot lifting off behind, weight shifting onto the front leg, arms beginning to counter-swing.
  - `guard_segway_sentinel_3.png` — passing — legs closest together, the lifted foot passing the planted ankle, body at the top of its stride, arms near neutral.
  - `guard_segway_sentinel_4.png` — contact mirrored — right foot planted forward, left foot lifting off behind, the opposite arm leading.

### `guard_supervisor_on_break`

Heavyset supervisor mid-break, coffee cup in one hand, shirt untucked, jacket open and wide.

- Canvas **256x320**, content height **233px (±4)**, feet_y **268 (±3)**, centre column **130 (±5)**
- Reference: `guard_supervisor_on_break.png`

  - `guard_supervisor_on_break_2.png` — contact — left foot planted forward, right foot lifting off behind, weight shifting onto the front leg, arms beginning to counter-swing.
  - `guard_supervisor_on_break_3.png` — passing — legs closest together, the lifted foot passing the planted ankle, body at the top of its stride, arms near neutral.
  - `guard_supervisor_on_break_4.png` — contact mirrored — right foot planted forward, left foot lifting off behind, the opposite arm leading.

### `guard_tactical_polo`

Contractor in a tight tactical polo and cargo trousers, earpiece coil, squared shoulders.

- Canvas **256x320**, content height **242px (±4)**, feet_y **278 (±3)**, centre column **127 (±5)**
- Reference: `guard_tactical_polo.png`

  - `guard_tactical_polo_2.png` — contact — left foot planted forward, right foot lifting off behind, weight shifting onto the front leg, arms beginning to counter-swing.
  - `guard_tactical_polo_3.png` — passing — legs closest together, the lifted foot passing the planted ankle, body at the top of its stride, arms near neutral.
  - `guard_tactical_polo_4.png` — contact mirrored — right foot planted forward, left foot lifting off behind, the opposite arm leading.

---

## Boss — 3 files

### `boss_default`

Surveillance Director boss: long dark coat, augmented visor rig, imposing upright posture.

- Canvas **320x384**, content height **306px (±4)**, feet_y **343 (±3)**, centre column **159 (±5)**
- Reference: `boss_default.png`

The boss moves with weight and menace — a slower, heavier stride than the guards.
Keep the coat hem trailing the leg motion by roughly one frame so it reads as cloth.

  - `boss_default_2.png` — contact — left foot planted forward, right foot lifting off behind, weight shifting onto the front leg, arms beginning to counter-swing.
  - `boss_default_3.png` — passing — legs closest together, the lifted foot passing the planted ankle, body at the top of its stride, arms near neutral.
  - `boss_default_4.png` — contact mirrored — right foot planted forward, left foot lifting off behind, the opposite arm leading.

---

## Delivery

Flat folder of 24 PNGs named exactly as above. No subfolders, no frame_01 style
names — the engine resolves frame 1 as the bare stem and frames 2+ as `stem_N`.

On arrival each file is checked for: RGBA alpha channel, absence of magenta,
content height and feet baseline against the numbers above. Frames that drift
get geometrically normalised by `scripts/normalize_frame_banks.py`, but that
cannot repair a wardrobe or lighting mismatch — those need regenerating.
