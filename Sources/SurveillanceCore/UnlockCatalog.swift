import Foundation

/// P11 unlockables: cosmetics, radio sets, weather packs, audio motifs.
/// Gates use mastery metrics only — never permanent damage/HP inflation.
public struct UnlockCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let schemaId: String
    public let forbidHiddenStatScaling: Bool
    public let items: [UnlockableItem]

    public static let currentSchemaVersion = 1
    public static let expectedSchemaId = "surveillance-survivor/unlockables"

    public static let allowedKinds: Set<String> = [
        "cosmetic",
        "radioSet",
        "weatherPack",
        "audioMotif"
    ]

    public static let bundled: UnlockCatalog = {
        do { return try loadBundled() }
        catch { preconditionFailure("Invalid bundled unlockables: \(error)") }
    }()

    public static func loadBundled() throws -> UnlockCatalog {
        guard let url = contentBundle.url(forResource: "unlockables", withExtension: "json", subdirectory: "Content")
            ?? contentBundle.url(forResource: "unlockables", withExtension: "json")
        else { throw UnlockCatalogError.missingResource }
        let catalog = try JSONDecoder().decode(UnlockCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func item(id: String) -> UnlockableItem? {
        items.first { $0.id == id }
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw UnlockCatalogError.unsupportedSchema(schemaVersion)
        }
        guard schemaId == Self.expectedSchemaId else {
            throw UnlockCatalogError.invalidDefinition("schemaId must be \(Self.expectedSchemaId)")
        }
        guard forbidHiddenStatScaling else {
            throw UnlockCatalogError.invalidDefinition("forbidHiddenStatScaling must be true")
        }
        guard !items.isEmpty else {
            throw UnlockCatalogError.invalidDefinition("items must be non-empty")
        }
        guard Set(items.map(\.id)).count == items.count else {
            throw UnlockCatalogError.invalidDefinition("duplicate unlockable ids")
        }
        for item in items {
            try item.validate()
        }
    }

    /// Items whose mastery thresholds are met by `progress`.
    public func eligible(for progress: MasteryProgress) -> [UnlockableItem] {
        items.filter { $0.isUnlocked(by: progress) }
    }

    /// IDs newly eligible that are not yet in `progress.unlockedItemIds`.
    public func newlyEarned(by progress: MasteryProgress) -> [UnlockableItem] {
        let owned = Set(progress.unlockedItemIds)
        return eligible(for: progress).filter { !owned.contains($0.id) }
    }
}

public struct UnlockableItem: Codable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let kind: String
    public let requiresTotalExtractions: Int
    public let requiresChallengeCompletions: Int
    public let requiresDailyBestStreak: Int
    public let presentationId: String?
    public let radioLanguage: String?
    public let weatherLightingModifier: String?
    public let audioMotifId: String?
    public let opportunity: String
    public let cost: String

    public init(
        id: String,
        displayName: String,
        kind: String,
        requiresTotalExtractions: Int = 0,
        requiresChallengeCompletions: Int = 0,
        requiresDailyBestStreak: Int = 0,
        presentationId: String? = nil,
        radioLanguage: String? = nil,
        weatherLightingModifier: String? = nil,
        audioMotifId: String? = nil,
        opportunity: String,
        cost: String
    ) {
        self.id = id
        self.displayName = displayName
        self.kind = kind
        self.requiresTotalExtractions = requiresTotalExtractions
        self.requiresChallengeCompletions = requiresChallengeCompletions
        self.requiresDailyBestStreak = requiresDailyBestStreak
        self.presentationId = presentationId
        self.radioLanguage = radioLanguage
        self.weatherLightingModifier = weatherLightingModifier
        self.audioMotifId = audioMotifId
        self.opportunity = opportunity
        self.cost = cost
    }

    public func isUnlocked(by progress: MasteryProgress) -> Bool {
        let challengeTotal = progress.challengeCompletions.values.reduce(0, +)
        return progress.totalExtractions >= requiresTotalExtractions
            && challengeTotal >= requiresChallengeCompletions
            && progress.dailyBestStreak >= requiresDailyBestStreak
    }

    func validate() throws {
        guard !id.isEmpty, !displayName.isEmpty else {
            throw UnlockCatalogError.invalidDefinition("unlockable needs id and displayName")
        }
        guard UnlockCatalog.allowedKinds.contains(kind) else {
            throw UnlockCatalogError.invalidDefinition("\(id) unknown kind \(kind)")
        }
        guard requiresTotalExtractions >= 0,
              requiresChallengeCompletions >= 0,
              requiresDailyBestStreak >= 0 else {
            throw UnlockCatalogError.invalidDefinition("\(id) thresholds must be ≥0")
        }
        guard !opportunity.isEmpty, !cost.isEmpty else {
            throw UnlockCatalogError.invalidDefinition("\(id) needs opportunity and cost")
        }
        switch kind {
        case "cosmetic":
            guard let presentationId, !presentationId.isEmpty else {
                throw UnlockCatalogError.invalidDefinition("\(id) cosmetic needs presentationId")
            }
        case "radioSet":
            guard let radioLanguage, !radioLanguage.isEmpty else {
                throw UnlockCatalogError.invalidDefinition("\(id) radioSet needs radioLanguage")
            }
        case "weatherPack":
            guard let weatherLightingModifier, !weatherLightingModifier.isEmpty else {
                throw UnlockCatalogError.invalidDefinition("\(id) weatherPack needs weatherLightingModifier")
            }
        case "audioMotif":
            guard let audioMotifId, !audioMotifId.isEmpty else {
                throw UnlockCatalogError.invalidDefinition("\(id) audioMotif needs audioMotifId")
            }
        default:
            break
        }
        let banned = ["damageScale", "healthScale", "hiddenDifficulty", "playerDamage", "enemyHealth"]
        let blob = [opportunity, cost, presentationId, radioLanguage, weatherLightingModifier, audioMotifId]
            .compactMap { $0 }
            .joined(separator: " ")
        for ban in banned where blob.localizedCaseInsensitiveContains(ban) {
            throw UnlockCatalogError.invalidDefinition("\(id) banned lever language \(ban)")
        }
    }
}

public enum UnlockCatalogError: Error, Equatable, Sendable {
    case missingResource
    case unsupportedSchema(Int)
    case invalidDefinition(String)
}
