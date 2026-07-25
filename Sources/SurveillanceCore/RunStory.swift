import Foundation

// MARK: - Content authority

/// Run Story Compiler rules. Facts may only fire when receipt evidence is present.
public struct RunStoryCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let schemaId: String
    public let forbidInventedNarrative: Bool
    public let maxSummaryLines: Int
    public let rules: [StoryFactRule]

    public static let currentSchemaVersion = 1
    public static let expectedSchemaId = "surveillance-survivor/story_fact_rules"

    public static let allowedEvidenceKinds: Set<String> = [
        "extractionCompleted",
        "playerDefeated",
        "eventKindPresent",
        "minDeaths",
        "minSelectedUpgrades",
        "minBuildSynergies",
        "minDirectorDecisions",
        "minCityStateEvents",
        "minCoordinationInterrupted",
        "minCoordinationCompleted",
        "minPeakSuspicion"
    ]

    public static let bundled: RunStoryCatalog = {
        do { return try loadBundled() }
        catch { preconditionFailure("Invalid bundled story fact rules: \(error)") }
    }()

    public static func loadBundled() throws -> RunStoryCatalog {
        guard let url = contentBundle.url(forResource: "story_fact_rules", withExtension: "json", subdirectory: "Content")
            ?? contentBundle.url(forResource: "story_fact_rules", withExtension: "json")
        else { throw RunStoryError.missingResource }
        let catalog = try JSONDecoder().decode(RunStoryCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw RunStoryError.unsupportedSchema(schemaVersion)
        }
        guard schemaId == Self.expectedSchemaId else {
            throw RunStoryError.invalidDefinition("schemaId must be \(Self.expectedSchemaId)")
        }
        guard forbidInventedNarrative else {
            throw RunStoryError.invalidDefinition("forbidInventedNarrative must be true")
        }
        guard maxSummaryLines >= 1, maxSummaryLines <= 12 else {
            throw RunStoryError.invalidDefinition("maxSummaryLines out of band")
        }
        guard !rules.isEmpty else {
            throw RunStoryError.invalidDefinition("rules must be non-empty")
        }
        guard Set(rules.map(\.id)).count == rules.count else {
            throw RunStoryError.invalidDefinition("duplicate rule ids")
        }
        for rule in rules {
            try rule.validate(allowedEvidence: Self.allowedEvidenceKinds)
        }
    }
}

public struct StoryFactEvidence: Codable, Equatable, Sendable {
    public let kind: String
    public let equals: Bool?
    public let eventKind: String?
    public let entityKind: String?
    public let minimum: Double?
}

public struct StoryFactRule: Codable, Equatable, Sendable {
    public let id: String
    public let priority: Int
    public let evidence: StoryFactEvidence
    public let template: String
    public let category: String

    func validate(allowedEvidence: Set<String>) throws {
        guard !id.isEmpty else { throw RunStoryError.invalidDefinition("empty rule id") }
        guard !template.isEmpty else { throw RunStoryError.invalidDefinition("\(id) empty template") }
        guard !category.isEmpty else { throw RunStoryError.invalidDefinition("\(id) empty category") }
        guard allowedEvidence.contains(evidence.kind) else {
            throw RunStoryError.invalidDefinition("\(id) unknown evidence kind \(evidence.kind)")
        }
        // Templates may only use known placeholders — no free-form invented fields.
        let allowedPlaceholders: Set<String> = [
            "{district}", "{count}", "{peak}", "{synergyList}", "{seed}"
        ]
        var search = template[...]
        while let open = search.firstIndex(of: "{") {
            guard let close = search[open...].firstIndex(of: "}") else {
                throw RunStoryError.invalidDefinition("\(id) unclosed placeholder")
            }
            let token = String(search[open...close])
            guard allowedPlaceholders.contains(token) else {
                throw RunStoryError.invalidDefinition("\(id) unknown placeholder \(token)")
            }
            search = search[search.index(after: close)...]
        }
        switch evidence.kind {
        case "extractionCompleted", "playerDefeated":
            guard evidence.equals != nil else {
                throw RunStoryError.invalidDefinition("\(id) requires equals")
            }
        case "eventKindPresent":
            guard let ek = evidence.eventKind, !ek.isEmpty else {
                throw RunStoryError.invalidDefinition("\(id) requires eventKind")
            }
        case "minDeaths":
            guard evidence.entityKind != nil, (evidence.minimum ?? 0) >= 1 else {
                throw RunStoryError.invalidDefinition("\(id) requires entityKind + minimum≥1")
            }
        case "minSelectedUpgrades", "minBuildSynergies", "minDirectorDecisions",
             "minCityStateEvents", "minCoordinationInterrupted", "minCoordinationCompleted",
             "minPeakSuspicion":
            guard (evidence.minimum ?? 0) >= 1 else {
                throw RunStoryError.invalidDefinition("\(id) requires minimum≥1")
            }
        default:
            break
        }
    }
}

public enum RunStoryError: Error, Equatable, Sendable {
    case missingResource
    case unsupportedSchema(Int)
    case invalidDefinition(String)
}

// MARK: - Facts + compiler

public struct StoryFact: Codable, Equatable, Sendable {
    public var id: String
    public var category: String
    public var text: String
    public var priority: Int

    public init(id: String, category: String, text: String, priority: Int) {
        self.id = id
        self.category = category
        self.text = text
        self.priority = priority
    }
}

public struct RunStoryReport: Codable, Equatable, Sendable {
    public var facts: [StoryFact]
    public var summaryLines: [String]
    /// Single paragraph joined from summary lines (shareable).
    public var summary: String

    public static let empty = RunStoryReport(facts: [], summaryLines: [], summary: "")

    public init(facts: [StoryFact], summaryLines: [String], summary: String) {
        self.facts = facts
        self.summaryLines = summaryLines
        self.summary = summary
    }
}

/// Snapshot of receipt fields the story compiler may read. Keeps compilation free of
/// incomplete `RunReceipt` initialization and forbids invented fields.
public struct StoryEvidenceSnapshot: Equatable, Sendable {
    public var seed: UInt64
    public var district: DistrictID
    public var extractionCompleted: Bool
    public var eventSequence: [RecordedRunEvent]
    public var deathsByArchetype: [EntityKind: Int]
    public var selectedUpgrades: [UpgradeChoice]
    public var directorDecisions: [DirectorDecisionSample]
    public var cityStateEvents: [CityStateEventSample]
    public var buildSynergyActivations: [BuildSynergyActivationSample]
    public var buildEngine: BuildEngineState?
    public var coordinationEvents: [CoordinationEventSample]
    public var coordination: CoordinationState?
    public var suspicionTimeline: [SuspicionSample]

    public init(
        seed: UInt64,
        district: DistrictID,
        extractionCompleted: Bool,
        eventSequence: [RecordedRunEvent],
        deathsByArchetype: [EntityKind: Int],
        selectedUpgrades: [UpgradeChoice],
        directorDecisions: [DirectorDecisionSample],
        cityStateEvents: [CityStateEventSample],
        buildSynergyActivations: [BuildSynergyActivationSample],
        buildEngine: BuildEngineState?,
        coordinationEvents: [CoordinationEventSample],
        coordination: CoordinationState?,
        suspicionTimeline: [SuspicionSample]
    ) {
        self.seed = seed
        self.district = district
        self.extractionCompleted = extractionCompleted
        self.eventSequence = eventSequence
        self.deathsByArchetype = deathsByArchetype
        self.selectedUpgrades = selectedUpgrades
        self.directorDecisions = directorDecisions
        self.cityStateEvents = cityStateEvents
        self.buildSynergyActivations = buildSynergyActivations
        self.buildEngine = buildEngine
        self.coordinationEvents = coordinationEvents
        self.coordination = coordination
        self.suspicionTimeline = suspicionTimeline
    }

    public init(receipt: RunReceipt) {
        self.init(
            seed: receipt.seed,
            district: receipt.district,
            extractionCompleted: receipt.extractionCompleted,
            eventSequence: receipt.eventSequence,
            deathsByArchetype: receipt.deathsByArchetype,
            selectedUpgrades: receipt.selectedUpgrades,
            directorDecisions: receipt.directorDecisions,
            cityStateEvents: receipt.cityStateEvents,
            buildSynergyActivations: receipt.buildSynergyActivations,
            buildEngine: receipt.buildEngine,
            coordinationEvents: receipt.coordinationEvents,
            coordination: receipt.coordination,
            suspicionTimeline: receipt.suspicionTimeline
        )
    }
}

/// Compiles authoritative story facts from receipt evidence only.
/// Never invents events, metrics, or narrative not grounded in the snapshot.
public enum RunStoryCompiler: Sendable {
    public static func compile(
        catalog: RunStoryCatalog = .bundled,
        receipt: RunReceipt
    ) -> RunStoryReport {
        compile(catalog: catalog, evidence: StoryEvidenceSnapshot(receipt: receipt))
    }

    public static func compile(
        catalog: RunStoryCatalog = .bundled,
        evidence: StoryEvidenceSnapshot
    ) -> RunStoryReport {
        guard catalog.forbidInventedNarrative else { return .empty }

        let view = StoryEvidenceView(snapshot: evidence)
        var facts: [StoryFact] = []
        for rule in catalog.rules.sorted(by: { $0.priority > $1.priority }) {
            guard let binding = view.match(rule.evidence) else { continue }
            let text = render(
                template: rule.template,
                district: evidence.district,
                seed: evidence.seed,
                binding: binding
            )
            facts.append(
                StoryFact(id: rule.id, category: rule.category, text: text, priority: rule.priority)
            )
        }

        // Stable secondary sort by id for determinism when priorities equal.
        facts.sort {
            if $0.priority != $1.priority { return $0.priority > $1.priority }
            return $0.id < $1.id
        }

        let lines = Array(facts.prefix(catalog.maxSummaryLines).map(\.text))
        let summary = lines.joined(separator: " ")
        return RunStoryReport(facts: facts, summaryLines: lines, summary: summary)
    }

    private static func render(
        template: String,
        district: DistrictID,
        seed: UInt64,
        binding: StoryBinding
    ) -> String {
        var text = template
        text = text.replacingOccurrences(of: "{district}", with: district.cityName)
        text = text.replacingOccurrences(of: "{seed}", with: String(format: "0x%08X", seed))
        if let count = binding.count {
            text = text.replacingOccurrences(of: "{count}", with: "\(count)")
        }
        if let peak = binding.peak {
            text = text.replacingOccurrences(of: "{peak}", with: "\(Int(peak.rounded()))")
        }
        if let list = binding.synergyList {
            text = text.replacingOccurrences(of: "{synergyList}", with: list)
        }
        return text
    }
}

// MARK: - Evidence projection (receipt-only)

private struct StoryBinding: Equatable {
    var count: Int?
    var peak: Double?
    var synergyList: String?
}

private struct StoryEvidenceView {
    let snapshot: StoryEvidenceSnapshot

    func match(_ evidence: StoryFactEvidence) -> StoryBinding? {
        switch evidence.kind {
        case "extractionCompleted":
            guard let expected = evidence.equals, expected == snapshot.extractionCompleted else { return nil }
            return StoryBinding()

        case "playerDefeated":
            // Receipt does not store playerDefeated bool; derive from event sequence only.
            let defeated = snapshot.eventSequence.contains { $0.event.kind == .playerDefeated }
            guard let expected = evidence.equals, expected == defeated else { return nil }
            return StoryBinding()

        case "eventKindPresent":
            guard let raw = evidence.eventKind,
                  let kind = RunEvent.Kind(rawValue: raw),
                  snapshot.eventSequence.contains(where: { $0.event.kind == kind })
            else { return nil }
            return StoryBinding()

        case "minDeaths":
            guard let entityRaw = evidence.entityKind,
                  let entityKind = EntityKind(rawValue: entityRaw),
                  let minimum = evidence.minimum
            else { return nil }
            let count = snapshot.deathsByArchetype[entityKind, default: 0]
            guard Double(count) >= minimum else { return nil }
            return StoryBinding(count: count)

        case "minSelectedUpgrades":
            guard let minimum = evidence.minimum else { return nil }
            let count = snapshot.selectedUpgrades.count
            guard Double(count) >= minimum else { return nil }
            return StoryBinding(count: count)

        case "minBuildSynergies":
            guard let minimum = evidence.minimum else { return nil }
            let ids = snapshot.buildEngine?.activeSynergyIds ?? []
            let fromActivations = Set(snapshot.buildSynergyActivations.map(\.synergyId))
            let combined = Array(Set(ids).union(fromActivations)).sorted()
            guard Double(combined.count) >= minimum else { return nil }
            return StoryBinding(count: combined.count, synergyList: combined.joined(separator: ", "))

        case "minDirectorDecisions":
            guard let minimum = evidence.minimum else { return nil }
            let count = snapshot.directorDecisions.count
            guard Double(count) >= minimum else { return nil }
            return StoryBinding(count: count)

        case "minCityStateEvents":
            guard let minimum = evidence.minimum else { return nil }
            let count = snapshot.cityStateEvents.count
            guard Double(count) >= minimum else { return nil }
            return StoryBinding(count: count)

        case "minCoordinationInterrupted":
            guard let minimum = evidence.minimum else { return nil }
            let effective = max(
                snapshot.coordinationEvents.filter { $0.status == .interrupted }.count,
                snapshot.coordination?.interruptedCount ?? 0
            )
            guard Double(effective) >= minimum else { return nil }
            return StoryBinding(count: effective)

        case "minCoordinationCompleted":
            guard let minimum = evidence.minimum else { return nil }
            let effective = max(
                snapshot.coordinationEvents.filter {
                    $0.status == .completed && $0.reason.contains("chain completed")
                }.count,
                snapshot.coordination?.completedCount ?? 0
            )
            guard Double(effective) >= minimum else { return nil }
            return StoryBinding(count: effective)

        case "minPeakSuspicion":
            guard let minimum = evidence.minimum else { return nil }
            let peak = snapshot.suspicionTimeline.map(\.value).max() ?? 0
            guard peak >= minimum else { return nil }
            return StoryBinding(peak: peak)

        default:
            return nil
        }
    }
}
