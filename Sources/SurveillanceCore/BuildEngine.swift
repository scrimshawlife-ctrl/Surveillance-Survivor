import Foundation

// MARK: - Content authority

/// Emergent Build Engine: tags, triggers, exclusions, thresholds, and explicit behaviors.
/// Builds must alter readable behavior — never hidden damage/health scaling.
public struct BuildEngineCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let schemaId: String
    public let forbidHiddenStatScaling: Bool
    public let families: [String]
    public let forbiddenBehaviorKinds: [String]
    public let upgradeTags: [String: [String]]
    public let synergies: [BuildSynergyDefinition]

    public static let currentSchemaVersion = 1
    public static let expectedSchemaId = "surveillance-survivor/build_synergies"

    public static let expectedFamilies: Set<String> = [
        "signalDisruption",
        "socialCamouflage",
        "bureaucraticWarfare",
        "physicalDisruption",
        "mobilityModification",
        "decoysIdentity",
        "infrastructureParasitism",
        "highSuspicionRisk"
    ]

    public static let allowedBehaviorKinds: Set<String> = [
        "suspicionRecoveryBoost",
        "observationSoftener",
        "directorBudgetRelief"
    ]

    public static let bundled: BuildEngineCatalog = {
        do { return try loadBundled() }
        catch { preconditionFailure("Invalid bundled build synergies: \(error)") }
    }()

    public static func loadBundled() throws -> BuildEngineCatalog {
        guard let url = contentBundle.url(forResource: "build_synergies", withExtension: "json", subdirectory: "Content")
            ?? contentBundle.url(forResource: "build_synergies", withExtension: "json")
        else { throw BuildEngineError.missingResource }
        let catalog = try JSONDecoder().decode(BuildEngineCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func tags(for upgrade: UpgradeChoice) -> [String] {
        upgradeTags[upgrade.rawValue] ?? []
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw BuildEngineError.unsupportedSchema(schemaVersion)
        }
        guard schemaId == Self.expectedSchemaId else {
            throw BuildEngineError.invalidDefinition("schemaId must be \(Self.expectedSchemaId)")
        }
        guard forbidHiddenStatScaling else {
            throw BuildEngineError.invalidDefinition("forbidHiddenStatScaling must be true")
        }
        guard Set(families) == Self.expectedFamilies else {
            throw BuildEngineError.invalidDefinition("families must match the approved eight build families")
        }
        guard !forbiddenBehaviorKinds.isEmpty else {
            throw BuildEngineError.invalidDefinition("forbiddenBehaviorKinds must be non-empty")
        }
        let forbidden = Set(forbiddenBehaviorKinds)
        guard forbidden.isSuperset(of: ["playerDamageScale", "enemyHealthScale", "playerHealthScale", "hiddenDifficulty"]) else {
            throw BuildEngineError.invalidDefinition("forbiddenBehaviorKinds missing required stat-scale bans")
        }

        // Every upgrade choice must be tagged.
        let upgradeKeys = Set(upgradeTags.keys)
        let expectedUpgrades = Set(UpgradeChoice.allCases.map(\.rawValue))
        guard upgradeKeys == expectedUpgrades else {
            throw BuildEngineError.invalidDefinition("upgradeTags must cover every UpgradeChoice exactly")
        }
        for (upgrade, tags) in upgradeTags {
            guard !tags.isEmpty else {
                throw BuildEngineError.invalidDefinition("upgrade \(upgrade) needs ≥1 tag")
            }
            for tag in tags where !Self.expectedFamilies.contains(tag) {
                throw BuildEngineError.invalidDefinition("upgrade \(upgrade) unknown tag \(tag)")
            }
        }

        guard !synergies.isEmpty else {
            throw BuildEngineError.invalidDefinition("synergies must be non-empty")
        }
        guard Set(synergies.map(\.id)).count == synergies.count else {
            throw BuildEngineError.invalidDefinition("duplicate synergy ids")
        }
        for synergy in synergies {
            try synergy.validate(families: Self.expectedFamilies, allowedBehaviors: Self.allowedBehaviorKinds, forbidden: forbidden)
        }
    }
}

public struct BuildSynergyBehavior: Codable, Equatable, Sendable {
    public let kind: String
    public let amount: Double
}

public struct BuildSynergyDefinition: Codable, Equatable, Sendable {
    public let id: String
    public let requiredTags: [String]
    public let minTagCounts: [String: Int]
    public let excludedTags: [String]
    public let minimumSelectedUpgrades: Int
    public let behavior: BuildSynergyBehavior
    public let readableSummary: String

    func validate(families: Set<String>, allowedBehaviors: Set<String>, forbidden: Set<String>) throws {
        guard !id.isEmpty else { throw BuildEngineError.invalidDefinition("empty synergy id") }
        guard !readableSummary.isEmpty else {
            throw BuildEngineError.invalidDefinition("\(id) needs readableSummary")
        }
        guard minimumSelectedUpgrades >= 1 else {
            throw BuildEngineError.invalidDefinition("\(id) minimumSelectedUpgrades must be ≥1")
        }
        for tag in requiredTags + excludedTags + Array(minTagCounts.keys) where !families.contains(tag) {
            throw BuildEngineError.invalidDefinition("\(id) unknown tag \(tag)")
        }
        for (tag, count) in minTagCounts where count < 1 {
            throw BuildEngineError.invalidDefinition("\(id) minTagCounts[\(tag)] must be ≥1")
        }
        guard allowedBehaviors.contains(behavior.kind) else {
            throw BuildEngineError.invalidDefinition("\(id) behavior kind \(behavior.kind) not allowed")
        }
        guard !forbidden.contains(behavior.kind) else {
            throw BuildEngineError.invalidDefinition("\(id) uses forbidden behavior \(behavior.kind)")
        }
        guard behavior.amount > 0 else {
            throw BuildEngineError.invalidDefinition("\(id) behavior amount must be > 0")
        }
        // Band-check by kind.
        switch behavior.kind {
        case "suspicionRecoveryBoost", "observationSoftener":
            guard behavior.amount <= 1 else {
                throw BuildEngineError.invalidDefinition("\(id) amount out of band for \(behavior.kind)")
            }
        case "directorBudgetRelief":
            guard behavior.amount <= 3 else {
                throw BuildEngineError.invalidDefinition("\(id) directorBudgetRelief amount out of band")
            }
        default:
            break
        }
    }
}

public enum BuildEngineError: Error, Equatable, Sendable {
    case missingResource
    case unsupportedSchema(Int)
    case invalidDefinition(String)
}

// MARK: - Runtime

public struct BuildEngineState: Codable, Equatable, Sendable {
    public var selectedUpgradeIds: [String]
    public var activeTagCounts: [String: Int]
    public var activeSynergyIds: [String]
    public var suspicionRecoveryBoost: Double
    public var observationSoftener: Double
    public var directorBudgetRelief: Int

    public static let empty = BuildEngineState(
        selectedUpgradeIds: [],
        activeTagCounts: [:],
        activeSynergyIds: [],
        suspicionRecoveryBoost: 0,
        observationSoftener: 0,
        directorBudgetRelief: 0
    )

    public init(
        selectedUpgradeIds: [String] = [],
        activeTagCounts: [String: Int] = [:],
        activeSynergyIds: [String] = [],
        suspicionRecoveryBoost: Double = 0,
        observationSoftener: Double = 0,
        directorBudgetRelief: Int = 0
    ) {
        self.selectedUpgradeIds = selectedUpgradeIds
        self.activeTagCounts = activeTagCounts
        self.activeSynergyIds = activeSynergyIds
        self.suspicionRecoveryBoost = suspicionRecoveryBoost
        self.observationSoftener = observationSoftener
        self.directorBudgetRelief = directorBudgetRelief
    }
}

public struct BuildSynergyActivationSample: Codable, Equatable, Sendable {
    public var tick: UInt64
    public var synergyId: String
    public var behaviorKind: String
    public var amount: Double
    public var summary: String

    public init(tick: UInt64, synergyId: String, behaviorKind: String, amount: Double, summary: String) {
        self.tick = tick
        self.synergyId = synergyId
        self.behaviorKind = behaviorKind
        self.amount = amount
        self.summary = summary
    }
}

public enum BuildEngine: Sendable {
    public static func evaluate(
        catalog: BuildEngineCatalog = .bundled,
        selected: [UpgradeChoice]
    ) -> BuildEngineState {
        var tagCounts: [String: Int] = [:]
        for upgrade in selected {
            for tag in catalog.tags(for: upgrade) {
                tagCounts[tag, default: 0] += 1
            }
        }

        var active: [BuildSynergyDefinition] = []
        for synergy in catalog.synergies {
            guard selected.count >= synergy.minimumSelectedUpgrades else { continue }
            let requiredOk = synergy.requiredTags.allSatisfy { (tagCounts[$0] ?? 0) > 0 }
            guard requiredOk else { continue }
            let minsOk = synergy.minTagCounts.allSatisfy { tag, need in (tagCounts[tag] ?? 0) >= need }
            guard minsOk else { continue }
            let excluded = synergy.excludedTags.contains { (tagCounts[$0] ?? 0) > 0 }
            guard !excluded else { continue }
            active.append(synergy)
        }

        var recovery = 0.0
        var softener = 0.0
        var budgetRelief = 0
        for synergy in active {
            switch synergy.behavior.kind {
            case "suspicionRecoveryBoost":
                recovery += synergy.behavior.amount
            case "observationSoftener":
                softener += synergy.behavior.amount
            case "directorBudgetRelief":
                budgetRelief += Int(synergy.behavior.amount.rounded(.down))
            default:
                break
            }
        }
        // Clamp explicit levers — never touch damage/HP.
        recovery = min(1.0, recovery)
        softener = min(0.5, softener)
        budgetRelief = min(3, max(0, budgetRelief))

        return BuildEngineState(
            selectedUpgradeIds: selected.map(\.rawValue),
            activeTagCounts: tagCounts,
            activeSynergyIds: active.map(\.id).sorted(),
            suspicionRecoveryBoost: recovery,
            observationSoftener: softener,
            directorBudgetRelief: budgetRelief
        )
    }

    public static func activations(
        catalog: BuildEngineCatalog = .bundled,
        state: BuildEngineState,
        tick: UInt64
    ) -> [BuildSynergyActivationSample] {
        state.activeSynergyIds.compactMap { id in
            guard let def = catalog.synergies.first(where: { $0.id == id }) else { return nil }
            return BuildSynergyActivationSample(
                tick: tick,
                synergyId: def.id,
                behaviorKind: def.behavior.kind,
                amount: def.behavior.amount,
                summary: def.readableSummary
            )
        }
    }
}
