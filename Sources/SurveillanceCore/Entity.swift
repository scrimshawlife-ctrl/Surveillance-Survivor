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

public enum GuardArchetype: String, CaseIterable, Codable, Equatable, Sendable {
    case flashlightCadet
    case radioGuy
    case clipboardEnforcer
    case tacticalPolo
    case segwaySentinel
    case supervisorOnBreak

    var definition: GuardDefinition { EnemyCatalog.bundled.guardDefinition(self) }
    public var displayName: String { definition.displayName }
    var health: Double { definition.health }
    var speed: Double { definition.speed }
    var radius: Double { definition.radius }
    var contactDamagePerSecond: Double { definition.contactDamagePerSecond }
}

public enum SensorArchetype: String, CaseIterable, Codable, Equatable, Sendable {
    case lprCameraPole
    case panTiltZoomEye
    case parkingLotDrone
    case smartDoorbellSwarm
    case acousticGunshotDetector
    case predictivePatrolNode

    var definition: SensorDefinition { EnemyCatalog.bundled.sensorDefinition(self) }
    public var displayName: String { definition.displayName }
    var health: Double { definition.health }
    var radius: Double { definition.radius }
    var scanRange: Double { definition.scanRange }
    var scanHalfAngle: Double? { definition.scanHalfAngle }
    var rotationSpeed: Double { definition.rotationSpeed }
}

public struct Entity: Identifiable, Codable, Equatable, Sendable {
    public let id: UInt64
    public var kind: EntityKind
    public var guardArchetype: GuardArchetype?
    public var sensorArchetype: SensorArchetype?
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
        guardArchetype: GuardArchetype? = nil,
        sensorArchetype: SensorArchetype? = nil,
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
        self.guardArchetype = guardArchetype
        self.sensorArchetype = sensorArchetype
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
