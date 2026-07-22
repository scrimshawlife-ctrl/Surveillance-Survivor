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
    public var sensorSpoof: SensorSpoof?

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
        sensorDisabledUntilTick: UInt64? = nil,
        sensorSpoof: SensorSpoof? = nil
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
        self.sensorSpoof = sensorSpoof
    }
}

public struct SensorSpoof: Codable, Equatable, Sendable {
    public var untilTick: UInt64
    public var suspicionMultiplier: Double

    public init(untilTick: UInt64, suspicionMultiplier: Double) {
        self.untilTick = untilTick
        self.suspicionMultiplier = min(1, max(0, suspicionMultiplier))
    }
}
