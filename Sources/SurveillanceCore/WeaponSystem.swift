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

    public static let baselineKinetic = ContentCatalog.bundled.weapon(.kineticCountermeasure).weaponSystem()
    public static let redactionOrdinance = ContentCatalog.bundled.weapon(.redactionOrdinance).weaponSystem()
    public static let identityTransponder = ContentCatalog.bundled.weapon(.identityTransponder).weaponSystem()
    public static let foiaSwarm = ContentCatalog.bundled.weapon(.foiaSwarm).weaponSystem()
    public static let mirrorArray = ContentCatalog.bundled.weapon(.mirrorArray).weaponSystem()
    public static let signalFlood = ContentCatalog.bundled.weapon(.signalFlood).weaponSystem()
}

public enum CombatLimits {
    public static let maximumActiveWeapons = 4
    public static let maximumProjectiles = 96
    public static let maximumPersistentDeployables = 8
}
