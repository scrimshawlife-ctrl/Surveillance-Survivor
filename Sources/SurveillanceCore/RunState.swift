public struct PlayerInput: Codable, Equatable, Sendable {
    public var movement: Vector2
    public var activateUtility: Bool
    public var upgradeChoiceIndex: Int?
    /// When false, weapons do not auto-fire. Used by UI tests so launch chrome
    /// is not immediately covered by AFK countermeasure upgrade drafts.
    public var autoFireEnabled: Bool

    public init(
        movement: Vector2 = .init(),
        activateUtility: Bool = false,
        upgradeChoiceIndex: Int? = nil,
        autoFireEnabled: Bool = true
    ) {
        self.movement = movement
        self.activateUtility = activateUtility
        self.upgradeChoiceIndex = upgradeChoiceIndex
        self.autoFireEnabled = autoFireEnabled
    }
}

public struct RunState: Codable, Equatable, Sendable {
    public var seed: UInt64
    public var district: DistrictID
    public var elapsed: Double
    public var suspicion: Double
    public var suspicionTier: SuspicionTier
    public var entities: [Entity]
    public var world: WorldLayout
    public var dataShards: Int
    public var pendingUpgradeChoices: [UpgradeChoice]
    public var bossDefeated: Bool
    public var extractionOpen: Bool
    public var runCompleted: Bool
    public var playerDefeated: Bool
    public var activeWeapons: [WeaponSystem]
    public var evolutions: Set<WeaponEvolution>

    public init(seed: UInt64, district: DistrictID = .campaignOpener) {
        self.seed = seed
        self.district = district
        elapsed = 0
        suspicion = 0
        suspicionTier = .backgroundNoise
        let generated = DistrictGenerator.generate(seed: seed, district: district)
        world = generated.layout
        let playerHealth = BossCatalog.bundled.playerHealth
        entities = [
            Entity(
                id: 1,
                kind: .player,
                position: district.profile.playerSpawn,
                health: playerHealth,
                radius: 18
            )
        ] + generated.sensors
        dataShards = 0
        pendingUpgradeChoices = []
        bossDefeated = false
        extractionOpen = false
        runCompleted = false
        playerDefeated = false
        activeWeapons = [.baselineKinetic]
        evolutions = []
    }
}

public enum UpgradeChoice: String, CaseIterable, Codable, Equatable, Sendable {
    case rapidCountermeasure
    case reinforcedSignal
    case lowProfileRouting
    case redactionOrdinance
    case identityTransponder
    case foiaSwarm
    case mirrorArray
    case signalFlood
    case precisionDart
    case blackBarMandate
    case ghostPlateCache
    case expeditedDiscovery
    case indictmentProtocol
    case blackoutField
    case ghostProtocol
    case paperStorm
}

public enum WeaponEvolution: String, CaseIterable, Codable, Hashable, Sendable {
    case indictmentProtocol
    case blackoutField
    case ghostProtocol
    case paperStorm
}

public struct RunEvent: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case suspicionChanged
        case tierChanged
        case entitySpawned
        case entityDestroyed
        case sensorContact
        case weaponFired
        case countermeasureHit
        case upgradeOffered
        case upgradeSelected
        case bossActivated
        case extractionOpened
        case extractionCompleted
        case playerDamaged
        case playerDefeated
    }

    public var kind: Kind
    public var message: String

    public init(_ kind: Kind, _ message: String) {
        self.kind = kind
        self.message = message
    }
}
