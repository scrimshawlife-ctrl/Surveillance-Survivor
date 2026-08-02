# Urban Arena Presentation (City-Grid Dress) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every district arena read as a coherent urban grid (roads, sidewalks, building blocks with procedural depth) by dressing existing `WorldLayout` obstacle AABBs — without changing simulation collision or generation.

**Architecture:** Pure `UrbanDressBuilder` infers streets/sidewalks/building rings from `WorldLayout`. `WorldProjector` renders named layers (ground, road, sidewalk, building stack, props) from that dress. Simulation continues to own only `WorldLayout` AABBs.

**Tech Stack:** Swift 6, SpriteKit, SurveillanceCore (`WorldLayout`, `WorldObstacle`, `DistrictID`), Swift Testing in `SurveillanceSurvivorTests`, XcodeGen `project.yml`.

**Spec:** [`docs/superpowers/specs/2026-08-02-urban-arena-presentation-design.md`](../specs/2026-08-02-urban-arena-presentation-design.md)

## Global Constraints

- Preserve deterministic simulation behavior; do not change combat balance, spawns, or movement rules.
- Collision remains `WorldObstacle` AABBs only — never sprite pixels or `UrbanDress` cells.
- Presentation logic stays out of `SurveillanceCore` mutation (builder may live under `Game/Presentation/` and import Core types).
- No RNG in dress building (or only seed-stable hash of obstacle ids if variation is required; prefer zero RNG).
- Do not stretch/blur pixel art; nearest for characters, linear OK for soft ground.
- Do not squash landmark hangar/warehouse art onto pads.
- All 10 districts must work from existing `districts.json` layouts.
- Prefer small focused commits; run relevant tests after each task.
- Repo root: worktree or checkout in use.

## File map

| Path | Responsibility |
| --- | --- |
| `Game/Presentation/UrbanDress.swift` | **Create** — rect types, `UrbanDress`, `UrbanBuildingDress`, constants |
| `Game/Presentation/UrbanDressBuilder.swift` | **Create** — pure inference from `WorldLayout` |
| `Game/Rendering/WorldProjector.swift` | **Modify** — consume dress; layered render |
| `Game/Rendering/VisualCombatLayers.swift` | **Modify** — optional z constants for urban layers (or keep local z in projector) |
| `Tests/SurveillanceSurvivorTests/UrbanDressBuilderTests.swift` | **Create** — pure builder tests |
| `Tests/SurveillanceSurvivorTests/WorldProjectorUrbanDressTests.swift` | **Create** — layer node smoke |
| `docs/arena/ARENA_QUALITY_CHECKLIST.md` | **Create** — operator checklist |
| `docs/arena/ARENA_ASSET_AUDIT.md` | **Create** — landmark alpha notes (phase 5) |
| `project.yml` | **Modify only if** new files not auto-included by XcodeGen globs |

---

### Task 1: UrbanDress model + builder with TDD

**Files:**
- Create: `Game/Presentation/UrbanDress.swift`
- Create: `Game/Presentation/UrbanDressBuilder.swift`
- Create: `Tests/SurveillanceSurvivorTests/UrbanDressBuilderTests.swift`

**Interfaces:**
- Produces:
  - `struct UrbanRect: Equatable` with `minX,maxX,minY,maxY: Double` and helpers `contains`, `intersects`, `inset`, `expanded`
  - `struct UrbanBuildingDress: Equatable` — `obstacleID: UInt64`, `footprint: UrbanRect`, `sidewalkOuter: UrbanRect`
  - `struct UrbanDress: Equatable` — `bounds`, `roads`, `intersections`, `sidewalks`, `buildings`, `alleys`
  - `enum UrbanDressBuilder` with `static func build(layout: WorldLayout, district: DistrictID) -> UrbanDress`
- Constants: `sidewalkWidth: Double = 14`, `minRoadWidth: Double = 28` (tune once; document in code)

- [ ] **Step 1: Write failing tests**

Create `Tests/SurveillanceSurvivorTests/UrbanDressBuilderTests.swift`:

```swift
import Testing
import SurveillanceCore
@testable import SurveillanceSurvivor

@Test func urbanDressMapsEveryObstacleToBuilding() {
    let layout = WorldLayout(
        bounds: WorldBounds(minX: -200, maxX: 200, minY: -150, maxY: 150),
        obstacles: [
            WorldObstacle(id: 1, center: .init(x: -80, y: 40), halfSize: .init(x: 30, y: 25)),
            WorldObstacle(id: 2, center: .init(x: 90, y: -20), halfSize: .init(x: 40, y: 20))
        ]
    )
    let dress = UrbanDressBuilder.build(layout: layout, district: .wichita)
    #expect(dress.buildings.count == 2)
    #expect(Set(dress.buildings.map(\.obstacleID)) == [1, 2])
}

@Test func urbanDressSidewalkExpandsFootprint() {
    let layout = WorldLayout(
        bounds: WorldBounds(minX: -200, maxX: 200, minY: -200, maxY: 200),
        obstacles: [
            WorldObstacle(id: 7, center: .init(x: 0, y: 0), halfSize: .init(x: 20, y: 15))
        ]
    )
    let dress = UrbanDressBuilder.build(layout: layout, district: .louisville)
    let b = dress.buildings[0]
    #expect(b.footprint.minX == -20 && b.footprint.maxX == 20)
    #expect(b.sidewalkOuter.minX == -20 - UrbanDressBuilder.sidewalkWidth)
    #expect(b.sidewalkOuter.maxX == 20 + UrbanDressBuilder.sidewalkWidth)
}

@Test func urbanDressRoadsDoNotOverlapBuildingFootprints() {
    let layout = DistrictGenerator.generate(seed: 42, district: .wichita).layout
    let dress = UrbanDressBuilder.build(layout: layout, district: .wichita)
    for road in dress.roads {
        for building in dress.buildings {
            #expect(!road.intersectsInterior(of: building.footprint))
        }
    }
}

@Test func urbanDressIsDeterministic() {
    let layout = DistrictGenerator.generate(seed: 99, district: .newYorkCity).layout
    let a = UrbanDressBuilder.build(layout: layout, district: .newYorkCity)
    let b = UrbanDressBuilder.build(layout: layout, district: .newYorkCity)
    #expect(a == b)
}
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
xcodegen generate
xcodebuild test -project SurveillanceSurvivor.xcodeproj -scheme SurveillanceSurvivor \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:'SurveillanceSurvivorTests/UrbanDressBuilderTests' \
  CODE_SIGNING_ALLOWED=NO
```

Expected: compile fail or missing types.

- [ ] **Step 3: Implement model**

`Game/Presentation/UrbanDress.swift`:

```swift
import SurveillanceCore

struct UrbanRect: Equatable, Sendable {
    var minX: Double
    var maxX: Double
    var minY: Double
    var maxY: Double

    var width: Double { maxX - minX }
    var height: Double { maxY - minY }
    var center: Vector2 { Vector2(x: (minX + maxX) / 2, y: (minY + maxY) / 2) }

    init(minX: Double, maxX: Double, minY: Double, maxY: Double) {
        self.minX = minX; self.maxX = maxX; self.minY = minY; self.maxY = maxY
    }

    init(center: Vector2, halfSize: Vector2) {
        minX = center.x - halfSize.x
        maxX = center.x + halfSize.x
        minY = center.y - halfSize.y
        maxY = center.y + halfSize.y
    }

    func expanded(by m: Double) -> UrbanRect {
        UrbanRect(minX: minX - m, maxX: maxX + m, minY: minY - m, maxY: maxY + m)
    }

    func intersects(_ other: UrbanRect) -> Bool {
        minX < other.maxX && maxX > other.minX && minY < other.maxY && maxY > other.minY
    }

    /// True if interiors overlap (shared edge alone is OK for sidewalks vs pads).
    func intersectsInterior(of other: UrbanRect) -> Bool {
        minX < other.maxX - 1e-9 && maxX > other.minX + 1e-9
            && minY < other.maxY - 1e-9 && maxY > other.minY + 1e-9
    }

    func clamped(to bounds: WorldBounds) -> UrbanRect {
        UrbanRect(
            minX: max(minX, bounds.minX),
            maxX: min(maxX, bounds.maxX),
            minY: max(minY, bounds.minY),
            maxY: min(maxY, bounds.maxY)
        )
    }
}

struct UrbanBuildingDress: Equatable, Sendable {
    var obstacleID: UInt64
    var footprint: UrbanRect
    var sidewalkOuter: UrbanRect
}

struct UrbanDress: Equatable, Sendable {
    var bounds: WorldBounds
    var roads: [UrbanRect]
    var intersections: [UrbanRect]
    var sidewalks: [UrbanRect]
    var buildings: [UrbanBuildingDress]
    var alleys: [UrbanRect]
}
```

- [ ] **Step 4: Implement builder**

`Game/Presentation/UrbanDressBuilder.swift` — minimal correct algorithm:

```swift
import SurveillanceCore

enum UrbanDressBuilder {
    static let sidewalkWidth: Double = 14
    static let minRoadWidth: Double = 28

    static func build(layout: WorldLayout, district: DistrictID) -> UrbanDress {
        _ = district // reserved for district-specific widths later
        let buildings: [UrbanBuildingDress] = layout.obstacles.map { o in
            let foot = UrbanRect(center: o.center, halfSize: o.halfSize)
            let outer = foot.expanded(by: sidewalkWidth).clamped(to: layout.bounds)
            return UrbanBuildingDress(obstacleID: o.id, footprint: foot, sidewalkOuter: outer)
        }

        // Sidewalk bands: one rect per building (outer); renderer draws as frame around pad.
        let sidewalks = buildings.map(\.sidewalkOuter)

        // Occupied = footprints only for road carve (sidewalks sit on road visually).
        let occupied = buildings.map(\.footprint)

        // Horizontal free strips: scan mid-Y free spans between obstacle projections.
        var roads: [UrbanRect] = []
        let bounds = layout.bounds
        // Simple approach: full-width horizontal corridors at Y bands where no obstacle
        // covers a continuous free height ≥ minRoadWidth across X — and vertical similarly.
        roads.append(contentsOf: horizontalRoadBands(bounds: bounds, occupied: occupied))
        roads.append(contentsOf: verticalRoadBands(bounds: bounds, occupied: occupied))

        // Intersections: overlaps of one H and one V road
        var intersections: [UrbanRect] = []
        let horiz = roads.filter { $0.width >= $0.height }
        let vert = roads.filter { $0.height > $0.width }
        for h in horiz {
            for v in vert where h.intersects(v) {
                intersections.append(UrbanRect(
                    minX: max(h.minX, v.minX), maxX: min(h.maxX, v.maxX),
                    minY: max(h.minY, v.minY), maxY: min(h.maxY, v.maxY)
                ))
            }
        }

        // Fallback: if no roads inferred, treat all free bounds as one road fill
        if roads.isEmpty {
            roads = [UrbanRect(
                minX: bounds.minX, maxX: bounds.maxX,
                minY: bounds.minY, maxY: bounds.maxY
            )]
        }

        return UrbanDress(
            bounds: bounds,
            roads: roads,
            intersections: intersections,
            sidewalks: sidewalks,
            buildings: buildings,
            alleys: []
        )
    }

    // Implement horizontalRoadBands / verticalRoadBands by projecting obstacles
    // onto Y (or X), sorting intervals, finding gaps ≥ minRoadWidth, and emitting
    // full-span rects in those gaps. See design §3.3.
}
```

Implement `horizontalRoadBands` / `verticalRoadBands` fully (gap detection on sorted obstacle projections). Do not leave stubs.

- [ ] **Step 5: Run tests — expect PASS**

Same `xcodebuild test` command as Step 2. Fix until green.

- [ ] **Step 6: Commit**

```bash
git add Game/Presentation/UrbanDress.swift Game/Presentation/UrbanDressBuilder.swift \
  Tests/SurveillanceSurvivorTests/UrbanDressBuilderTests.swift
git commit -m "feat(presentation): UrbanDress model and deterministic builder"
```

---

### Task 2: Layered ground, roads, sidewalks in WorldProjector

**Files:**
- Modify: `Game/Rendering/WorldProjector.swift`
- Create: `Tests/SurveillanceSurvivorTests/WorldProjectorUrbanDressTests.swift`

**Interfaces:**
- Consumes: `UrbanDressBuilder.build`
- Produces: named child nodes under root: `urban-ground`, `urban-roads`, `urban-sidewalks`, `urban-buildings`, `urban-props`

- [ ] **Step 1: Failing test for layer nodes**

```swift
import SpriteKit
import Testing
import SurveillanceCore
@testable import SurveillanceSurvivor

@MainActor
@Test func worldProjectorBuildsUrbanLayerNodes() throws {
    let layout = DistrictGenerator.generate(seed: 7, district: .wichita).layout
    let scene = SKScene(size: CGSize(width: 852, height: 393))
    WorldProjector().synchronize(layout: layout, district: .wichita, in: scene)
    let rootChildren = scene.children
    // Projector root may be nested; search descendants
    func find(_ name: String) -> SKNode? {
        func walk(_ n: SKNode) -> SKNode? {
            if n.name == name { return n }
            for c in n.children { if let m = walk(c) { return m } }
            return nil
        }
        for c in scene.children { if let m = walk(c) { return m } }
        return nil
    }
    #expect(find("urban-ground") != nil)
    #expect(find("urban-roads") != nil)
    #expect(find("urban-sidewalks") != nil)
    #expect(find("urban-buildings") != nil)
}
```

- [ ] **Step 2: Run test — FAIL until layers exist**

- [ ] **Step 3: Refactor `synchronize` to build dress and layers**

In `WorldProjector.synchronize` after computing `worldRect`:

```swift
let dress = UrbanDressBuilder.build(layout: layout, district: district)
let ground = SKNode(); ground.name = "urban-ground"
let roads = SKNode(); roads.name = "urban-roads"
let sidewalks = SKNode(); sidewalks.name = "urban-sidewalks"
let buildings = SKNode(); buildings.name = "urban-buildings"
let props = SKNode(); props.name = "urban-props"
root.addChild(ground)
root.addChild(roads)
root.addChild(sidewalks)
root.addChild(buildings)
root.addChild(props)

renderGround(into: ground, dress: dress, district: district, worldRect: worldRect)
renderRoads(into: roads, dress: dress, district: district)
renderSidewalks(into: sidewalks, dress: dress, district: district)
// keep fillTerrain simplified: either merge into renderGround or call with low alpha only
```

`renderGround`: city-tinted `SKShapeNode` full bounds (existing `asphaltBaseColor`), optional sparse primary terrain stamps at α ≤ 0.12.

`renderRoads`: for each `dress.roads` and `dress.intersections`, filled rect slightly darker than base; road z ~ 0.02; intersection slightly different value; optional crosswalk dashes on intersections (low alpha white).

`renderSidewalks`: for each building, draw sidewalk as frame: outer `sidewalkOuter` fill lighter gray, then building pad drawn later on top. Or four edge rects between outer and footprint.

Remove or demote old full-field dual stamp carpet if still present — sparse only.

Keep parking/lane ticks **only** as road markings on `urban-roads`, sparse.

- [ ] **Step 4: Tests PASS**

```bash
xcodebuild test ... -only-testing:'SurveillanceSurvivorTests/WorldProjectorUrbanDressTests' \
  -only-testing:'SurveillanceSurvivorTests/WorldProjectorReducedFlashTests' \
  -only-testing:'SurveillanceSurvivorTests/UrbanDressBuilderTests'
```

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(presentation): layered urban ground roads and sidewalks"
```

---

### Task 3: Procedural building depth stack

**Files:**
- Modify: `Game/Rendering/WorldProjector.swift` (`projectObstacles` / new `renderBuildings`)

**Interfaces:**
- Consumes: `dress.buildings`
- Produces: per-building container with shadow, foundation, body, parapet

- [ ] **Step 1: Add test that each building container has shadow + body**

```swift
@MainActor
@Test func worldProjectorBuildingStackHasShadowAndBody() throws {
    let layout = WorldLayout(
        bounds: WorldBounds(minX: -100, maxX: 100, minY: -100, maxY: 100),
        obstacles: [WorldObstacle(id: 3, center: .init(x: 0, y: 0), halfSize: .init(x: 25, y: 20))]
    )
    let scene = SKScene(size: CGSize(width: 400, height: 300))
    WorldProjector().synchronize(layout: layout, district: .tulsa, in: scene)
    // find node named building-3 or similar under urban-buildings
    // expect child names building-shadow, building-foundation, building-body
}
```

- [ ] **Step 2: Implement `renderBuildings`**

For each `UrbanBuildingDress`:

```swift
let container = SKNode()
container.name = "building-\(b.obstacleID)"
container.position = CGPoint(x: b.footprint.center.x, y: b.footprint.center.y)
let w = CGFloat(b.footprint.width)
let h = CGFloat(b.footprint.height)

// contact shadow
let shadow = SKShapeNode(rectOf: CGSize(width: w * 1.05, height: h * 0.35), cornerRadius: 4)
shadow.name = "building-shadow"
shadow.fillColor = SKColor(white: 0, alpha: 0.28)
shadow.strokeColor = .clear
shadow.position = CGPoint(x: w * 0.06, y: -h * 0.42)
shadow.zPosition = 0
container.addChild(shadow)

// foundation
let foundation = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 6)
foundation.name = "building-foundation"
foundation.fillColor = foundationColor(district) // darker than pad
foundation.strokeColor = .clear
foundation.zPosition = 1
container.addChild(foundation)

// body (inset)
let body = SKShapeNode(rectOf: CGSize(width: w * 0.92, height: h * 0.88), cornerRadius: 5)
body.name = "building-body"
body.fillColor = obstaclePadColor(for: district) // existing helper
body.strokeColor = SKColor(white: 0.08, alpha: 0.5)
body.lineWidth = 1
body.zPosition = 2
container.addChild(body)

// parapet (north edge highlight)
let parapet = SKShapeNode(rectOf: CGSize(width: w * 0.88, height: max(3, h * 0.08)))
parapet.name = "building-parapet"
parapet.fillColor = SKColor(white: 0.35, alpha: 0.35)
parapet.strokeColor = .clear
parapet.position = CGPoint(x: 0, y: h * 0.38)
parapet.zPosition = 3
container.addChild(parapet)

buildingsLayer.addChild(container)
```

Remove any remaining landmark-as-pad paths. Optional: rare retail mass only if aspect fits and α ≤ 0.4.

- [ ] **Step 3: Tests green + full `SurveillanceSurvivorTests` smoke**

```bash
xcodebuild test ... -only-testing:'SurveillanceSurvivorTests' CODE_SIGNING_ALLOWED=NO
```

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(presentation): procedural building depth stack on urban dress"
```

---

### Task 4: Props, landmarks, wayfinding integration

**Files:**
- Modify: `WorldProjector.swift` — call landmark/decal into `urban-props`; keep ≤2 landmarks, ≤2 decals
- Ensure wayfinding remains under calmed alpha (`CityOverlayPresentation`)

- [ ] **Step 1: Move `scatterDecals` / `placeCityLandmarks` outputs under `props` layer**

- [ ] **Step 2: Manual sanity** — no landmark hangar on pads; pin() landmarks only

- [ ] **Step 3: Run WorldProjector + Emulator visual smoke tests**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(presentation): route landmarks and decals into urban-props layer"
```

---

### Task 5: Landmark / prop alpha audit doc

**Files:**
- Create: `docs/arena/ARENA_ASSET_AUDIT.md`
- Optional script: `scripts/audit_sprite_opaque_corners.py` (report only)

- [ ] **Step 1: Script scan** of `Resources/RuntimeSprites/*landmark*` and `*prop*` for corner alpha == 255 and near-uniform RGB

- [ ] **Step 2: Write audit markdown** listing suspects; repair only clear opaque-canvas offenders (flood-fill edge black/magenta) with receipt note

- [ ] **Step 3: `make assets-check sprite-chroma-check`**

- [ ] **Step 4: Commit**

```bash
git commit -m "docs(arena): building and landmark alpha audit"
```

---

### Task 6: Docs + quality checklist

**Files:**
- Create: `docs/arena/ARENA_QUALITY_CHECKLIST.md`
- Create: `docs/arena/URBAN_DRESS.md` (architecture: dress vs sim)
- Optional: pointer from `docs/ENVIRONMENT_ART_MAP.md` or `docs/HALLMARK_FLOOR_AUDIT.md`

- [ ] **Step 1: Write architecture note** — UrbanDress vs WorldLayout, layer z, inference rules

- [ ] **Step 2: Checklist** from design §7

- [ ] **Step 3: Commit**

```bash
git commit -m "docs(arena): urban dress architecture and quality checklist"
```

---

### Task 7: Final verification

- [ ] **Step 1:**

```bash
make launch-gate-check  # honesty only; may stay LAUNCH_BLOCKED
xcodebuild test -project SurveillanceSurvivor.xcodeproj -scheme SurveillanceSurvivor \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:'SurveillanceSurvivorTests' CODE_SIGNING_ALLOWED=NO
```

- [ ] **Step 2: Device glance** (if phone available):

```bash
DEVELOPMENT_TEAM=X9M969D8M3 make device-smoke
```

Confirm: continuous ground, street-like free space, blocky buildings with shadow, no opaque landmark boxes on pads.

- [ ] **Step 3: No READY gate invention; board note optional**

---

## Spec coverage

| Spec item | Task |
| --- | --- |
| UrbanDress model + builder | 1 |
| Inference sidewalks/roads | 1 |
| Layered ground/road/sidewalk | 2 |
| Building depth stack | 3 |
| No landmark-on-pad | 3–4 |
| Props/landmarks calmed | 4 |
| Asset alpha audit | 5 |
| Docs + checklist | 6 |
| Determinism + sim untouched | Global + Task 1 tests |
| All 10 cities | Tasks 1–3 use DistrictID profiles |

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-08-02-urban-arena-presentation.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks  
2. **Inline Execution** — this session with checkpoints  

Which approach?
