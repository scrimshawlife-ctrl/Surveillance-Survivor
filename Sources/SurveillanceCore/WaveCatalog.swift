import Foundation

public struct WaveCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let guardInitialTarget: Int
    /// Global safety ceiling on live contract security. Districts author their own
    /// target in `DistrictSimulationProfile`; this bounds every district.
    public let guardPopulationCeiling: Int
    public let guardGrowthIntervalSeconds: Double
    public let guardSpawnIntervalTicks: UInt64
    public let guardSpawnRadius: Double
    public let sensorSpawnIntervalTicks: UInt64
    public let sensorSpawnRadius: Double

    public static let currentSchemaVersion = 2
    public static let bundled: WaveCatalog = {
        do { return try loadBundled() }
        catch { preconditionFailure("Invalid bundled wave catalog: \(error)") }
    }()

    public static func loadBundled() throws -> WaveCatalog {
        guard let url = contentBundle.url(forResource: "waves", withExtension: "json", subdirectory: "Content")
            ?? contentBundle.url(forResource: "waves", withExtension: "json") else { throw WaveCatalogError.missingResource }
        let catalog = try JSONDecoder().decode(WaveCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else { throw WaveCatalogError.unsupportedSchema(schemaVersion) }
        guard guardInitialTarget > 0, guardPopulationCeiling >= guardInitialTarget, guardGrowthIntervalSeconds > 0, guardSpawnIntervalTicks > 0, guardSpawnRadius > 0, sensorSpawnIntervalTicks > 0, sensorSpawnRadius > 0 else { throw WaveCatalogError.invalidDefinition }
    }
}

public enum WaveCatalogError: Error, Equatable, Sendable { case missingResource, unsupportedSchema(Int), invalidDefinition }
