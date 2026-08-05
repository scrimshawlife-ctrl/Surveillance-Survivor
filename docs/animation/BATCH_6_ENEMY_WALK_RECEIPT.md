# Batch 6 receipt — enemy walk cycles

**Date:** 2026-08-04
**Base:** `origin/main` @ `82ea482`
**Branch:** `prabu/animation-integration-and-isolation`
**Scope:** guard + boss walk banks, wired and status-corrected

## What shipped

24 PNGs: seven guard archetypes and the boss, three new frames each. Frame 1 was
already on disk and is unchanged; frames 2–4 complete the cycle.

| Bank | Frames | Canvas |
| --- | --- | --- |
| `guard_default` | 4 | 256x320 |
| `guard_clipboard_enforcer` | 4 | 256x320 |
| `guard_flashlight_cadet` | 4 | 256x320 |
| `guard_radio_guy` | 4 | 256x320 |
| `guard_segway_sentinel` | 4 | 256x320 |
| `guard_supervisor_on_break` | 4 | 256x320 |
| `guard_tactical_polo` | 4 | 256x320 |
| `boss_default` | 4 | 320x384 |

## Why there was no code to write

`EntityProjector.applyGuardAppearance` and `applyBossAppearance` already resolved
their texture through `OptionalSpriteFrameCycle`. With only the stem on disk the
probe returned 1 and every frame drew the same still — the enemies "drifting"
was missing art, not missing wiring. `probeLimit` was already 16.

The one change made was a gate: frames now advance only while
`EntityAnimationStateMachine.hostileState(entity:) == .moving`. Without it a
halted guard marches on the spot. The threshold is read from the existing state
machine rather than re-derived, so presentation does not invent its own idea of
movement.

## Intake validation

Every frame checked against the frame-1 reference before wiring:

| Check | Result |
| --- | --- |
| Canvas matches frame 1 | 24/24 |
| Content height within ±4px | 24/24 — all exactly +0 |
| Feet baseline within ±3px | 24/24 — all exactly +0 |
| Horizontal centre within ±5px | 24/24 — all exactly +0 |
| RGBA alpha channel present | 24/24 |
| Magenta pixels (chroma sentinel) | 0 in all 24 |
| Real frame-to-frame change vs frame 1 | 7.4%–27.4%, all 8 banks |
| Palette drift across frames | ≤10.7 on 7 banks |

`guard_flashlight_cadet` measured 14.2 palette drift and was inspected rather
than rejected: the variance is the flashlight beam brightening and lengthening
through the cycle, which is the intended motion. Uniform, skin and hair are
unchanged.

This intake bar exists because the player walk banks failed it. Those arrived as
four independent illustrations — frame 1 at 485px tall against ~340px for frames
2–4, in three different outfits — so the player resized 30% and hopped up to
100px per step. Batch 6 was specified with per-archetype pixel targets to prevent
a repeat, and came back with zero drift.

## Verification

- `assets-check`, `sprite-chroma-check`, `art-qa-check`, `animation-check`,
  `weapon-vfx-check`, `version-check`: **PASS**
- App test suite: **433 tests, 0 failures**
- Isolation regression (`SKPhysics|physicsBody|physicsWorld|contactTestBitMask|collisionBitMask`
  under `Game/` and `App/`): **zero matches**
- Simulator, Wichita combat, static camera: guard regions change 5.9%–48.2%
  across successive frames where they previously changed 0%.

## Test contract change

`OptionalSpriteFrameCycleTests` asserted guards and the boss were still-only
(`availableFrameCount == 1`, `<= 1`). Those assertions encoded the absence of art
and are now inverted to assert the banks are attached and that one period visits
every frame exactly once. Two tests added: full-roster bank coverage, so a
partially-delivered roster fails loudly rather than animating some archetypes and
freezing others; and the movement gate threshold.

## Manifest

- `guard.patrol`: `single_frame_present` → `runtime_integrated`
- `boss.patrol`: **new row**. The boss walk had no manifest entry — only
  `boss.telegraph.primary` — so what shipped would otherwise have gone unrecorded.

## Known gaps

- Both banks are 4 frames against `target_frames [6, 10]`, the same shortfall
  `player.walk.*` carries. Animation is correct; it is simply shorter than target.
- Guards have no directional variants and do not flip on heading, so the cycle
  reads the same regardless of travel direction. Pre-existing, not introduced here.
- Device QA not run. Simulator only.

## Reduced motion

Doctrine requires reduced-motion coverage, and cycles previously advanced
regardless of the setting. `PresentationQualityTier.advancesSpriteFrameCycles`
now returns false for `.minimal`, which is what `reducedMotion: true` resolves
to, and the guard, boss and player cycles all consult it — the sprite holds
frame 1 rather than looping limb animation. Frame index is presentation-only, so
holding it cannot affect hits or timing.

The player cycle was covered too. Its omission predates this batch, but it is the
same doctrine and the same one-line gate, so fixing only the enemies would have
left the setting half-honoured.

Reduced *flash* is untouched: these are walk cycles with no flash content.

---

# Addendum — event clip integration

Five clips shipped as PNGs in #159 that nothing selected. The manifest recorded
them as `missing`, which read as "no art" when the art was on disk the whole
time. `AnimationClipCatalog` is the selection step.

| Clip | Bank | Frames | Trigger | Playback |
| --- | --- | --- | --- | --- |
| `player.defeat` | `player_defeat` | 10 | state `.defeated` | one-shot, holds last |
| `player.extract` | `player_extract` | 10 | state `.extracting` | one-shot, holds last |
| `player.damage` | `player_damage` | 4 | observed health decrease | one-shot, then returns to atlas |
| `lpr.scan` | `lpr_scan_loop` | 6 | state `.scanning` | loop |
| `lpr.destroy` | `lpr_destroy_sequence` | 10 | state `.destroyed` | one-shot, holds last |

Every trigger is an `EntityAnimationState` already derived from authoritative
fields, so no new simulation state was introduced. The catalog reads state; it
never produces it. Clip identity and frame index have no bearing on hits, damage
or timing.

`player.damage` is deliberately **not** bound to `.damaged`. That state is the
sustained "health below 30" condition — binding a hit reaction there would freeze
the walk cycle for the rest of the run. It triggers on an observed health
decrease and clears when the one-shot completes.

Fallbacks are intact: a clip whose bank is absent resolves to its bare stem, and
the LPR shape-node fallback is untouched. `missingBankDegradesToTheStillNotToNothing`
covers that path.

## Verification

- 440 tests pass, including 6 new clip tests
- Simulator, static camera: LPR region changes 5.7%–16.1% across successive
  frames over 6 distinct levels, confirming the scan loop cycles rather than
  swapping once
- One-shots are covered by test rather than screenshot — they need events that a
  fixed capture cannot reliably provoke
- `animation-check` required player clip stems to be declared, so
  `GameAssetName.Player.damage/defeat/extract` were added as a `clips` list, kept
  separate from `all` (the directional poses the locomotion state machine picks
  between)

## Test contract change

`entityProjectorAttachesMappedPlayerAndLPRSprites` asserted the LPR body was
`lpr_intact`. A healthy pole is scanning, so it now plays the loop; that
assertion recorded the absence of the scan bank rather than intended behaviour.
It accepts any scan frame or the still, and separately asserts the still stays
resolvable so the fallback cannot rot.

## Not wired

| Clip | Frames on disk | Why not |
| --- | --- | --- |
| `boss.telegraph.primary` | 8 | Needs a telegraph event from boss wind-up; no entity state corresponds |
| `fx.blind_spot.open` | 12 | Needs a spawned effect node, not an entity texture swap |
| `fx.impact.hardware` | 6 | Needs a transient effect spawned at an impact point |
| `weapon.redaction.field` | 8 | Needs deployable-field lifecycle wiring |

These four need an effect-spawning layer rather than entity-state mapping, which
is a larger change than this batch. Their statuses are left `missing`/`reserved`
rather than promoted, because the frames still do not play.
