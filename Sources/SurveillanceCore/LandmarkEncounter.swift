import Foundation

// MARK: - Content

/// Landmark-scale set pieces (P9). Influences pressure levers only — no hidden damage/HP scaling.
public struct LandmarkEncounterCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let schemaId: String
    public let forbidHiddenStatScaling: Bool
    public let encounters: [LandmarkEncounterDefinition]

    public static let currentSchemaVersion = 1
    public static let expectedSchemaId = "surveillance-survivor/landmark_encounters"

    public static let bundled: LandmarkEncounterCatalog = {
        do { return try loadBundled() }
        catch { preconditionFailure("Invalid bundled landmark encounters: \(error)") }
    }()

    public static func loadBundled() throws -> LandmarkEncounterCatalog {
        guard let url = contentBundle.url(forResource: "landmark_encounters", withExtension: "json", subdirectory: "Content")
            ?? contentBundle.url(forResource: "landmark_encounters", withExtension: "json")
        else { throw LandmarkError.missingResource }
        let catalog = try JSONDecoder().decode(LandmarkEncounterCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func encounters(for district: DistrictID) -> [LandmarkEncounterDefinition] {
        encounters.filter { $0.districtId == district }
    }

    public func primary(for district: DistrictID) -> LandmarkEncounterDefinition? {
        encounters(for: district).first
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw LandmarkError.unsupportedSchema(schemaVersion)
        }
        guard schemaId == Self.expectedSchemaId else {
            throw LandmarkError.invalidDefinition("schemaId must be \(Self.expectedSchemaId)")
        }
        guard forbidHiddenStatScaling else {
            throw LandmarkError.invalidDefinition("forbidHiddenStatScaling must be true")
        }
        guard !encounters.isEmpty else {
            throw LandmarkError.invalidDefinition("encounters must be non-empty")
        }
        guard Set(encounters.map(\.id)).count == encounters.count else {
            throw LandmarkError.invalidDefinition("duplicate encounter ids")
        }
        let interactables = InteractableCatalog.bundled
        for encounter in encounters {
            try encounter.validate()
            for linked in encounter.linkedInteractableIds {
                guard interactables.definition(linked) != nil else {
                    throw LandmarkError.invalidDefinition("\(encounter.id) links unknown interactable \(linked)")
                }
                if let def = interactables.definition(linked), def.districtId != encounter.districtId {
                    throw LandmarkError.invalidDefinition("\(encounter.id) interactable district mismatch")
                }
            }
        }
    }
}

public struct LandmarkWhileInsideLevers: Codable, Equatable, Sendable {
    public let guardTargetDelta: Int
    public let observationPressureBonus: Double
    public let spawnIntervalMultiplier: Double
}

public struct LandmarkHazardStep: Codable, Equatable, Sendable {
    public let atElapsedSeconds: Double
    public let kind: String
    public let observationPressureBonus: Double
    public let guardTargetDelta: Int
}

public struct LandmarkBossHooks: Codable, Equatable, Sendable {
    public let nudgeSuspicionPerSecondWhileInside: Double
    public let minimumTierRaw: Int
}

public struct LandmarkEncounterDefinition: Codable, Equatable, Sendable {
    public let id: String
    public let districtId: DistrictID
    public let displayName: String
    public let center: Vector2
    public let radius: Double
    public let topologyGrammar: String
    public let linkedInteractableIds: [String]
    public let hazardSchedule: [LandmarkHazardStep]
    public let whileInside: LandmarkWhileInsideLevers
    public let bossHooks: LandmarkBossHooks
    public let audioMotifId: String
    public let artPackageId: String
    public let opportunity: String
    public let cost: String

    func validate() throws {
        guard !id.isEmpty, !displayName.isEmpty else {
            throw LandmarkError.invalidDefinition("id/displayName required")
        }
        guard radius > 40, radius <= 600 else {
            throw LandmarkError.invalidDefinition("\(id) radius out of band")
        }
        guard !topologyGrammar.isEmpty else {
            throw LandmarkError.invalidDefinition("\(id) topologyGrammar required")
        }
        guard linkedInteractableIds.count >= 2 else {
            throw LandmarkError.invalidDefinition("\(id) needs ≥2 linked interactables")
        }
        guard !hazardSchedule.isEmpty else {
            throw LandmarkError.invalidDefinition("\(id) hazardSchedule required")
        }
        for hazard in hazardSchedule {
            guard hazard.atElapsedSeconds >= 0 else {
                throw LandmarkError.invalidDefinition("\(id) hazard time invalid")
            }
            guard (0...0.5).contains(hazard.observationPressureBonus) else {
                throw LandmarkError.invalidDefinition("\(id) hazard observation out of band")
            }
            guard (-2...4).contains(hazard.guardTargetDelta) else {
                throw LandmarkError.invalidDefinition("\(id) hazard guard delta out of band")
            }
        }
        let levers = whileInside
        guard (-2...4).contains(levers.guardTargetDelta) else {
            throw LandmarkError.invalidDefinition("\(id) whileInside guard delta out of band")
        }
        guard (0...0.5).contains(levers.observationPressureBonus) else {
            throw LandmarkError.invalidDefinition("\(id) whileInside observation out of band")
        }
        guard (0.5...1.5).contains(levers.spawnIntervalMultiplier) else {
            throw LandmarkError.invalidDefinition("\(id) whileInside spawn multiplier out of band")
        }
        guard bossHooks.nudgeSuspicionPerSecondWhileInside >= 0,
              bossHooks.nudgeSuspicionPerSecondWhileInside <= 2,
              (0...5).contains(bossHooks.minimumTierRaw)
        else {
            throw LandmarkError.invalidDefinition("\(id) bossHooks out of band")
        }
        guard !audioMotifId.isEmpty, !artPackageId.isEmpty else {
            throw LandmarkError.invalidDefinition("\(id) audio/art package required")
        }
        guard !opportunity.isEmpty, !cost.isEmpty else {
            throw LandmarkError.invalidDefinition("\(id) opportunity and cost required")
        }
    }
}

public enum LandmarkError: Error, Equatable, Sendable {
    case missingResource
    case unsupportedSchema(Int)
    case invalidDefinition(String)
}

// MARK: - Runtime

public struct LandmarkEncounterState: Codable, Equatable, Sendable {
    public var activeEncounterId: String?
    public var isPlayerInside: Bool
    public var enteredElapsed: Double?
    public var firedHazardKinds: [String]
    public var appliedGuardTargetDelta: Int
    public var appliedObservationBonus: Double
    public var appliedSpawnIntervalMultiplier: Double
    public var timeInsideSeconds: Double

    public static let idle = LandmarkEncounterState(
        activeEncounterId: nil,
        isPlayerInside: false,
        enteredElapsed: nil,
        firedHazardKinds: [],
        appliedGuardTargetDelta: 0,
        appliedObservationBonus: 0,
        appliedSpawnIntervalMultiplier: 1,
        timeInsideSeconds: 0
    )

    public init(
        activeEncounterId: String? = nil,
        isPlayerInside: Bool = false,
        enteredElapsed: Double? = nil,
        firedHazardKinds: [String] = [],
        appliedGuardTargetDelta: Int = 0,
        appliedObservationBonus: Double = 0,
        appliedSpawnIntervalMultiplier: Double = 1,
        timeInsideSeconds: Double = 0
    ) {
        self.activeEncounterId = activeEncounterId
        self.isPlayerInside = isPlayerInside
        self.enteredElapsed = enteredElapsed
        self.firedHazardKinds = firedHazardKinds
        self.appliedGuardTargetDelta = appliedGuardTargetDelta
        self.appliedObservationBonus = appliedObservationBonus
        self.appliedSpawnIntervalMultiplier = appliedSpawnIntervalMultiplier
        self.timeInsideSeconds = timeInsideSeconds
    }
}

public struct LandmarkEventSample: Codable, Equatable, Sendable {
    public var tick: UInt64
    public var encounterId: String
    public var kind: String
    public var reason: String

    public init(tick: UInt64, encounterId: String, kind: String, reason: String) {
        self.tick = tick
        self.encounterId = encounterId
        self.kind = kind
        self.reason = reason
    }
}

public struct LandmarkStepResult: Equatable, Sendable {
    public var state: LandmarkEncounterState
    public var events: [LandmarkEventSample]
    public var suspicionNudgePerSecond: Double
    /// While inside, suspicion should reach at least this tier (0 = no floor).
    public var minimumTierRaw: Int

    public init(
        state: LandmarkEncounterState,
        events: [LandmarkEventSample],
        suspicionNudgePerSecond: Double,
        minimumTierRaw: Int = 0
    ) {
        self.state = state
        self.events = events
        self.suspicionNudgePerSecond = suspicionNudgePerSecond
        self.minimumTierRaw = minimumTierRaw
    }
}

public enum LandmarkEncounterEngine: Sendable {
    public static func evaluate(
        catalog: LandmarkEncounterCatalog = .bundled,
        district: DistrictID,
        playerPosition: Vector2,
        elapsed: Double,
        tick: UInt64,
        fixedStep: Double,
        state: LandmarkEncounterState
    ) -> LandmarkStepResult {
        guard catalog.forbidHiddenStatScaling else {
            return LandmarkStepResult(state: state, events: [], suspicionNudgePerSecond: 0)
        }
        guard let encounter = catalog.primary(for: district) else {
            return LandmarkStepResult(state: .idle, events: [], suspicionNudgePerSecond: 0)
        }

        var next = state
        var events: [LandmarkEventSample] = []
        let inside = (playerPosition - encounter.center).magnitude <= encounter.radius
        next.activeEncounterId = encounter.id

        if inside && !state.isPlayerInside {
            next.isPlayerInside = true
            next.enteredElapsed = elapsed
            next.timeInsideSeconds = 0
            next.firedHazardKinds = []
            next.appliedGuardTargetDelta = encounter.whileInside.guardTargetDelta
            next.appliedObservationBonus = encounter.whileInside.observationPressureBonus
            next.appliedSpawnIntervalMultiplier = encounter.whileInside.spawnIntervalMultiplier
            events.append(
                LandmarkEventSample(
                    tick: tick,
                    encounterId: encounter.id,
                    kind: "entered",
                    reason: "entered \(encounter.displayName)"
                )
            )
        } else if !inside && state.isPlayerInside {
            next.isPlayerInside = false
            next.enteredElapsed = nil
            next.timeInsideSeconds = 0
            next.firedHazardKinds = []
            next.appliedGuardTargetDelta = 0
            next.appliedObservationBonus = 0
            next.appliedSpawnIntervalMultiplier = 1
            events.append(
                LandmarkEventSample(
                    tick: tick,
                    encounterId: encounter.id,
                    kind: "exited",
                    reason: "left \(encounter.displayName)"
                )
            )
        }

        if inside {
            next.timeInsideSeconds += fixedStep
            for (index, hazard) in encounter.hazardSchedule.enumerated() {
                // Index + full timestamp: same-kind hazards in one integer second must not collide.
                let key = "\(index):\(hazard.kind)@\(hazard.atElapsedSeconds)"
                guard !next.firedHazardKinds.contains(key) else { continue }
                guard next.timeInsideSeconds >= hazard.atElapsedSeconds else { continue }
                next.firedHazardKinds.append(key)
                next.appliedObservationBonus = min(
                    0.5,
                    next.appliedObservationBonus + hazard.observationPressureBonus
                )
                next.appliedGuardTargetDelta += hazard.guardTargetDelta
                events.append(
                    LandmarkEventSample(
                        tick: tick,
                        encounterId: encounter.id,
                        kind: "hazard",
                        reason: "hazard \(hazard.kind)"
                    )
                )
            }
        }

        let nudge = inside ? encounter.bossHooks.nudgeSuspicionPerSecondWhileInside : 0
        let minimumTier = inside ? encounter.bossHooks.minimumTierRaw : 0
        return LandmarkStepResult(
            state: next,
            events: events,
            suspicionNudgePerSecond: nudge,
            minimumTierRaw: minimumTier
        )
    }
}
