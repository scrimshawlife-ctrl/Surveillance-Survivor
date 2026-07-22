public struct PlayerInput: Codable, Equatable, Sendable {
    public var movement: Vector2
    public var activateUtility: Bool

    public init(movement: Vector2 = .init(), activateUtility: Bool = false) {
        self.movement = movement
        self.activateUtility = activateUtility
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
    public var bossDefeated: Bool
    public var extractionOpen: Bool
    public var activeWeapons: [WeaponSystem]

    public init(seed: UInt64, activeWeapons: [WeaponSystem] = [.baselineKinetic]) {
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
        bossDefeated = false
        extractionOpen = false
        self.activeWeapons = Array(activeWeapons.prefix(CombatLimits.maximumActiveWeapons))
    }
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
        case statusApplied
        case upgradeOffered
        case extractionOpened
    }

    public var kind: Kind
    public var message: String

    public init(_ kind: Kind, _ message: String) {
        self.kind = kind
        self.message = message
    }
}
