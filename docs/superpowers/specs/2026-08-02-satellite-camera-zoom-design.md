# Satellite camera zoom (fixed default) — design

**Date:** 2026-08-02  
**Product:** Surveillance Survivor  
**Status:** Design approved (brainstorm)  
**Branch context:** `feat/urban-arena-presentation` (presentation isolation; coordinate with concurrent collaborators)  
**Related:** urban arena dress (`2026-08-02-urban-arena-presentation-design.md`); `GameScene` `SKCameraNode` follow

---

## 1. Purpose, success, non-goals

### Purpose

Zoom the play camera out so the arena reads more like a **satellite map** over city blocks and two-way streets, without changing simulation, collision, or combat rules.

### Success

| Criterion | Pass means |
| --- | --- |
| Zoom | Default play shows **~30–45% more world** than scale 1.0 (target **scale 1.38**) |
| Fixed | Same scale for entire run; no combat/idle zoom, no pinch |
| Follow | Camera still player-centered (smooth follow when allowed) |
| HUD chrome | Blind Spot compass on-screen test uses **effective** viewport (scene size × camera scale) |
| Sim contract | No Core mutation; no balance/spawn changes |
| Accessibility | Reduced motion still disables **smoothing only**; zoom stays fixed |
| Device | Readable threats/player on physical iPhone landscape after deploy |

### Non-goals

- Pinch zoom, settings slider, or dynamic combat zoom  
- Fitting full district bounds on screen  
- Changing stick, HUD layout, or world generation  
- Inventing launch READY  

---

## 2. Current system

```text
GameScene
  scaleMode = .resizeFill
  followCamera = SKCameraNode()   // scale 1.0 today
  followCamera.position → player (smooth or snap)
  blindSpotCompass child of camera (screen-space offset)

blindSpotMarker(cameraCentre, exit, viewSize):
  halfWidth/Height = viewSize/2
  "on screen" if exit within half − margins
```

With scale 1.0, only a fraction of a large district (~1800×1080-class) is visible — combat-close, weak satellite read of streets/blocks.

**SpriteKit note:** `SKCameraNode` scale **> 1** shows **more** world (zoom out).

---

## 3. Architecture (Approach 1 — fixed camera scale)

### 3.1 Single constant

```swift
// GameScene (or small CameraPresentation helper)
static let satelliteCameraScale: CGFloat = 1.38
```

Apply once when the camera is attached / scene is presented / `size` is set:

```swift
followCamera.setScale(Self.satelliteCameraScale)
```

Re-apply in `didChangeSize` if needed so resize keeps the same scale.

### 3.2 Follow (unchanged semantics)

- Snap on district/session reset  
- Smooth lerp when `tier.allowCameraSmoothing && !reducedMotion`  
- Position only; **do not** animate scale  

### 3.3 Effective viewport

Visible half-extents in **world** units:

```text
halfWidthWorld  = (scene.size.width  / 2) * followCamera.xScale
halfHeightWorld = (scene.size.height / 2) * followCamera.yScale
```

Use this for:

- `blindSpotMarker` on-screen test and edge ellipse radii  
- Any future edge chrome that assumes “screen half-size in world space”

API shape (minimal change):

```swift
static func blindSpotMarker(
    cameraCentre: CGPoint,
    exit: CGPoint,
    viewSize: CGSize,
    cameraScale: CGFloat = 1
) -> (position: CGPoint, rotation: CGFloat)?
```

Implementation multiplies half-width/height by `max(cameraScale, 0.001)`. Call site passes `followCamera.xScale` (or the constant).

Compass node stays parented to the camera (offset in camera/local space); only the **world-space “is exit on screen?”** math needs scale.

### 3.4 What does **not** change

| Layer | Status |
| --- | --- |
| Simulation positions, radii, collision | Unchanged |
| UrbanDress / WorldProjector | Unchanged (already draws full layout) |
| Entity sprites | Same world size; appear smaller on screen because camera zoomed out |
| Stick / SwiftUI HUD | Unchanged (screen space) |

---

## 4. Tuning

| Knob | Initial | Notes |
| --- | ---: | --- |
| `satelliteCameraScale` | **1.38** | Mid of 30–45% band; one-constant retune after device glance |
| Floor | 1.30 | Do not ship below without re-checking “satellite” read |
| Ceiling | 1.45 | Above this, combat readability risk rises |

If device glance says too far / too close: change **only** this constant; no algorithm change.

---

## 5. Testing

| Test | Expectation |
| --- | --- |
| Unit: blind spot on-screen | With scale 1.38, exits that were near the old edge may count as on-screen — update expectations using scaled half-extents |
| Unit: blind spot off-screen marker | Far exit still returns marker; radii scale with cameraScale |
| Wiring | Compass still attached to camera |
| Optional | Assert `followCamera.xScale` ≈ 1.38 after scene setup (MainActor test) |
| Device | Smoke deploy + operator glance: streets/blocks readable; player still findable |

Do not claim performance or READY from smoke alone.

---

## 6. Implementation sketch (for plan, not code yet)

1. Add `satelliteCameraScale` and apply on camera setup + size change.  
2. Thread `cameraScale` into `blindSpotMarker` + call site.  
3. Adjust `BlindSpotWayfindingTests` for scaled viewport.  
4. Run `SurveillanceSurvivorTests`; device-smoke on feature branch when phone available.  
5. Short note in `docs/arena/URBAN_DRESS.md` or checklist: camera scale is presentation-only.

---

## 7. Risks

| Risk | Mitigation |
| --- | --- |
| Threats hard to see when smaller | Cap scale ≤ 1.45; device glance before merge |
| Compass false “on screen” / off screen | Scale-aware half extents |
| Concurrent collaborators | Stay on `feat/urban-arena-presentation`; no main thrash |
| Touch targeting feels different | Stick is UIKit/SwiftUI overlay — unaffected |

---

## 8. Decision record

| Question | Choice |
| --- | --- |
| How much zoom? | **B** — clear satellite step (~30–45%) |
| Fixed vs dynamic? | **A** — fixed for whole run |
| Approach | **1** — fixed `SKCameraNode` scale |
| Initial scale | **1.38** |

---

## 9. Out of scope follow-ups

- District-specific scale tables  
- Fit-to-bounds satellite framing  
- Accessibility “zoom closer” preference (only if operators request after ship of fixed scale)  
