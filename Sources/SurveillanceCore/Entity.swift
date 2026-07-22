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

    public var displayName: String {
        switch self {
        case .flashlightCadet: "Flashlight Cadet"
        case .radioGuy: "Radio Guy"
        case .clipboardEnforcer: "Clipboard Enforcer"
        case .tacticalPolo: "Tactical Polo"
        case .segwaySentinel: "Segway Sentinel"
        case .supervisorOnBreak: "Supervisor on Break"
        }
    }

    var health: Double {
        switch self {
        case .flashlightCadet: 20
        case .radioGuy: 24
        case .clipboardEnforcer: 30
        case .tacticalPolo: 18
        case .segwaySentinel: 26
        case .supervisorOnBreak: 70
        }
    }

    var speed: Double {
        switch self {
        case .flashlightCadet: 88
        case .radioGuy: 72
        case .clipboardEnforcer: 62
        case .tacticalPolo: 130
        case .segwaySentinel: 102
        case .supervisorOnBreak: 76
        }
    }

    var radius: Double {
        self == .supervisorOnBreak ? 21 : 14
    }
}

public struct Entity: Identifiable, Codable, Equatable, Sendable {
    public let id: UInt64
    public var kind: EntityKind
    public var guardArchetype: GuardArchetype?
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
