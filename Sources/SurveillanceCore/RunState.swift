public struct PlayerInput: Codable, Equatable, Sendable {
    public var movement: Vector2
    public var activateUtility: Bool
    public var upgradeChoiceIndex: Int?

    public init(movement: Vector2 = .init(), activateUtility: Bool = false, upgradeChoiceIndex: Int? = nil) {
        self.movement = movement
        self.activateUtility = activateUtility
        self.upgradeChoiceIndex = upgradeChoiceIndex
    }
}

public struct RunState: Codable, Equatable, Sendable {
    public var seed: UInt64
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
    public var activeWeapons: [WeaponSystem]

    public init(seed: UInt64) {
        self.seed = seed
        elapsed = 0
        suspicion = 0
        suspicionTier = .backgroundNoise
        let generated = ParkingLotGenerator.generate(seed: seed)
        world = generated.layout
        entities = [
            Entity(
                id: 1,
                kind: .player,
                position: Vector2(x: 0, y: -180),
                health: 100,
                radius: 18
            )
        ] + generated.cameras
        dataShards = 0
        pendingUpgradeChoices = []
        bossDefeated = false
        extractionOpen = false
        runCompleted = false
        activeWeapons = [.baselineKinetic]
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
    }

    public var kind: Kind
    public var message: String

    public init(_ kind: Kind, _ message: String) {
        self.kind = kind
        self.message = message
    }
}
