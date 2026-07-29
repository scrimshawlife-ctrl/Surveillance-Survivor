import Foundation

public struct SuspicionCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let guardPressurePerSecond: Double
    public let sensorContactPressurePerSecond: Double
    public let noContactRecoveryPerSecond: Double
    public let sensorContactEventIntervalTicks: UInt64
    public let tierThresholds: [Double]
    public let cameraRotationBaseMultiplier: Double
    public let cameraRotationTierIncrement: Double
    public let predictivePatrolPressureMultiplier: Double
    /// Suspicion added when the player destroys a camera pole.
    ///
    /// Destroying surveillance infrastructure is the loudest thing the player can
    /// do, and it is also the run objective. Without this the objective starves
    /// its own escalation: clear every camera and suspicion has no source, so the
    /// district authority takes longer to appear. Sized for pacing rather than as the
    /// whole escalation ladder: a district only holds 8-10 poles, so a spike large
    /// enough to reach total visibility on its own ended runs in half a minute.
    /// `surveillanceGridCleared` is what guarantees the authority still comes.
    public let cameraDestroyedSuspicionSpike: Double

    /// How close a guard must be to contribute observation pressure. Guards beyond
    /// this cannot see the player, so their presence is a threat to survival rather
    /// than to concealment.
    public static let guardObservationRange = 340.0

    public static let currentSchemaVersion = 2
    public static let bundled: SuspicionCatalog = {
        do { return try loadBundled() }
        catch { preconditionFailure("Invalid bundled suspicion catalog: \(error)") }
    }()

    public static func loadBundled() throws -> SuspicionCatalog {
        guard let url = contentBundle.url(forResource: "suspicion", withExtension: "json", subdirectory: "Content")
            ?? contentBundle.url(forResource: "suspicion", withExtension: "json") else { throw SuspicionCatalogError.missingResource }
        let catalog = try JSONDecoder().decode(SuspicionCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func tier(for suspicion: Double) -> SuspicionTier {
        let rawValue = tierThresholds.lastIndex(where: { suspicion >= $0 }).map { $0 + 1 } ?? 0
        return SuspicionTier(rawValue: rawValue) ?? .totalVisibility
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else { throw SuspicionCatalogError.unsupportedSchema(schemaVersion) }
        guard guardPressurePerSecond >= 0, sensorContactPressurePerSecond >= 0, noContactRecoveryPerSecond >= 0, sensorContactEventIntervalTicks > 0, tierThresholds.count == 5, zip(tierThresholds, tierThresholds.dropFirst()).allSatisfy({ $0 < $1 }), tierThresholds.allSatisfy({ (0...100).contains($0) }), cameraRotationBaseMultiplier >= 0, cameraRotationTierIncrement >= 0, predictivePatrolPressureMultiplier >= 1, cameraDestroyedSuspicionSpike >= 0 else { throw SuspicionCatalogError.invalidDefinition }
    }
}

public enum SuspicionCatalogError: Error, Equatable, Sendable { case missingResource, unsupportedSchema(Int), invalidDefinition }
