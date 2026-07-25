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
    /// v8: additive interactable activations (P9 environmental weaponization).
    public static let schemaVersion = 8

    public var schemaVersion: Int
    public var seed: UInt64
    public var district: DistrictID
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
    /// Authoritative director choices; may only describe selected actions (no invented narrative).
    public var directorDecisions: [DirectorDecisionSample]
    /// Authoritative infrastructure integrity changes (no invented narrative).
    public var cityStateEvents: [CityStateEventSample]
    /// Final district infrastructure snapshot for receipt audit.
    public var districtState: DistrictState?
    /// Active build synergies at end of run (and any mid-run activation samples).
    public var buildSynergyActivations: [BuildSynergyActivationSample]
    public var buildEngine: BuildEngineState?
    /// Coordination chain transitions (start / advance / interrupt / complete).
    public var coordinationEvents: [CoordinationEventSample]
    public var coordination: CoordinationState?
    /// Story facts compiled only from receipt evidence (no invented narrative).
    public var storyFacts: [StoryFact]
    public var storySummary: String
    /// Environmental interactable activations this run.
    public var interactableActivations: [InteractableActivationSample]

    public init(
        seed: UInt64,
        district: DistrictID,
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
        extractionCompleted: Bool,
        directorDecisions: [DirectorDecisionSample] = [],
        cityStateEvents: [CityStateEventSample] = [],
        districtState: DistrictState? = nil,
        buildSynergyActivations: [BuildSynergyActivationSample] = [],
        buildEngine: BuildEngineState? = nil,
        coordinationEvents: [CoordinationEventSample] = [],
        coordination: CoordinationState? = nil,
        storyFacts: [StoryFact]? = nil,
        storySummary: String? = nil,
        interactableActivations: [InteractableActivationSample] = []
    ) {
        schemaVersion = Self.schemaVersion
        self.seed = seed
        self.district = district
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
        self.directorDecisions = directorDecisions
        self.cityStateEvents = cityStateEvents
        self.districtState = districtState
        self.buildSynergyActivations = buildSynergyActivations
        self.buildEngine = buildEngine
        self.coordinationEvents = coordinationEvents
        self.coordination = coordination
        if let storyFacts, let storySummary {
            self.storyFacts = storyFacts
            self.storySummary = storySummary
        } else {
            let report = RunStoryCompiler.compile(
                evidence: StoryEvidenceSnapshot(
                    seed: seed,
                    district: district,
                    extractionCompleted: extractionCompleted,
                    eventSequence: eventSequence,
                    deathsByArchetype: deathsByArchetype,
                    selectedUpgrades: selectedUpgrades,
                    directorDecisions: directorDecisions,
                    cityStateEvents: cityStateEvents,
                    buildSynergyActivations: buildSynergyActivations,
                    buildEngine: buildEngine,
                    coordinationEvents: coordinationEvents,
                    coordination: coordination,
                    suspicionTimeline: suspicionTimeline
                )
            )
            self.storyFacts = report.facts
            self.storySummary = report.summary
        }
        self.interactableActivations = interactableActivations
    }
}
