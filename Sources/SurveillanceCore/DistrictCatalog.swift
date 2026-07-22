import Foundation

/// Campaign authority extracted from the canonical ten-city roster. This is
/// descriptive content only until districts receive authored simulation rules.
public enum DistrictID: String, CaseIterable, Codable, Equatable, Sendable {
    case wichita
    case louisville
    case tulsa
    case dayton
    case oakland
    case sanFrancisco
    case columbus
    case newYorkCity
    case losAngeles
    case atlanta
}

public struct DistrictCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let districts: [DistrictDefinition]

    public static let currentSchemaVersion = 1
    public static let bundled: DistrictCatalog = {
        do { return try loadBundled() }
        catch { preconditionFailure("Invalid bundled district catalog: \(error)") }
    }()

    public static func loadBundled() throws -> DistrictCatalog {
        guard let url = contentBundle.url(forResource: "districts", withExtension: "json", subdirectory: "Content")
            ?? contentBundle.url(forResource: "districts", withExtension: "json") else {
            throw DistrictCatalogError.missingResource
        }
        let catalog = try JSONDecoder().decode(DistrictCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func district(_ id: DistrictID) -> DistrictDefinition {
        guard let district = districts.first(where: { $0.id == id }) else {
            preconditionFailure("Missing district definition: \(id.rawValue)")
        }
        return district
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else { throw DistrictCatalogError.unsupportedSchema(schemaVersion) }
        guard districts.count == DistrictID.allCases.count, Set(districts.map(\.id)) == Set(DistrictID.allCases) else { throw DistrictCatalogError.incompleteCatalog }
        guard Set(districts.map(\.id)).count == districts.count else { throw DistrictCatalogError.duplicateID }
        guard districts.map(\.level).sorted() == Array(1...DistrictID.allCases.count) else { throw DistrictCatalogError.invalidLevelOrder }
        guard districts.allSatisfy(\.isValid) else { throw DistrictCatalogError.invalidDefinition }
    }
}

public struct DistrictDefinition: Codable, Equatable, Sendable {
    public let id: DistrictID
    public let level: Int
    public let cityName: String
    public let title: String
    public let signatureMechanic: String
    public let standardEnemyNames: [String]
    public let eliteName: String
    public let bossName: String
    public let midBossName: String?
    public let researchQualification: String?

    var isValid: Bool {
        level > 0 && !cityName.isEmpty && !title.isEmpty && !signatureMechanic.isEmpty
            && standardEnemyNames.count >= 5 && standardEnemyNames.allSatisfy { !$0.isEmpty }
            && !eliteName.isEmpty && !bossName.isEmpty
            && (midBossName?.isEmpty != true) && (researchQualification?.isEmpty != true)
    }
}

public enum DistrictCatalogError: Error, Equatable, Sendable {
    case missingResource
    case unsupportedSchema(Int)
    case incompleteCatalog
    case duplicateID
    case invalidLevelOrder
    case invalidDefinition
}
