import Foundation

/// P10 — per-city rule-level identity (not textures). Explicit levers and labels only;
/// never damage/HP scaling.
public struct CitySystemicRulesCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let schemaId: String
    public let forbidHiddenStatScaling: Bool
    public let cities: [CitySystemicRule]

    public static let currentSchemaVersion = 1
    public static let expectedSchemaId = "surveillance-survivor/city_systemic_rules"

    public static let allowedProjectionStatus: Set<String> = [
        "rules_only",
        "slice_a_projected",
        "full_p9_proof"
    ]

    public static let bundled: CitySystemicRulesCatalog = {
        do { return try loadBundled() }
        catch { preconditionFailure("Invalid bundled city systemic rules: \(error)") }
    }()

    public static func loadBundled() throws -> CitySystemicRulesCatalog {
        guard let url = contentBundle.url(forResource: "city_systemic_rules", withExtension: "json", subdirectory: "Content")
            ?? contentBundle.url(forResource: "city_systemic_rules", withExtension: "json")
        else { throw CitySystemicRulesError.missingResource }
        let catalog = try JSONDecoder().decode(CitySystemicRulesCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func rule(for district: DistrictID) -> CitySystemicRule? {
        cities.first { $0.districtId == district }
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw CitySystemicRulesError.unsupportedSchema(schemaVersion)
        }
        guard schemaId == Self.expectedSchemaId else {
            throw CitySystemicRulesError.invalidDefinition("schemaId must be \(Self.expectedSchemaId)")
        }
        guard forbidHiddenStatScaling else {
            throw CitySystemicRulesError.invalidDefinition("forbidHiddenStatScaling must be true")
        }
        guard cities.count == DistrictID.allCases.count else {
            throw CitySystemicRulesError.invalidDefinition("must define rules for all \(DistrictID.allCases.count) cities")
        }
        guard Set(cities.map(\.districtId)) == Set(DistrictID.allCases) else {
            throw CitySystemicRulesError.invalidDefinition("city rules must cover every DistrictID exactly once")
        }
        let knownTags = BuildEngineCatalog.expectedFamilies
        for city in cities {
            try city.validate(knownTags: knownTags)
        }
    }
}

public struct CitySystemicRule: Codable, Equatable, Sendable {
    public let districtId: DistrictID
    public let topologyGrammar: String
    public let infrastructureProfile: String
    public let weatherLightingModifier: String
    public let civilianReportingBias: String
    public let enemyFactionWeighting: String
    public let upgradeWeightingTags: [String]
    public let landmarkHookId: String?
    public let radioLanguage: String
    public let audioMotifId: String
    public let satiricalPolicyModifier: String
    public let projectionStatus: String

    func validate(knownTags: Set<String>) throws {
        let required = [
            topologyGrammar, infrastructureProfile, weatherLightingModifier,
            civilianReportingBias, enemyFactionWeighting, radioLanguage,
            audioMotifId, satiricalPolicyModifier, projectionStatus
        ]
        guard required.allSatisfy({ !$0.isEmpty }) else {
            throw CitySystemicRulesError.invalidDefinition("\(districtId.rawValue) missing identity fields")
        }
        guard CitySystemicRulesCatalog.allowedProjectionStatus.contains(projectionStatus) else {
            throw CitySystemicRulesError.invalidDefinition("\(districtId.rawValue) bad projectionStatus")
        }
        guard !upgradeWeightingTags.isEmpty else {
            throw CitySystemicRulesError.invalidDefinition("\(districtId.rawValue) needs upgradeWeightingTags")
        }
        for tag in upgradeWeightingTags where !knownTags.contains(tag) {
            throw CitySystemicRulesError.invalidDefinition(
                "\(districtId.rawValue) unknown upgradeWeightingTag \(tag)"
            )
        }
        if let hook = landmarkHookId, !hook.isEmpty {
            if LandmarkEncounterCatalog.bundled.encounters.first(where: { $0.id == hook }) == nil {
                throw CitySystemicRulesError.invalidDefinition(
                    "\(districtId.rawValue) landmarkHookId \(hook) not in landmark catalog"
                )
            }
        }
        // No hidden damage/HP language in identity strings.
        let banned = ["damageScale", "healthScale", "hiddenDifficulty", "hpScale"]
        let blob = required.joined(separator: " ")
        for ban in banned where blob.localizedCaseInsensitiveContains(ban) {
            throw CitySystemicRulesError.invalidDefinition("\(districtId.rawValue) banned lever language \(ban)")
        }
    }
}

public enum CitySystemicRulesError: Error, Equatable, Sendable {
    case missingResource
    case unsupportedSchema(Int)
    case invalidDefinition(String)
}
