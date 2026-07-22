public enum EntityKind: String, Codable, Hashable, Sendable {
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
    public var heading: Double
    public var health: Double
    public var radius: Double
    public var sourceWeapon: WeaponID?
    public var payload: CountermeasurePayload?
    public var sensorDisabledUntilTick: UInt64?

    public init(
        id: UInt64,
        kind: EntityKind,
        position: Vector2,
        velocity: Vector2 = .init(),
        heading: Double = 0,
        health: Double,
        radius: Double,
        sourceWeapon: WeaponID? = nil,
        payload: CountermeasurePayload? = nil,
        sensorDisabledUntilTick: UInt64? = nil
    ) {
        self.id = id
        self.kind = kind
        self.position = position
        self.velocity = velocity
        self.heading = heading
        self.health = health
        self.radius = radius
        self.sourceWeapon = sourceWeapon
        self.payload = payload
        self.sensorDisabledUntilTick = sensorDisabledUntilTick
    }
}
