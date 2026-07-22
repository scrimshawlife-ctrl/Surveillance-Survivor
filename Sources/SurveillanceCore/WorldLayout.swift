public struct WorldBounds: Codable, Equatable, Sendable {
    public var minX: Double
    public var maxX: Double
    public var minY: Double
    public var maxY: Double

    public init(minX: Double, maxX: Double, minY: Double, maxY: Double) {
        self.minX = minX
        self.maxX = maxX
        self.minY = minY
        self.maxY = maxY
    }

    public func clamped(_ point: Vector2, margin: Double = 0) -> Vector2 {
        Vector2(
            x: min(max(point.x, minX + margin), maxX - margin),
            y: min(max(point.y, minY + margin), maxY - margin)
        )
    }
}

public struct WorldObstacle: Identifiable, Codable, Equatable, Sendable {
    public let id: UInt64
    public var center: Vector2
    public var halfSize: Vector2

    public init(id: UInt64, center: Vector2, halfSize: Vector2) {
        self.id = id
        self.center = center
        self.halfSize = halfSize
    }
}

public struct WorldLayout: Codable, Equatable, Sendable {
    public var bounds: WorldBounds
    public var obstacles: [WorldObstacle]

    public init(bounds: WorldBounds, obstacles: [WorldObstacle]) {
        self.bounds = bounds
        self.obstacles = obstacles
    }
}
