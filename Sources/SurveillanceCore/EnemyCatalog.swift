import Foundation

public struct EnemyCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let guards: [GuardDefinition]
    public let sensors: [SensorDefinition]

    public static let currentSchemaVersion = 1
    public static let bundled: EnemyCatalog = {
        do { return try loadBundled() }
        catch { preconditionFailure("Invalid bundled enemy catalog: \(error)") }
    }()

    public static func loadBundled() throws -> EnemyCatalog {
        guard let url = contentBundle.url(forResource: "enemies", withExtension: "json", subdirectory: "Content")
            ?? contentBundle.url(forResource: "enemies", withExtension: "json") else { throw EnemyCatalogError.missingResource }
        let catalog = try JSONDecoder().decode(EnemyCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func guardDefinition(_ id: GuardArchetype) -> GuardDefinition {
        guard let definition = guards.first(where: { $0.id == id }) else { preconditionFailure("Missing guard definition: \(id.rawValue)") }
        return definition
    }

    public func sensorDefinition(_ id: SensorArchetype) -> SensorDefinition {
        guard let definition = sensors.first(where: { $0.id == id }) else { preconditionFailure("Missing sensor definition: \(id.rawValue)") }
        return definition
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else { throw EnemyCatalogError.unsupportedSchema(schemaVersion) }
        guard guards.count == GuardArchetype.allCases.count, Set(guards.map(\.id)) == Set(GuardArchetype.allCases), sensors.count == SensorArchetype.allCases.count, Set(sensors.map(\.id)) == Set(SensorArchetype.allCases) else { throw EnemyCatalogError.incompleteCatalog }
        guard Set(guards.map(\.id)).count == guards.count, Set(sensors.map(\.id)).count == sensors.count else { throw EnemyCatalogError.duplicateID }
        guard guards.allSatisfy(\.isValid), sensors.allSatisfy(\.isValid) else { throw EnemyCatalogError.invalidDefinition }
    }
}

public enum GuardMovementStyle: String, Codable, Sendable { case chase, orbit, dormantUntilNearby }
public enum SensorMovementStyle: String, Codable, Sendable { case stationary, orbit, chase }

public struct GuardDefinition: Codable, Equatable, Sendable {
    public let id: GuardArchetype
    public let displayName: String
    public let health: Double
    public let speed: Double
    public let radius: Double
    public let contactDamagePerSecond: Double
    public let movementStyle: GuardMovementStyle
    public let activationRange: Double?

    var isValid: Bool {
        !displayName.isEmpty
            && health > 0
            && speed >= 0
            && radius > 0
            && contactDamagePerSecond >= 0
            && (movementStyle != .dormantUntilNearby || (activationRange ?? 0) > 0)
    }
}

public struct SensorDefinition: Codable, Equatable, Sendable {
    public let id: SensorArchetype
    public let displayName: String
    public let health: Double
    public let radius: Double
    public let scanRange: Double
    public let scanHalfAngle: Double?
    public let rotationSpeed: Double
    public let movementStyle: SensorMovementStyle

    var isValid: Bool { !displayName.isEmpty && health > 0 && radius > 0 && scanRange > 0 && rotationSpeed >= 0 && (scanHalfAngle ?? 0) >= 0 }
}

public enum EnemyCatalogError: Error, Equatable, Sendable { case missingResource, unsupportedSchema(Int), incompleteCatalog, duplicateID, invalidDefinition }
