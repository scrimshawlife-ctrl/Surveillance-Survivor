public enum EntityKind: String, Codable, Sendable {
    case player
    case securityGuard
    case cameraPole
    case projectile
    case boss
    case extraction
}

public struct Entity: Identifiable, Codable, Equatable, Sendable {
    public let id: UInt64
    public var kind: EntityKind
    public var position: Vector2
    public var velocity: Vector2
    public var health: Double
    public var radius: Double

    public init(
        id: UInt64,
        kind: EntityKind,
        position: Vector2,
        velocity: Vector2 = .init(),
        health: Double,
        radius: Double
    ) {
        self.id = id
        self.kind = kind
        self.position = position
        self.velocity = velocity
        self.health = health
        self.radius = radius
    }
}
