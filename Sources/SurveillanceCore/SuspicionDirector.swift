import Foundation

// MARK: - Content authority

/// Bundled Suspicion Director rules. Contracts only — no hidden damage/health scaling.
public struct SuspicionDirectorCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let schemaId: String
    public let forbidHiddenStatScaling: Bool
    public let evaluationIntervalTicks: UInt64
    public let maxRecentActions: Int
    public let forbiddenLeverKeys: [String]
    public let tiers: [DirectorTierRule]
    public let actions: [DirectorActionDefinition]

    public static let currentSchemaVersion = 1
    public static let expectedSchemaId = "surveillance-survivor/director_rules"

    public static let bundled: SuspicionDirectorCatalog = {
        do { return try loadBundled() }
        catch { preconditionFailure("Invalid bundled director rules: \(error)") }
    }()

    public static func loadBundled() throws -> SuspicionDirectorCatalog {
        guard let url = contentBundle.url(forResource: "director_rules", withExtension: "json", subdirectory: "Content")
            ?? contentBundle.url(forResource: "director_rules", withExtension: "json")
        else { throw SuspicionDirectorError.missingResource }
        let catalog = try JSONDecoder().decode(SuspicionDirectorCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func action(id: String) -> DirectorActionDefinition? {
        actions.first { $0.id == id }
    }

    public func tierRule(for tier: SuspicionTier) -> DirectorTierRule? {
        tiers.first { $0.tier == tier.rawValue }
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw SuspicionDirectorError.unsupportedSchema(schemaVersion)
        }
        guard schemaId == Self.expectedSchemaId else {
            throw SuspicionDirectorError.invalidDefinition("schemaId must be \(Self.expectedSchemaId)")
        }
        guard forbidHiddenStatScaling else {
            throw SuspicionDirectorError.invalidDefinition("forbidHiddenStatScaling must be true")
        }
        guard evaluationIntervalTicks > 0 else {
            throw SuspicionDirectorError.invalidDefinition("evaluationIntervalTicks must be > 0")
        }
        guard maxRecentActions > 0 else {
            throw SuspicionDirectorError.invalidDefinition("maxRecentActions must be > 0")
        }
        guard !forbiddenLeverKeys.isEmpty else {
            throw SuspicionDirectorError.invalidDefinition("forbiddenLeverKeys must be non-empty")
        }
        guard Set(tiers.map(\.tier)).count == tiers.count else {
            throw SuspicionDirectorError.invalidDefinition("duplicate tier rows")
        }
        guard Set(tiers.map(\.tier)) == Set(0...5) else {
            throw SuspicionDirectorError.invalidDefinition("tiers must cover 0...5 exactly")
        }
        guard !actions.isEmpty else {
            throw SuspicionDirectorError.invalidDefinition("actions must be non-empty")
        }
        guard Set(actions.map(\.id)).count == actions.count else {
            throw SuspicionDirectorError.invalidDefinition("duplicate action ids")
        }

        let actionIDs = Set(actions.map(\.id))
        for tier in tiers {
            guard tier.pressureWindowSeconds > 0, tier.encounterBudget >= 0 else {
                throw SuspicionDirectorError.invalidDefinition("tier \(tier.tier) has invalid budget window")
            }
            guard !tier.allowedActionIds.isEmpty else {
                throw SuspicionDirectorError.invalidDefinition("tier \(tier.tier) has no allowed actions")
            }
            for actionID in tier.allowedActionIds where !actionIDs.contains(actionID) {
                throw SuspicionDirectorError.invalidDefinition("tier \(tier.tier) references unknown action \(actionID)")
            }
        }

        let forbidden = Set(forbiddenLeverKeys)
        for action in actions {
            try action.validate(forbiddenLeverKeys: forbidden)
        }
    }
}

public struct DirectorTierRule: Codable, Equatable, Sendable {
    public let tier: Int
    public let pressureWindowSeconds: Double
    public let encounterBudget: Int
    public let allowedActionIds: [String]
}

public struct DirectorActionLevers: Codable, Equatable, Sendable {
    /// Additive change to guard population target for the active pressure window.
    public let guardTargetDelta: Int
    /// Multiplies guard spawn interval (lower = more frequent). Clamped at runtime to a safe band.
    public let spawnIntervalMultiplier: Double
    /// Multiplies sensor deployment cadence (lower = more frequent). Clamped at runtime.
    public let sensorCadenceMultiplier: Double

    public init(
        guardTargetDelta: Int = 0,
        spawnIntervalMultiplier: Double = 1.0,
        sensorCadenceMultiplier: Double = 1.0
    ) {
        self.guardTargetDelta = guardTargetDelta
        self.spawnIntervalMultiplier = spawnIntervalMultiplier
        self.sensorCadenceMultiplier = sensorCadenceMultiplier
    }

    func validate(forbiddenLeverKeys: Set<String>) throws {
        // Explicit, readable levers only. Forbidden keys are reserved names that must never appear.
        let mirror: [String: Double] = [
            "guardTargetDelta": Double(guardTargetDelta),
            "spawnIntervalMultiplier": spawnIntervalMultiplier,
            "sensorCadenceMultiplier": sensorCadenceMultiplier
        ]
        for key in forbiddenLeverKeys where mirror.keys.contains(key) {
            throw SuspicionDirectorError.invalidDefinition("forbidden lever key present: \(key)")
        }
        guard spawnIntervalMultiplier > 0, sensorCadenceMultiplier > 0 else {
            throw SuspicionDirectorError.invalidDefinition("multipliers must be > 0")
        }
        guard (0.25...2.0).contains(spawnIntervalMultiplier) else {
            throw SuspicionDirectorError.invalidDefinition("spawnIntervalMultiplier out of band \(spawnIntervalMultiplier)")
        }
        guard (0.25...2.0).contains(sensorCadenceMultiplier) else {
            throw SuspicionDirectorError.invalidDefinition("sensorCadenceMultiplier out of band \(sensorCadenceMultiplier)")
        }
        guard (-4...6).contains(guardTargetDelta) else {
            throw SuspicionDirectorError.invalidDefinition("guardTargetDelta out of band \(guardTargetDelta)")
        }
    }
}

public struct DirectorActionDefinition: Codable, Equatable, Sendable {
    public let id: String
    public let cooldownSeconds: Double
    public let budgetCost: Int
    public let weight: Int
    public let levers: DirectorActionLevers

    func validate(forbiddenLeverKeys: Set<String>) throws {
        guard !id.isEmpty else { throw SuspicionDirectorError.invalidDefinition("empty action id") }
        guard cooldownSeconds >= 0 else { throw SuspicionDirectorError.invalidDefinition("\(id) cooldown must be >= 0") }
        guard budgetCost >= 0 else { throw SuspicionDirectorError.invalidDefinition("\(id) budgetCost must be >= 0") }
        guard weight > 0 else { throw SuspicionDirectorError.invalidDefinition("\(id) weight must be > 0") }
        try levers.validate(forbiddenLeverKeys: forbiddenLeverKeys)
    }
}

public enum SuspicionDirectorError: Error, Equatable, Sendable {
    case missingResource
    case unsupportedSchema(Int)
    case invalidDefinition(String)
}

// MARK: - Runtime state + decisions

public struct SuspicionDirectorState: Codable, Equatable, Sendable {
    public var activeActionId: String?
    public var windowStartedElapsed: Double
    public var budgetRemaining: Int
    /// Tier that opened the current pressure window; mismatches force a budget reset.
    public var windowTier: SuspicionTier?
    /// Earliest `elapsed` when each action id may fire again.
    public var actionAvailableAtElapsed: [String: Double]
    public var recentActionIds: [String]
    public var appliedGuardTargetDelta: Int
    public var appliedSpawnIntervalMultiplier: Double
    public var appliedSensorCadenceMultiplier: Double

    public static let neutral = SuspicionDirectorState(
        activeActionId: nil,
        windowStartedElapsed: 0,
        budgetRemaining: 0,
        windowTier: nil,
        actionAvailableAtElapsed: [:],
        recentActionIds: [],
        appliedGuardTargetDelta: 0,
        appliedSpawnIntervalMultiplier: 1.0,
        appliedSensorCadenceMultiplier: 1.0
    )

    public init(
        activeActionId: String? = nil,
        windowStartedElapsed: Double = 0,
        budgetRemaining: Int = 0,
        windowTier: SuspicionTier? = nil,
        actionAvailableAtElapsed: [String: Double] = [:],
        recentActionIds: [String] = [],
        appliedGuardTargetDelta: Int = 0,
        appliedSpawnIntervalMultiplier: Double = 1.0,
        appliedSensorCadenceMultiplier: Double = 1.0
    ) {
        self.activeActionId = activeActionId
        self.windowStartedElapsed = windowStartedElapsed
        self.budgetRemaining = budgetRemaining
        self.windowTier = windowTier
        self.actionAvailableAtElapsed = actionAvailableAtElapsed
        self.recentActionIds = recentActionIds
        self.appliedGuardTargetDelta = appliedGuardTargetDelta
        self.appliedSpawnIntervalMultiplier = appliedSpawnIntervalMultiplier
        self.appliedSensorCadenceMultiplier = appliedSensorCadenceMultiplier
    }

    private enum CodingKeys: String, CodingKey {
        case activeActionId, windowStartedElapsed, budgetRemaining, windowTier
        case actionAvailableAtElapsed, recentActionIds
        case appliedGuardTargetDelta, appliedSpawnIntervalMultiplier, appliedSensorCadenceMultiplier
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        activeActionId = try c.decodeIfPresent(String.self, forKey: .activeActionId)
        windowStartedElapsed = try c.decodeIfPresent(Double.self, forKey: .windowStartedElapsed) ?? 0
        budgetRemaining = try c.decodeIfPresent(Int.self, forKey: .budgetRemaining) ?? 0
        windowTier = try c.decodeIfPresent(SuspicionTier.self, forKey: .windowTier)
        actionAvailableAtElapsed = try c.decodeIfPresent([String: Double].self, forKey: .actionAvailableAtElapsed) ?? [:]
        recentActionIds = try c.decodeIfPresent([String].self, forKey: .recentActionIds) ?? []
        appliedGuardTargetDelta = try c.decodeIfPresent(Int.self, forKey: .appliedGuardTargetDelta) ?? 0
        appliedSpawnIntervalMultiplier = try c.decodeIfPresent(Double.self, forKey: .appliedSpawnIntervalMultiplier) ?? 1.0
        appliedSensorCadenceMultiplier = try c.decodeIfPresent(Double.self, forKey: .appliedSensorCadenceMultiplier) ?? 1.0
    }
}

public struct DirectorDecisionSample: Codable, Equatable, Sendable {
    public var tick: UInt64
    public var elapsed: Double
    public var tier: SuspicionTier
    public var actionId: String
    public var budgetRemaining: Int
    public var reason: String

    public init(
        tick: UInt64,
        elapsed: Double,
        tier: SuspicionTier,
        actionId: String,
        budgetRemaining: Int,
        reason: String
    ) {
        self.tick = tick
        self.elapsed = elapsed
        self.tier = tier
        self.actionId = actionId
        self.budgetRemaining = budgetRemaining
        self.reason = reason
    }
}

public struct DirectorEvaluationResult: Equatable, Sendable {
    public var state: SuspicionDirectorState
    public var decision: DirectorDecisionSample?
}

/// Pure, seed-deterministic Suspicion Director evaluation (no sim side effects).
public enum SuspicionDirector: Sendable {
    public static func evaluate(
        catalog: SuspicionDirectorCatalog = .bundled,
        state: SuspicionDirectorState,
        tier: SuspicionTier,
        elapsed: Double,
        tick: UInt64,
        rng: inout DeterministicRNG,
        budgetCostRelief: Int = 0
    ) -> DirectorEvaluationResult {
        guard let tierRule = catalog.tierRule(for: tier) else {
            return DirectorEvaluationResult(state: state, decision: nil)
        }

        var next = state
        // `windowTier == nil` is the uninitialized sentinel; elapsed 0 is a valid window start.
        let needsNewWindow =
            next.windowTier == nil
            || next.windowTier != tier
            || elapsed - next.windowStartedElapsed >= tierRule.pressureWindowSeconds
        if needsNewWindow {
            next.windowStartedElapsed = elapsed
            next.budgetRemaining = tierRule.encounterBudget
            next.windowTier = tier
        }

        let relief = max(0, budgetCostRelief)
        let candidates = tierRule.allowedActionIds.compactMap { actionID -> DirectorActionDefinition? in
            guard let action = catalog.action(id: actionID) else { return nil }
            let availableAt = next.actionAvailableAtElapsed[actionID] ?? 0
            guard elapsed >= availableAt else { return nil }
            let effectiveCost = max(0, action.budgetCost - relief)
            guard effectiveCost <= next.budgetRemaining else { return nil }
            return action
        }

        guard !candidates.isEmpty else {
            // Cooldown gaps / exhausted budget must not leave the previous action's levers sticky.
            next.activeActionId = nil
            next.appliedGuardTargetDelta = 0
            next.appliedSpawnIntervalMultiplier = 1.0
            next.appliedSensorCadenceMultiplier = 1.0
            return DirectorEvaluationResult(state: next, decision: nil)
        }

        let totalWeight = candidates.reduce(0) { $0 + $1.weight }
        var roll = Int(rng.next() % UInt64(max(totalWeight, 1)))
        var chosen = candidates[0]
        for candidate in candidates {
            roll -= candidate.weight
            if roll < 0 {
                chosen = candidate
                break
            }
        }

        next.activeActionId = chosen.id
        let effectiveCost = max(0, chosen.budgetCost - relief)
        next.budgetRemaining = max(0, next.budgetRemaining - effectiveCost)
        next.actionAvailableAtElapsed[chosen.id] = elapsed + chosen.cooldownSeconds
        next.appliedGuardTargetDelta = chosen.levers.guardTargetDelta
        next.appliedSpawnIntervalMultiplier = chosen.levers.spawnIntervalMultiplier
        next.appliedSensorCadenceMultiplier = chosen.levers.sensorCadenceMultiplier
        next.recentActionIds.append(chosen.id)
        if next.recentActionIds.count > catalog.maxRecentActions {
            next.recentActionIds.removeFirst(next.recentActionIds.count - catalog.maxRecentActions)
        }

        let decision = DirectorDecisionSample(
            tick: tick,
            elapsed: elapsed,
            tier: tier,
            actionId: chosen.id,
            budgetRemaining: next.budgetRemaining,
            reason: "tier \(tier.rawValue) budgeted action"
        )
        return DirectorEvaluationResult(state: next, decision: decision)
    }
}
