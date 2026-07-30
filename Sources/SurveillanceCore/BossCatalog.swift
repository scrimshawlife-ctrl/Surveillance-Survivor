import Foundation

public struct BossCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let playerHealth: Double
    public let playerSpeed: Double
    /// How many touching threats can damage the player at once. Contact damage is
    /// continuous, so without a cap a tier-5 crowd stacks every overlapping guard
    /// on the same tick and removes 100 health in under two seconds. Capping keeps
    /// sustained contact lethal while stopping density alone from deleting a run.
    public let maximumSimultaneousContactThreats: Int
    public let shiftManagerHealth: Double
    public let shiftManagerRadius: Double
    public let shiftManagerSpeed: Double
    /// Hard ceiling on a boss's effective speed, as a fraction of the player's.
    ///
    /// Districts escalate `bossSpeedMultiplier` and boss policies multiply it again,
    /// which at the top of the campaign produced authorities faster than the player.
    /// With no healing anywhere and contact damage up to 2x, an authority that cannot
    /// be outrun is not difficult, it is unanswerable. Kiting must stay available as
    /// counterplay; the multipliers still decide how relentless the chase feels.
    public let bossSpeedCeilingFractionOfPlayer: Double
    public let shiftManagerContactDamagePerSecond: Double
    public let shiftManagerSpawnX: Double
    public let blindSpotHealth: Double
    public let blindSpotRadius: Double
    public let blindSpotPositionX: Double

    public static let currentSchemaVersion = 2
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
              maximumSimultaneousContactThreats > 0,
              shiftManagerHealth > 0,
              shiftManagerRadius > 0,
              shiftManagerSpeed > 0,
              bossSpeedCeilingFractionOfPlayer > 0,
              bossSpeedCeilingFractionOfPlayer <= 1,
              shiftManagerContactDamagePerSecond >= 0,
              blindSpotHealth > 0,
              blindSpotRadius > 0 else { throw BossCatalogError.invalidDefinition }
    }
}

public enum BossCatalogError: Error, Equatable, Sendable { case missingResource, unsupportedSchema(Int), invalidDefinition }
