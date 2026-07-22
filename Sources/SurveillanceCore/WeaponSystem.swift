public enum WeaponID: String, Codable, CaseIterable, Sendable {
    case kineticCountermeasure
    case redactionOrdinance
    case identityTransponder
    case foiaSwarm
    case mirrorArray
    case signalFlood
}

public enum TargetingRule: String, Codable, Sendable {
    case nearestCameraThenThreat
    case nearestThreat
    case nearestCamera
}

public enum CountermeasurePayload: Codable, Equatable, Sendable {
    case damage(Double)
    case disableCameraSensors(durationTicks: UInt64)
    case spoofCameraSensors(durationTicks: UInt64, suspicionMultiplier: Double)
    case processing(durationTicks: UInt64, slowMultiplier: Double, damagePerTick: Double)
    case reflect(durationTicks: UInt64, damageMultiplier: Double)
    case signalFlood(radius: Double, durationTicks: UInt64, suspicionSpike: Double)
}

public struct WeaponSystem: Codable, Equatable, Sendable {
    public var id: WeaponID
    public var level: Int
    public var cadenceTicks: UInt64
    public var range: Double
    public var projectileSpeed: Double
    public var projectileRadius: Double
    public var payload: CountermeasurePayload
    public var targetingRule: TargetingRule

    public init(
        id: WeaponID,
        level: Int = 1,
        cadenceTicks: UInt64,
        range: Double,
        projectileSpeed: Double,
        projectileRadius: Double,
        payload: CountermeasurePayload,
        targetingRule: TargetingRule
    ) {
        self.id = id
        self.level = level
        self.cadenceTicks = max(1, cadenceTicks)
        self.range = max(0, range)
        self.projectileSpeed = max(0, projectileSpeed)
        self.projectileRadius = max(1, projectileRadius)
        self.payload = payload
        self.targetingRule = targetingRule
    }

    public static let baselineKinetic = WeaponSystem(
        id: .kineticCountermeasure,
        cadenceTicks: 15,
        range: 1_000,
        projectileSpeed: 600,
        projectileRadius: 5,
        payload: .damage(15),
        targetingRule: .nearestCameraThenThreat
    )

    public static let redactionOrdinance = WeaponSystem(
        id: .redactionOrdinance,
        cadenceTicks: 90,
        range: 800,
        projectileSpeed: 420,
        projectileRadius: 10,
        payload: .disableCameraSensors(durationTicks: 180),
        targetingRule: .nearestCamera
    )

    public static let identityTransponder = WeaponSystem(
        id: .identityTransponder,
        cadenceTicks: 120,
        range: 700,
        projectileSpeed: 360,
        projectileRadius: 9,
        payload: .spoofCameraSensors(durationTicks: 240, suspicionMultiplier: 0.25),
        targetingRule: .nearestCamera
    )

    public static let foiaSwarm = WeaponSystem(
        id: .foiaSwarm,
        cadenceTicks: 75,
        range: 700,
        projectileSpeed: 320,
        projectileRadius: 7,
        payload: .processing(durationTicks: 180, slowMultiplier: 0.5, damagePerTick: 0.12),
        targetingRule: .nearestThreat
    )

    public static let mirrorArray = WeaponSystem(
        id: .mirrorArray,
        cadenceTicks: 180,
        range: 0,
        projectileSpeed: 0,
        projectileRadius: 34,
        payload: .reflect(durationTicks: 360, damageMultiplier: 1),
        targetingRule: .nearestCamera
    )

    public static let signalFlood = WeaponSystem(
        id: .signalFlood,
        cadenceTicks: 300,
        range: 360,
        projectileSpeed: 0,
        projectileRadius: 360,
        payload: .signalFlood(radius: 360, durationTicks: 150, suspicionSpike: 10),
        targetingRule: .nearestCamera
    )
}

public enum CombatLimits {
    public static let maximumActiveWeapons = 4
    public static let maximumProjectiles = 96
    public static let maximumPersistentDeployables = 8
}
