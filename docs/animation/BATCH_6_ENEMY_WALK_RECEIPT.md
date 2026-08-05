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

---

# Addendum 2 — transient effect layer

The four clips left unwired in the previous addendum now play. They were stuck
because they are not any entity's texture: an impact spark, a Blind Spot opening
and a boss telegraph belong to a moment, so `EntityProjector` had nowhere to put
them. `TransientEffectProjector` owns them.

| Clip | Bank | Frames | Trigger | Playback | Depth |
| --- | --- | --- | --- | --- | --- |
| `fx.blind_spot.open` | `fx_blind_spot_open` | 12 | extraction entity first appears | one-shot | overlay |
| `fx.impact.hardware` | `fx_impact_surveillance_hardware` | 6 | cameraPole health decrease | one-shot | overlay |
| `boss.telegraph.primary` | `boss_telegraph_primary` | 8 | `BossPhase` change | one-shot | ground |
| `weapon.redaction.field` | `fx_redaction_field` | 8 | camera `sensorDisabledUntilTick` set | **loop** | ground |

## Two depths, not one

A boss telegraph must sit *under* the boss — it is ground the boss stands on, and
drawing it over the body hides the thing being telegraphed. The redaction field
is the same: a low-opacity world-space mask that must not obscure what it
affects. Impacts and the Blind Spot opening are the opposite; they happen *to*
something and belong above it, over projectiles so a hit is never hidden by the
shot that caused it. `VisualCombatLayers.groundEffect` (1.5) and
`overlayEffect` (40) bracket the entity range.

## The redaction field is not a burst

`redactionOrdinance`'s payload is `disableCameraSensors` with a tick duration, so
there is no redaction *entity* to attach to — the field belongs to the camera for
exactly as long as its sensors stay dark. It attaches on
`sensorDisabledUntilTick`, follows the camera, and detaches when the camera
recovers or despawns. That last case matters: an attached loop whose owner
vanished would hang in the scene for the rest of the run.

## Why health, not events

`RunEvent` carries a kind and a message but no position, and an impact has to
land on the hardware that was struck. So impacts trigger on an observed health
decrease — the same mechanism as the player hit reaction — rather than on
`.countermeasureHit`. Presentation observing simulation truth, never producing
it.

## Isolation

Every trigger is a transition in authoritative state: an entity appearing, health
falling, a phase changing, a sensor going dark. No effect's presence, position or
frame index feeds back into hits, damage or timing, and the whole layer can be
deleted without altering a run. Isolation grep stays clean.

Reduced motion holds effects on frame 1 via the same
`advancesSpriteFrameCycles` gate. Reduced flash drops effect alpha from 0.85 to
0.45 — these banks carry scan and spark content, and the manifest marks
`fx_blind_spot_open` reduced-flash sensitive.

## Verification

447 tests pass, including 7 new effect tests. The one that matters most is
`effectsDoNotAccumulateAcrossASustainedRun`: 300 frames of repeated camera damage
must leave fewer than 8 live effect nodes. A burst that never retires would add a
node per frame, which is the failure mode this layer could most easily have.

Others cover: the Blind Spot firing exactly once rather than every frame; impacts
not re-firing while a damaged camera sits still; the field surviving past one loop
period; the field detaching on recovery and on despawn; the telegraph firing on
phase transition only; and `reset()` clearing everything so a new run cannot
inherit a half-played clip.

## Gate changes

- `validate_weapon_vfx_manifest.py` pinned the runtime-addressable stem set to
  three entries; the three effect banks are now addressable and were added.
- The VFX manifest's scope vocabulary is `runtime_addressable` / `reserved` —
  `runtime_present` belongs to the gameplay manifest. Corrected after the
  validator caught it.
- Runtime-addressable stems must be registered in `GameAssetName`, so
  `GameAssetName.Effect` was added and the projector references it rather than
  raw strings.

## Still not wired

`weapon.transponder.deploy` and `weapon.foia.flight` remain `reserved`. Their
manifest stems have no frames on disk, so these are genuinely missing art rather
than status debt.

## Not verified

Effects are covered by test, not by screenshot. Each needs an event a fixed
capture cannot reliably provoke — a boss phase change, a camera being shot, the
Blind Spot opening. Device QA is still not run.
