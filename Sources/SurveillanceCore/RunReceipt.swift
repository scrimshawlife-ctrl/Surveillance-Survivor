public struct RecordedRunEvent: Codable, Equatable, Sendable {
    public var tick: UInt64
    public var sequence: UInt64
    public var event: RunEvent

    public init(tick: UInt64, sequence: UInt64, event: RunEvent) {
        self.tick = tick
        self.sequence = sequence
        self.event = event
    }
}

public struct SuspicionSample: Codable, Equatable, Sendable {
    public var tick: UInt64
    public var value: Double
    public var tier: SuspicionTier

    public init(tick: UInt64, value: Double, tier: SuspicionTier) {
        self.tick = tick
        self.value = value
        self.tier = tier
    }
}

public struct RunReceipt: Codable, Equatable, Sendable {
    public static let schemaVersion = 1

    public var schemaVersion: Int
    public var seed: UInt64
    public var elapsedTicks: UInt64
    public var elapsedSeconds: Double
    public var suspicionTimeline: [SuspicionSample]
    public var eventSequence: [RecordedRunEvent]
    public var offeredUpgrades: [[UpgradeChoice]]
    public var selectedUpgrades: [UpgradeChoice]
    public var spawnedEntities: [EntityKind: Int]
    public var deathsByArchetype: [EntityKind: Int]
    public var damageDealt: Double
    public var damageTaken: Double
    public var bossPhaseDurations: [UInt64]
    public var extractionCompleted: Bool

    public init(
        seed: UInt64,
        elapsedTicks: UInt64,
        elapsedSeconds: Double,
        suspicionTimeline: [SuspicionSample],
        eventSequence: [RecordedRunEvent],
        offeredUpgrades: [[UpgradeChoice]],
        selectedUpgrades: [UpgradeChoice],
        spawnedEntities: [EntityKind: Int],
        deathsByArchetype: [EntityKind: Int],
        damageDealt: Double,
        damageTaken: Double,
        bossPhaseDurations: [UInt64],
        extractionCompleted: Bool
    ) {
        schemaVersion = Self.schemaVersion
        self.seed = seed
        self.elapsedTicks = elapsedTicks
        self.elapsedSeconds = elapsedSeconds
        self.suspicionTimeline = suspicionTimeline
        self.eventSequence = eventSequence
        self.offeredUpgrades = offeredUpgrades
        self.selectedUpgrades = selectedUpgrades
        self.spawnedEntities = spawnedEntities
        self.deathsByArchetype = deathsByArchetype
        self.damageDealt = damageDealt
        self.damageTaken = damageTaken
        self.bossPhaseDurations = bossPhaseDurations
        self.extractionCompleted = extractionCompleted
    }
}
