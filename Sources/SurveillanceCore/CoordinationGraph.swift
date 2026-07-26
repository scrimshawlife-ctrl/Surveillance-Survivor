import Foundation

// MARK: - Content authority

/// Enemy Coordination Graph authority (P8 E5). Interruptible chains with ≥2 counterplay points.
public struct CoordinationCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let schemaId: String
    public let forbidHiddenStatScaling: Bool
    public let minimumCounterplayPoints: Int
    public let evaluationIntervalTicks: UInt64
    public let forbiddenLeverKeys: [String]
    public let chains: [CoordinationChainDefinition]

    public static let currentSchemaVersion = 1
    public static let expectedSchemaId = "surveillance-survivor/coordination_graphs"

    public static let allowedAdvanceSignals: Set<String> = ["sensorContact", "timer"]
    public static let allowedInterruptSignals: Set<String> = [
        "sensorDestroyed", "sensorSpoofed", "sensorDisabled", "guardDisrupted"
    ]
    public static let allowedLeverKeys: Set<String> = [
        "guardTargetDelta", "observationPressureBonus", "spawnIntervalMultiplier"
    ]

    public static let bundled: CoordinationCatalog = {
        do { return try loadBundled() }
        catch { preconditionFailure("Invalid bundled coordination graphs: \(error)") }
    }()

    public static func loadBundled() throws -> CoordinationCatalog {
        guard let url = contentBundle.url(forResource: "coordination_graphs", withExtension: "json", subdirectory: "Content")
            ?? contentBundle.url(forResource: "coordination_graphs", withExtension: "json")
        else { throw CoordinationError.missingResource }
        let catalog = try JSONDecoder().decode(CoordinationCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func chain(id: String) -> CoordinationChainDefinition? {
        chains.first { $0.id == id }
    }

    public func primaryChain(for district: DistrictID) -> CoordinationChainDefinition? {
        chains.first { $0.districtIds.contains(district.rawValue) } ?? chains.first
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw CoordinationError.unsupportedSchema(schemaVersion)
        }
        guard schemaId == Self.expectedSchemaId else {
            throw CoordinationError.invalidDefinition("schemaId must be \(Self.expectedSchemaId)")
        }
        guard forbidHiddenStatScaling else {
            throw CoordinationError.invalidDefinition("forbidHiddenStatScaling must be true")
        }
        guard minimumCounterplayPoints >= 2 else {
            throw CoordinationError.invalidDefinition("minimumCounterplayPoints must be ≥2")
        }
        guard evaluationIntervalTicks > 0 else {
            throw CoordinationError.invalidDefinition("evaluationIntervalTicks must be > 0")
        }
        let forbidden = Set(forbiddenLeverKeys)
        guard forbidden.isSuperset(of: ["playerDamageScale", "enemyHealthScale", "playerHealthScale", "hiddenDifficulty"]) else {
            throw CoordinationError.invalidDefinition("forbiddenLeverKeys missing required bans")
        }
        guard !chains.isEmpty else {
            throw CoordinationError.invalidDefinition("chains must be non-empty")
        }
        guard Set(chains.map(\.id)).count == chains.count else {
            throw CoordinationError.invalidDefinition("duplicate chain ids")
        }
        for chain in chains {
            try chain.validate(
                minCounterplay: minimumCounterplayPoints,
                allowedAdvance: Self.allowedAdvanceSignals,
                allowedInterrupt: Self.allowedInterruptSignals,
                allowedLevers: Self.allowedLeverKeys,
                forbiddenLevers: forbidden
            )
        }
    }
}

public struct CoordinationLinkLevers: Codable, Equatable, Sendable {
    public let guardTargetDelta: Int
    public let observationPressureBonus: Double
    public let spawnIntervalMultiplier: Double

    public init(
        guardTargetDelta: Int = 0,
        observationPressureBonus: Double = 0,
        spawnIntervalMultiplier: Double = 1
    ) {
        self.guardTargetDelta = guardTargetDelta
        self.observationPressureBonus = observationPressureBonus
        self.spawnIntervalMultiplier = spawnIntervalMultiplier
    }

    func validate(forbidden: Set<String>) throws {
        let keys = Set(["guardTargetDelta", "observationPressureBonus", "spawnIntervalMultiplier"])
        guard keys.isDisjoint(with: forbidden) else {
            throw CoordinationError.invalidDefinition("forbidden lever collision")
        }
        guard (-2...4).contains(guardTargetDelta) else {
            throw CoordinationError.invalidDefinition("guardTargetDelta out of band")
        }
        guard (0...0.5).contains(observationPressureBonus) else {
            throw CoordinationError.invalidDefinition("observationPressureBonus out of band")
        }
        guard (0.5...1.5).contains(spawnIntervalMultiplier) else {
            throw CoordinationError.invalidDefinition("spawnIntervalMultiplier out of band")
        }
    }
}

public struct CoordinationLinkDefinition: Codable, Equatable, Sendable {
    public let id: String
    public let role: String
    public let label: String
    public let advanceOn: [String]
    public let interruptOn: [String]
    public let counterplay: Bool
    public let timerSeconds: Double?
    public let levers: CoordinationLinkLevers
}

public struct CoordinationChainDefinition: Codable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let districtIds: [String]
    public let links: [CoordinationLinkDefinition]

    public func link(at index: Int) -> CoordinationLinkDefinition? {
        guard links.indices.contains(index) else { return nil }
        return links[index]
    }

    func validate(
        minCounterplay: Int,
        allowedAdvance: Set<String>,
        allowedInterrupt: Set<String>,
        allowedLevers: Set<String>,
        forbiddenLevers: Set<String>
    ) throws {
        guard !id.isEmpty, !displayName.isEmpty else {
            throw CoordinationError.invalidDefinition("chain id/displayName required")
        }
        guard links.count >= 3 else {
            throw CoordinationError.invalidDefinition("\(id) needs ≥3 links")
        }
        guard Set(links.map(\.id)).count == links.count else {
            throw CoordinationError.invalidDefinition("\(id) duplicate link ids")
        }
        let counterplayCount = links.filter(\.counterplay).count
        guard counterplayCount >= minCounterplay else {
            throw CoordinationError.invalidDefinition("\(id) needs ≥\(minCounterplay) counterplay links")
        }
        for link in links {
            guard !link.id.isEmpty, !link.label.isEmpty, !link.role.isEmpty else {
                throw CoordinationError.invalidDefinition("\(id) link missing identity fields")
            }
            guard !link.advanceOn.isEmpty else {
                throw CoordinationError.invalidDefinition("\(id)/\(link.id) advanceOn empty")
            }
            for signal in link.advanceOn where !allowedAdvance.contains(signal) {
                throw CoordinationError.invalidDefinition("\(id)/\(link.id) bad advance \(signal)")
            }
            for signal in link.interruptOn where !allowedInterrupt.contains(signal) {
                throw CoordinationError.invalidDefinition("\(id)/\(link.id) bad interrupt \(signal)")
            }
            if link.advanceOn.contains("timer") {
                guard let seconds = link.timerSeconds, seconds > 0 else {
                    throw CoordinationError.invalidDefinition("\(id)/\(link.id) timerSeconds required")
                }
            }
            // Ensure lever object only uses allowed keys via Codable shape + band checks.
            _ = allowedLevers
            try link.levers.validate(forbidden: forbiddenLevers)
        }
    }
}

public enum CoordinationError: Error, Equatable, Sendable {
    case missingResource
    case unsupportedSchema(Int)
    case invalidDefinition(String)
}

// MARK: - Runtime

public enum CoordinationLinkStatus: String, Codable, Equatable, Sendable {
    case pending
    case active
    case completed
    case interrupted
}

public struct CoordinationState: Codable, Equatable, Sendable {
    public var chainId: String?
    public var activeLinkIndex: Int
    public var linkStatuses: [String: CoordinationLinkStatus]
    public var linkEnteredElapsed: Double
    public var appliedGuardTargetDelta: Int
    public var appliedObservationBonus: Double
    public var appliedSpawnIntervalMultiplier: Double
    public var interruptedCount: Int
    public var completedCount: Int

    public static let idle = CoordinationState(
        chainId: nil,
        activeLinkIndex: 0,
        linkStatuses: [:],
        linkEnteredElapsed: 0,
        appliedGuardTargetDelta: 0,
        appliedObservationBonus: 0,
        appliedSpawnIntervalMultiplier: 1,
        interruptedCount: 0,
        completedCount: 0
    )

    public init(
        chainId: String? = nil,
        activeLinkIndex: Int = 0,
        linkStatuses: [String: CoordinationLinkStatus] = [:],
        linkEnteredElapsed: Double = 0,
        appliedGuardTargetDelta: Int = 0,
        appliedObservationBonus: Double = 0,
        appliedSpawnIntervalMultiplier: Double = 1,
        interruptedCount: Int = 0,
        completedCount: Int = 0
    ) {
        self.chainId = chainId
        self.activeLinkIndex = activeLinkIndex
        self.linkStatuses = linkStatuses
        self.linkEnteredElapsed = linkEnteredElapsed
        self.appliedGuardTargetDelta = appliedGuardTargetDelta
        self.appliedObservationBonus = appliedObservationBonus
        self.appliedSpawnIntervalMultiplier = appliedSpawnIntervalMultiplier
        self.interruptedCount = interruptedCount
        self.completedCount = completedCount
    }
}

public struct CoordinationEventSample: Codable, Equatable, Sendable {
    public var tick: UInt64
    public var chainId: String
    public var linkId: String
    public var status: CoordinationLinkStatus
    public var signal: String
    public var reason: String

    public init(
        tick: UInt64,
        chainId: String,
        linkId: String,
        status: CoordinationLinkStatus,
        signal: String,
        reason: String
    ) {
        self.tick = tick
        self.chainId = chainId
        self.linkId = linkId
        self.status = status
        self.signal = signal
        self.reason = reason
    }
}

public struct CoordinationStepResult: Equatable, Sendable {
    public var state: CoordinationState
    public var events: [CoordinationEventSample]
}

public enum CoordinationEngine: Sendable {
    public static func startIfNeeded(
        catalog: CoordinationCatalog = .bundled,
        state: CoordinationState,
        district: DistrictID,
        elapsed: Double,
        tick: UInt64,
        signal: String
    ) -> CoordinationStepResult {
        guard catalog.forbidHiddenStatScaling else {
            return CoordinationStepResult(state: state, events: [])
        }
        // Only idle chains start on sensor contact.
        guard state.chainId == nil, signal == "sensorContact" else {
            return CoordinationStepResult(state: state, events: [])
        }
        guard let chain = catalog.primaryChain(for: district), let first = chain.links.first else {
            return CoordinationStepResult(state: state, events: [])
        }
        var next = CoordinationState.idle
        // Preserve cumulative chain history across restarts (idle only clears active levers).
        next.interruptedCount = state.interruptedCount
        next.completedCount = state.completedCount
        next.chainId = chain.id
        next.activeLinkIndex = 0
        next.linkEnteredElapsed = elapsed
        for link in chain.links {
            next.linkStatuses[link.id] = .pending
        }
        next.linkStatuses[first.id] = .active
        applyLevers(from: first, into: &next)
        let event = CoordinationEventSample(
            tick: tick,
            chainId: chain.id,
            linkId: first.id,
            status: .active,
            signal: signal,
            reason: "chain started: \(first.label)"
        )
        return CoordinationStepResult(state: next, events: [event])
    }

    public static func handleSignal(
        catalog: CoordinationCatalog = .bundled,
        state: CoordinationState,
        elapsed: Double,
        tick: UInt64,
        signal: String
    ) -> CoordinationStepResult {
        guard catalog.forbidHiddenStatScaling else {
            return CoordinationStepResult(state: state, events: [])
        }
        guard let chainId = state.chainId, let chain = catalog.chain(id: chainId) else {
            return CoordinationStepResult(state: state, events: [])
        }
        guard let link = chain.link(at: state.activeLinkIndex) else {
            return CoordinationStepResult(state: state, events: [])
        }

        var next = state
        var events: [CoordinationEventSample] = []

        if link.interruptOn.contains(signal) {
            next.linkStatuses[link.id] = .interrupted
            next.interruptedCount += 1
            next.chainId = nil
            next.appliedGuardTargetDelta = 0
            next.appliedObservationBonus = 0
            next.appliedSpawnIntervalMultiplier = 1
            events.append(
                CoordinationEventSample(
                    tick: tick,
                    chainId: chainId,
                    linkId: link.id,
                    status: .interrupted,
                    signal: signal,
                    reason: "interrupted \(link.label)"
                )
            )
            return CoordinationStepResult(state: next, events: events)
        }

        if link.advanceOn.contains(signal) {
            return advance(
                catalog: catalog,
                chain: chain,
                state: next,
                elapsed: elapsed,
                tick: tick,
                signal: signal
            )
        }
        return CoordinationStepResult(state: next, events: events)
    }

    public static func tickTimers(
        catalog: CoordinationCatalog = .bundled,
        state: CoordinationState,
        elapsed: Double,
        tick: UInt64
    ) -> CoordinationStepResult {
        guard let chainId = state.chainId, let chain = catalog.chain(id: chainId) else {
            return CoordinationStepResult(state: state, events: [])
        }
        guard let link = chain.link(at: state.activeLinkIndex) else {
            return CoordinationStepResult(state: state, events: [])
        }
        guard link.advanceOn.contains("timer"), let seconds = link.timerSeconds else {
            return CoordinationStepResult(state: state, events: [])
        }
        guard elapsed - state.linkEnteredElapsed >= seconds else {
            return CoordinationStepResult(state: state, events: [])
        }
        return advance(
            catalog: catalog,
            chain: chain,
            state: state,
            elapsed: elapsed,
            tick: tick,
            signal: "timer"
        )
    }

    private static func advance(
        catalog: CoordinationCatalog,
        chain: CoordinationChainDefinition,
        state: CoordinationState,
        elapsed: Double,
        tick: UInt64,
        signal: String
    ) -> CoordinationStepResult {
        var next = state
        var events: [CoordinationEventSample] = []
        guard let current = chain.link(at: next.activeLinkIndex) else {
            return CoordinationStepResult(state: state, events: [])
        }
        next.linkStatuses[current.id] = .completed
        let nextIndex = next.activeLinkIndex + 1
        if let following = chain.link(at: nextIndex) {
            events.append(
                CoordinationEventSample(
                    tick: tick,
                    chainId: chain.id,
                    linkId: current.id,
                    status: .completed,
                    signal: signal,
                    reason: "completed \(current.label)"
                )
            )
            next.activeLinkIndex = nextIndex
            next.linkEnteredElapsed = elapsed
            next.linkStatuses[following.id] = .active
            applyLevers(from: following, into: &next)
            events.append(
                CoordinationEventSample(
                    tick: tick,
                    chainId: chain.id,
                    linkId: following.id,
                    status: .active,
                    signal: signal,
                    reason: "advanced to \(following.label)"
                )
            )
        } else {
            next.completedCount += 1
            next.chainId = nil
            next.appliedGuardTargetDelta = 0
            next.appliedObservationBonus = 0
            next.appliedSpawnIntervalMultiplier = 1
            // Single terminal event — avoid duplicate `.completed` for the same link.
            events.append(
                CoordinationEventSample(
                    tick: tick,
                    chainId: chain.id,
                    linkId: current.id,
                    status: .completed,
                    signal: signal,
                    reason: "chain completed"
                )
            )
        }
        _ = catalog
        return CoordinationStepResult(state: next, events: events)
    }

    private static func applyLevers(from link: CoordinationLinkDefinition, into state: inout CoordinationState) {
        state.appliedGuardTargetDelta = link.levers.guardTargetDelta
        state.appliedObservationBonus = link.levers.observationPressureBonus
        state.appliedSpawnIntervalMultiplier = link.levers.spawnIntervalMultiplier
    }
}
