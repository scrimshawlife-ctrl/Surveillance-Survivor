public enum EntityKind: String, Codable, Hashable, Sendable {
    case player
    case securityGuard
    case cameraPole
    case projectile
    case boss
    case extraction
    case mirrorArray
    case signalFlood
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
    public var processing: ProcessingStatus?
    public var disruptedUntilTick: UInt64?
    public var effectExpiresAtTick: UInt64?

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
        sensorSpoof: SensorSpoof? = nil,
        processing: ProcessingStatus? = nil,
        disruptedUntilTick: UInt64? = nil,
        effectExpiresAtTick: UInt64? = nil
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
        self.processing = processing
        self.disruptedUntilTick = disruptedUntilTick
        self.effectExpiresAtTick = effectExpiresAtTick
    }
}

public struct ProcessingStatus: Codable, Equatable, Sendable {
    public var untilTick: UInt64
    public var slowMultiplier: Double
    public var damagePerTick: Double

    public init(untilTick: UInt64, slowMultiplier: Double, damagePerTick: Double) {
        self.untilTick = untilTick
        self.slowMultiplier = min(1, max(0, slowMultiplier))
        self.damagePerTick = max(0, damagePerTick)
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
