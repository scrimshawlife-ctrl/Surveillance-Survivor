import Foundation

public struct BossCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let playerHealth: Double
    public let playerSpeed: Double
    public let shiftManagerHealth: Double
    public let shiftManagerRadius: Double
    public let shiftManagerSpeed: Double
    public let shiftManagerContactDamagePerSecond: Double
    public let shiftManagerSpawnX: Double
    public let blindSpotHealth: Double
    public let blindSpotRadius: Double
    public let blindSpotPositionX: Double

    public static let currentSchemaVersion = 1
    public static let bundled: BossCatalog = { do { return try loadBundled() } catch { preconditionFailure("Invalid bundled boss catalog: \(error)") } }()

    public static func loadBundled() throws -> BossCatalog {
        guard let url = contentBundle.url(forResource: "bosses", withExtension: "json", subdirectory: "Content") ?? contentBundle.url(forResource: "bosses", withExtension: "json") else { throw BossCatalogError.missingResource }
        let catalog = try JSONDecoder().decode(BossCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else { throw BossCatalogError.unsupportedSchema(schemaVersion) }
        guard playerHealth > 0,
              playerSpeed > 0,
              shiftManagerHealth > 0,
              shiftManagerRadius > 0,
              shiftManagerSpeed > 0,
              shiftManagerContactDamagePerSecond >= 0,
              blindSpotHealth > 0,
              blindSpotRadius > 0 else { throw BossCatalogError.invalidDefinition }
    }
}

public enum BossCatalogError: Error, Equatable, Sendable { case missingResource, unsupportedSchema(Int), invalidDefinition }
