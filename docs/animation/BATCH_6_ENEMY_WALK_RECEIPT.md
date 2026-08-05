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
