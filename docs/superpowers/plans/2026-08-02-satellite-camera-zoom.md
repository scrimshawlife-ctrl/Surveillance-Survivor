# Satellite Camera Zoom Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Zoom the default play camera out to a fixed satellite-map scale (~1.38) so more of the urban arena is visible, without changing simulation or combat rules.

**Architecture:** Single presentation constant on `GameScene` applied to `SKCameraNode`. Blind Spot wayfinding uses scale-aware world half-extents. Follow/smoothing behavior unchanged.

**Tech Stack:** Swift 6, SpriteKit, Swift Testing (`SurveillanceSurvivorTests`), XcodeGen.

**Spec:** [`docs/superpowers/specs/2026-08-02-satellite-camera-zoom-design.md`](../specs/2026-08-02-satellite-camera-zoom-design.md)

## Global Constraints

- Presentation only — no `SurveillanceCore` mutation, no combat/spawn/collision changes.
- Fixed scale for whole run: **no** pinch, combat zoom, or idle zoom.
- `satelliteCameraScale = 1.38` (tune only this constant after device glance).
- SpriteKit: camera scale **> 1** = zoom **out** (more world visible).
- Reduced motion: disable camera **smoothing only**; zoom stays applied.
- Blind Spot compass: on-screen test must use `viewSize * cameraScale` in world units.
- Prefer small focused commits; run `SurveillanceSurvivorTests` after code tasks.
- Work on `feat/urban-arena-presentation` worktree; do not thrash shared `main` without owner request.
- Do not invent launch READY.

## File map

| Path | Responsibility |
| --- | --- |
| `Game/Scenes/GameScene.swift` | Apply scale; pass scale into `blindSpotMarker`; optional `didChangeSize` |
| `Tests/SurveillanceSurvivorTests/BlindSpotWayfindingTests.swift` | Scale-aware marker geometry tests |
| `Tests/SurveillanceSurvivorTests/BlindSpotCompassWiringTests.swift` | Optional: assert camera scale after setup |
| `docs/arena/URBAN_DRESS.md` or checklist | One-line camera scale note (optional, Task 3) |

---

### Task 1: Scale-aware Blind Spot marker (TDD) + apply camera scale

**Files:**
- Modify: `Game/Scenes/GameScene.swift`
- Modify: `Tests/SurveillanceSurvivorTests/BlindSpotWayfindingTests.swift`
- Modify: `Tests/SurveillanceSurvivorTests/BlindSpotCompassWiringTests.swift` (optional assert)

**Interfaces:**
- Produces:
  - `GameScene.satelliteCameraScale: CGFloat = 1.38` (static)
  - `GameScene.blindSpotMarker(cameraCentre:exit:viewSize:cameraScale:)` with default `cameraScale: CGFloat = 1` for back-compat, production passes live scale
- Consumes: existing follow camera, compass wiring

- [ ] **Step 1: Write failing tests**

Update `BlindSpotWayfindingTests.swift`:

```swift
import SpriteKit
import Testing
@testable import SurveillanceCore
@testable import SurveillanceSurvivor

@MainActor
struct BlindSpotWayfindingTests {
    private let viewSize = CGSize(width: 844, height: 390)
    private let satelliteScale = GameScene.satelliteCameraScale

    @Test func anExitAlreadyOnScreenIsNotMarked() {
        let marker = GameScene.blindSpotMarker(
            cameraCentre: .zero,
            exit: CGPoint(x: 120, y: 40),
            viewSize: viewSize,
            cameraScale: 1
        )
        #expect(marker == nil)
    }

    @Test func satelliteScaleTreatsFartherExitsAsOnScreen() {
        // At scale 1.0, half-width ≈ 422; exit at x=500 is off-screen.
        // At satellite scale, half-width ≈ 422 * 1.38 ≈ 582; exit at 500 is on-screen.
        let exit = CGPoint(x: 500, y: 0)
        #expect(GameScene.blindSpotMarker(
            cameraCentre: .zero, exit: exit, viewSize: viewSize, cameraScale: 1
        ) != nil)
        #expect(GameScene.blindSpotMarker(
            cameraCentre: .zero, exit: exit, viewSize: viewSize, cameraScale: satelliteScale
        ) == nil)
    }

    @Test func anOffScreenExitIsMarkedInItsDirection() {
        let cases: [(CGPoint, String)] = [
            (CGPoint(x: 1_500, y: 0), "east"),
            (CGPoint(x: -1_500, y: 0), "west"),
            (CGPoint(x: 0, y: 900), "north"),
            (CGPoint(x: 0, y: -900), "south"),
            (CGPoint(x: -1_200, y: 700), "north-west")
        ]
        for (exit, label) in cases {
            guard let marker = GameScene.blindSpotMarker(
                cameraCentre: .zero,
                exit: exit,
                viewSize: viewSize,
                cameraScale: satelliteScale
            ) else {
                Issue.record("\(label) exit at \(exit) must be marked")
                continue
            }
            let expected = atan2(exit.y, exit.x)
            #expect(abs(marker.rotation - expected) < 0.0001, "\(label) bearing wrong")
            // Marker position is in camera/local space (unscaled scene half-size).
            #expect(abs(marker.position.x) <= viewSize.width / 2, "\(label) marker left the screen")
            #expect(abs(marker.position.y) <= viewSize.height / 2, "\(label) marker left the screen")
        }
    }

    @Test func theMarkerTracksTheExitAsThePlayerMoves() {
        let exit = CGPoint(x: 600, y: 0)
        for x in stride(from: -600.0, through: 0.0, by: 150.0) {
            let marker = GameScene.blindSpotMarker(
                cameraCentre: CGPoint(x: x, y: 0),
                exit: exit,
                viewSize: viewSize,
                cameraScale: satelliteScale
            )
            guard let marker else {
                Issue.record("exit \(600 - x) away should still be marked under satellite scale")
                continue
            }
            #expect(abs(marker.rotation) < 0.0001, "should point due east from \(x)")
        }
        // Standing near exit: with satellite scale, halfW≈582 so x=590 is on-screen.
        #expect(GameScene.blindSpotMarker(
            cameraCentre: CGPoint(x: 590, y: 0),
            exit: exit,
            viewSize: viewSize,
            cameraScale: satelliteScale
        ) == nil, "standing on/near the exit must clear the marker")
    }
}
```

Add to `BlindSpotCompassWiringTests.swift` after scene setup test (or new test):

```swift
@Test func satelliteCameraScaleIsAppliedOnSetup() {
    let scene = scene(extractionAt: .init(x: 1_500, y: 0), playerAt: .init())
    let scale = scene.camera?.xScale ?? 0
    #expect(abs(scale - GameScene.satelliteCameraScale) < 0.001)
}
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
cd /path/to/feat/urban-arena-presentation
xcodegen generate
xcodebuild test -project SurveillanceSurvivor.xcodeproj -scheme SurveillanceSurvivor \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:'SurveillanceSurvivorTests' \
  CODE_SIGNING_ALLOWED=NO
```

Expected: compile fail (`satelliteCameraScale` / `cameraScale` missing) or assertion fail on scale.

- [ ] **Step 3: Implement**

In `GameScene.swift`:

1. Add near camera property:

```swift
/// Fixed satellite-map zoom-out. SpriteKit: scale > 1 shows more world.
static let satelliteCameraScale: CGFloat = 1.38
```

2. In `didMove(to:)` after camera is parented:

```swift
applySatelliteCameraScale()
```

3. Add:

```swift
private func applySatelliteCameraScale() {
    followCamera.setScale(Self.satelliteCameraScale)
}

override func didChangeSize(_ oldSize: CGSize) {
    super.didChangeSize(oldSize)
    applySatelliteCameraScale()
}
```

4. Change `blindSpotMarker` signature and body:

```swift
static func blindSpotMarker(
    cameraCentre: CGPoint,
    exit: CGPoint,
    viewSize: CGSize,
    cameraScale: CGFloat = 1
) -> (position: CGPoint, rotation: CGFloat)? {
    let dx = exit.x - cameraCentre.x
    let dy = exit.y - cameraCentre.y
    let scale = max(cameraScale, 0.001)
    let halfWidth = (viewSize.width / 2) * scale
    let halfHeight = (viewSize.height / 2) * scale
    guard abs(dx) > halfWidth - 40 || abs(dy) > halfHeight - 40 else { return nil }
    let angle = atan2(dy, dx)
    // Marker offset is in camera local space (screen half-size, not world).
    let radiusX = max(24, viewSize.width / 2 - 46)
    let radiusY = max(24, viewSize.height / 2 - 46)
    return (CGPoint(x: cos(angle) * radiusX, y: sin(angle) * radiusY), angle)
}
```

5. Call site in `updateBlindSpotCompass`:

```swift
let marker = Self.blindSpotMarker(
    cameraCentre: cameraCentre,
    exit: CGPoint(x: CGFloat(exit.position.x), y: CGFloat(exit.position.y)),
    viewSize: size,
    cameraScale: followCamera.xScale
)
```

- [ ] **Step 4: Run tests — expect PASS**

Same `xcodebuild test` command. Fix until green (full `SurveillanceSurvivorTests`).

- [ ] **Step 5: Commit**

```bash
git add Game/Scenes/GameScene.swift \
  Tests/SurveillanceSurvivorTests/BlindSpotWayfindingTests.swift \
  Tests/SurveillanceSurvivorTests/BlindSpotCompassWiringTests.swift
git commit -m "feat(presentation): fixed satellite camera zoom scale 1.38"
```

---

### Task 2: Docs note + device smoke (when phone available)

**Files:**
- Modify: `docs/arena/URBAN_DRESS.md` (short “Camera” subsection) **or** `docs/arena/ARENA_QUALITY_CHECKLIST.md` tip table

- [ ] **Step 1: Document**

Add to `URBAN_DRESS.md`:

```markdown
## Camera (presentation)

Default play uses a fixed satellite zoom: `GameScene.satelliteCameraScale = 1.38`
on `SKCameraNode` (scale > 1 = more world visible). Simulation units and
collision are unchanged; entities appear slightly smaller on screen.
Blind Spot on-screen tests multiply view half-size by camera scale.
```

- [ ] **Step 2: Device smoke** (if phone connected)

```bash
DEVELOPMENT_TEAM=X9M969D8M3 make device-smoke
```

Record PASS/SKIP in checklist tip table with short SHA. Operator visual: more map, streets readable, player findable. **No READY claim.**

- [ ] **Step 3: Commit**

```bash
git commit -m "docs(arena): satellite camera scale note and device tip"
```

If device unavailable, docs-only commit is fine; note SKIP.

---

### Task 3: Final verification

- [ ] **Step 1:**

```bash
make launch-gate-check   # may stay LAUNCH_BLOCKED
xcodebuild test -project SurveillanceSurvivor.xcodeproj -scheme SurveillanceSurvivor \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:'SurveillanceSurvivorTests' CODE_SIGNING_ALLOWED=NO
```

- [ ] **Step 2:** Confirm no Core files changed (`git diff --stat` should be Game/ + Tests/ + docs only).

- [ ] **Step 3:** No READY invention; leave branch local unless owner requests PR.

---

## Spec coverage

| Spec item | Task |
| --- | --- |
| Scale 1.38 fixed | 1 |
| Apply on setup / size change | 1 |
| Follow unchanged | 1 (no change to lerp) |
| Compass scale-aware | 1 |
| Reduced motion smoothing only | 1 (no scale toggle) |
| Tests | 1 |
| Docs + device glance | 2 |
| No READY / sim untouched | Global + 3 |

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-08-02-satellite-camera-zoom.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks  
2. **Inline Execution** — this session with checkpoints  

Which approach?
