import Foundation

/// Named strategic clearing builds for P9 proof — synergy contracts only, no damage/HP scaling.
public struct ClearingBuildCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let schemaId: String
    public let forbidHiddenStatScaling: Bool
    public let proofDistrictId: DistrictID
    public let builds: [ClearingBuildDefinition]

    public static let currentSchemaVersion = 1
    public static let expectedSchemaId = "surveillance-survivor/clearing_builds"

    public static let bundled: ClearingBuildCatalog = {
        do { return try loadBundled() }
        catch { preconditionFailure("Invalid bundled clearing builds: \(error)") }
    }()

    public static func loadBundled() throws -> ClearingBuildCatalog {
        guard let url = contentBundle.url(forResource: "clearing_builds", withExtension: "json", subdirectory: "Content")
            ?? contentBundle.url(forResource: "clearing_builds", withExtension: "json")
        else { throw ClearingBuildError.missingResource }
        let catalog = try JSONDecoder().decode(ClearingBuildCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func build(_ id: String) -> ClearingBuildDefinition? {
        builds.first { $0.id == id }
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw ClearingBuildError.unsupportedSchema(schemaVersion)
        }
        guard schemaId == Self.expectedSchemaId else {
            throw ClearingBuildError.invalidDefinition("schemaId must be \(Self.expectedSchemaId)")
        }
        guard forbidHiddenStatScaling else {
            throw ClearingBuildError.invalidDefinition("forbidHiddenStatScaling must be true")
        }
        guard builds.count >= 3 else {
            throw ClearingBuildError.invalidDefinition("need ≥3 clearing builds for P9 proof")
        }
        guard Set(builds.map(\.id)).count == builds.count else {
            throw ClearingBuildError.invalidDefinition("duplicate build ids")
        }
        let upgradeIDs = Set(UpgradeChoice.allCases.map(\.rawValue))
        let synergyIDs = Set(BuildEngineCatalog.bundled.synergies.map(\.id))
        for build in builds {
            try build.validate(upgradeIDs: upgradeIDs, synergyIDs: synergyIDs)
            // Live proof: required upgrades produce expected synergies and exclude forbidden ones.
            let choices = build.requiredUpgrades.compactMap { UpgradeChoice(rawValue: $0) }
            guard choices.count == build.requiredUpgrades.count else {
                throw ClearingBuildError.invalidDefinition("\(build.id) unknown upgrade id")
            }
            let state = BuildEngine.evaluate(selected: choices)
            for synergy in build.expectedSynergies where !state.activeSynergyIds.contains(synergy) {
                throw ClearingBuildError.invalidDefinition(
                    "\(build.id) missing expected synergy \(synergy); got \(state.activeSynergyIds)"
                )
            }
            for forbidden in build.forbiddenSynergies where state.activeSynergyIds.contains(forbidden) {
                throw ClearingBuildError.invalidDefinition(
                    "\(build.id) unexpectedly activates forbidden synergy \(forbidden)"
                )
            }
        }
        // Strategies must be pairwise distinct for "three strategically distinct builds".
        guard Set(builds.map(\.strategy)).count == builds.count else {
            throw ClearingBuildError.invalidDefinition("clearing build strategies must be unique")
        }
    }
}

public struct ClearingBuildDefinition: Codable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let strategy: String
    public let requiredUpgrades: [String]
    public let expectedSynergies: [String]
    public let forbiddenSynergies: [String]
    public let readableSummary: String

    func validate(upgradeIDs: Set<String>, synergyIDs: Set<String>) throws {
        guard !id.isEmpty, !displayName.isEmpty, !strategy.isEmpty else {
            throw ClearingBuildError.invalidDefinition("identity fields required")
        }
        guard requiredUpgrades.count >= 2 else {
            throw ClearingBuildError.invalidDefinition("\(id) needs ≥2 required upgrades")
        }
        for upgrade in requiredUpgrades where !upgradeIDs.contains(upgrade) {
            throw ClearingBuildError.invalidDefinition("\(id) unknown upgrade \(upgrade)")
        }
        guard !expectedSynergies.isEmpty else {
            throw ClearingBuildError.invalidDefinition("\(id) needs expectedSynergies")
        }
        for synergy in expectedSynergies + forbiddenSynergies where !synergyIDs.contains(synergy) {
            throw ClearingBuildError.invalidDefinition("\(id) unknown synergy \(synergy)")
        }
        guard !readableSummary.isEmpty else {
            throw ClearingBuildError.invalidDefinition("\(id) readableSummary required")
        }
    }
}

public enum ClearingBuildError: Error, Equatable, Sendable {
    case missingResource
    case unsupportedSchema(Int)
    case invalidDefinition(String)
}

public enum ClearingBuildMatcher: Sendable {
    /// Returns the first clearing build whose required upgrades are a subset of selected.
    public static func match(
        catalog: ClearingBuildCatalog = .bundled,
        selected: [UpgradeChoice]
    ) -> ClearingBuildDefinition? {
        let selectedIDs = Set(selected.map(\.rawValue))
        return catalog.builds.first { build in
            Set(build.requiredUpgrades).isSubset(of: selectedIDs)
        }
    }
}
