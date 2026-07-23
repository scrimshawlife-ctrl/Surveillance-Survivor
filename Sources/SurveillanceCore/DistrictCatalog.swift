import Foundation

/// Campaign authority extracted from the canonical ten-city roster. Each district
/// carries both its descriptive roster entry and the authored simulation profile
/// that drives world generation, spawn rosters, escalation, and boss scaling.
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

    /// The canonical first district, used whenever a run does not name one.
    public static let campaignOpener: DistrictID = .wichita

    public var definition: DistrictDefinition { DistrictCatalog.bundled.district(self) }
    public var profile: DistrictSimulationProfile { definition.simulation }
    public var cityName: String { definition.cityName }
    public var bossName: String { definition.bossName }
}

public struct DistrictCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let districts: [DistrictDefinition]

    public static let currentSchemaVersion = 2
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
        guard districts.allSatisfy({ $0.simulation.isValid }) else { throw DistrictCatalogError.invalidSimulationProfile }
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
    public let simulation: DistrictSimulationProfile

    var isValid: Bool {
        level > 0 && !cityName.isEmpty && !title.isEmpty && !signatureMechanic.isEmpty
            && standardEnemyNames.count >= 5 && standardEnemyNames.allSatisfy { !$0.isEmpty }
            && !eliteName.isEmpty && !bossName.isEmpty
            && (midBossName?.isEmpty != true) && (researchQualification?.isEmpty != true)
    }
}

/// Authored per-district simulation rules. Every value here is content: the
/// simulation reads this profile and never hard-codes district geometry or pacing.
public struct DistrictSimulationProfile: Codable, Equatable, Sendable {
    public let bounds: WorldBounds
    public let playerSpawn: Vector2
    public let obstacles: [ObstacleBlueprint]
    public let startingSensors: [SensorPlacement]
    public let sensorDeploymentOrder: [SensorArchetype]
    public let guardRoster: [GuardArchetype]
    public let guardMaximumTarget: Int
    public let suspicionPressureMultiplier: Double
    public let bossHealthMultiplier: Double
    public let bossSpeedMultiplier: Double
    public let bossContactDamageMultiplier: Double
    public let bossSpawn: Vector2
    public let extractionPosition: Vector2

    var isValid: Bool {
        bounds.minX < bounds.maxX
            && bounds.minY < bounds.maxY
            && bounds.contains(playerSpawn)
            && bounds.contains(bossSpawn)
            && bounds.contains(extractionPosition)
            && obstacles.allSatisfy(\.isValid)
            && !obstacles.contains { $0.contains(playerSpawn) }
            && !startingSensors.isEmpty
            && startingSensors.allSatisfy { bounds.contains($0.position) }
            && !sensorDeploymentOrder.isEmpty
            && Set(sensorDeploymentOrder).count == sensorDeploymentOrder.count
            && !guardRoster.isEmpty
            && Set(guardRoster).count == guardRoster.count
            && guardMaximumTarget > 0
            && suspicionPressureMultiplier > 0
            && bossHealthMultiplier > 0
            && bossSpeedMultiplier > 0
            && bossContactDamageMultiplier >= 0
    }
}

public struct ObstacleBlueprint: Codable, Equatable, Sendable {
    public let center: Vector2
    public let halfSize: Vector2

    var isValid: Bool { halfSize.x > 0 && halfSize.y > 0 }

    func contains(_ point: Vector2) -> Bool {
        abs(point.x - center.x) <= halfSize.x && abs(point.y - center.y) <= halfSize.y
    }
}

public struct SensorPlacement: Codable, Equatable, Sendable {
    public let archetype: SensorArchetype
    public let position: Vector2
    public let heading: Double
}

public enum DistrictCatalogError: Error, Equatable, Sendable {
    case missingResource
    case unsupportedSchema(Int)
    case incompleteCatalog
    case duplicateID
    case invalidLevelOrder
    case invalidDefinition
    case invalidSimulationProfile
}
