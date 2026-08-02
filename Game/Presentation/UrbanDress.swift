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

    func contains(_ point: Vector2) -> Bool {
        point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY
    }

    func expanded(by m: Double) -> UrbanRect {
        UrbanRect(minX: minX - m, maxX: maxX + m, minY: minY - m, maxY: maxY + m)
    }

    func inset(by m: Double) -> UrbanRect {
        expanded(by: -m)
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
