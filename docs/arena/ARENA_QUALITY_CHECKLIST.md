# Arena quality checklist (urban dress)

**Source:** design §7 in [`docs/superpowers/specs/2026-08-02-urban-arena-presentation-design.md`](../superpowers/specs/2026-08-02-urban-arena-presentation-design.md)  
**Architecture:** [`URBAN_DRESS.md`](URBAN_DRESS.md)  
**Asset alpha:** [`ARENA_ASSET_AUDIT.md`](ARENA_ASSET_AUDIT.md)

Acceptance for the **presentation-first urban grid** work. Checkboxes record engineering status against the design; they are **not** a READY launch claim, physical-iPhone certification, or product ship gate.

Legend: `[x]` implemented / evidenced in-repo · `[ ]` open or not fully evidenced · `~` partial

---

## Design §7 criteria

```text
[x] Continuous ground surface (city-tinted base covers bounds)
[x] Free space reads as connected road network (inferred)
[x] Every obstacle has sidewalk ring + building depth stack
[x] No landmark art squashed onto collision pads
[~] No opaque texture backgrounds on used building/landmark sprites
[x] Buildings have foundation + body + contact shadow (+ optional roof)
[x] Collision still matches WorldObstacle AABBs exactly
[ ] Spawn / extraction free-space not visually sealed (presentation check)
[x] Deterministic UrbanDress for fixed layout
[x] Existing gameplay tests pass (tip 1e706ba; full suite green)
[x] New UrbanDress unit tests pass (tip 1e706ba; full suite green)
[x] Documentation describes dress vs sim separation
```

---

## Tip verification (Task 7 + device-smoke)

| Check | Result |
| --- | --- |
| Tip (suite) | `1e706ba` — full `SurveillanceSurvivorTests` green |
| Tip (device-smoke) | `c3ae907` — physical dual-launch liveness |
| `make launch-gate-check` | **PASS** script; overall **`LAUNCH_BLOCKED`** (honest; not READY) |
| `SurveillanceSurvivorTests` | **425 tests / 10 suites — TEST SUCCEEDED** (iPhone 17 Simulator, `CODE_SIGNING_ALLOWED=NO`) |
| Physical device smoke | **PASS** on `c3ae907` — deploy + dual-launch (`00008150-000A6C120CB8401C`); receipt under worktree `.device-smoke/` |
| Operator visual glance | **Open** — smoke is not floor/building readability sign-off |
| UrbanDress tests | All builder + projector UrbanDress cases passed within suite |
| READY claim | **None** — presentation work does not invent launch READY |

---

## Notes per item

| Criterion | Evidence / gap |
| --- | --- |
| Continuous ground | `WorldProjector.renderGround` draws city-tinted `urban-ground-base` over layout bounds; sparse terrain stamps only |
| Inferred roads | `UrbanDressBuilder` gap projection → H/V bands + intersections; fallback full-bounds road if empty |
| Sidewalk + stack | Builder expands footprints by `sidewalkWidth`; `renderBuildings` emits shadow/foundation/body/parapet per id |
| No landmark on pads | Pads use geometric stack; optional retail mass only; landmarks/decals parent under `urban-props` |
| Opaque backgrounds | Landmark/prop clear-plate suspects repaired; **2 REVIEW** leftovers in `ARENA_ASSET_AUDIT.md` (not zero residual review) |
| Building depth | Named stack: `building-shadow`, `building-foundation`, `building-body`, `building-parapet` (optional retail skin, not full roof kit) |
| Collision AABB | No Core layout/collision change; dress never drives hit tests |
| Spawn/extract free | Design validation/flood-fill overlay not required for ship; **manual/presentation check still open** (device-smoke pass does not close this) |
| Determinism | `urbanDressIsDeterministic` + pure builder (no RNG) |
| Gameplay tests | Full `SurveillanceSurvivorTests` green on tip `1e706ba` (425 tests, 2026-08-01 Task 7) |
| UrbanDress tests | `UrbanDressBuilderTests` + `WorldProjectorUrbanDressTests` green on same tip/suite run |
| Docs | This checklist + `URBAN_DRESS.md` |

---

## Quick verification commands

```bash
# Narrow presentation tests (when Xcode toolchain available)
xcodebuild test \
  -scheme SurveillanceSurvivor \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:'SurveillanceSurvivorTests/UrbanDressBuilderTests' \
  -only-testing:'SurveillanceSurvivorTests/WorldProjectorUrbanDressTests'

make assets-check
make sprite-chroma-check
python3 scripts/audit_sprite_opaque_corners.py
```

---

## Explicit non-claims

- Not a Core `UrbanCellType` / city-grid sim rewrite  
- Not proof of physical-device readability, flash safety, or performance  
- Not “READY” launch or matrix-complete visual QA for all 10 districts  
- Alleys / plaza classification / debug overlay (`-UIDebugUrbanDress`) may still be incomplete vs design optional items  
