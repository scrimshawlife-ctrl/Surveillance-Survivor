import Foundation

public struct ContentCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let weapons: [WeaponDefinition]

    public static let currentSchemaVersion = 1

    public static let bundled: ContentCatalog = {
        do {
            return try loadBundled()
        } catch {
            preconditionFailure("Invalid bundled content catalog: \(error)")
        }
    }()

    public static func loadBundled() throws -> ContentCatalog {
        let bundle = contentBundle
        // SwiftPM flattens processed resources; Xcode preserves the Content directory.
        guard let url = bundle.url(forResource: "weapons", withExtension: "json", subdirectory: "Content")
            ?? bundle.url(forResource: "weapons", withExtension: "json") else {
            throw ContentCatalogError.missingResource
        }
        let catalog = try JSONDecoder().decode(ContentCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func weapon(_ id: WeaponID) -> WeaponDefinition {
        guard let weapon = weapons.first(where: { $0.id == id }) else {
            preconditionFailure("Missing weapon definition: \(id.rawValue)")
        }
        return weapon
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw ContentCatalogError.unsupportedSchema(schemaVersion)
        }
        guard weapons.count == WeaponID.allCases.count else {
            throw ContentCatalogError.incompleteWeaponCatalog
        }
        guard Set(weapons.map(\.id)).count == weapons.count else {
            throw ContentCatalogError.duplicateWeaponID
        }
        guard Set(weapons.map(\.id)) == Set(WeaponID.allCases) else {
            throw ContentCatalogError.incompleteWeaponCatalog
        }
        guard weapons.allSatisfy({ $0.isValid }) else {
            throw ContentCatalogError.invalidWeaponDefinition
        }
    }
}

public struct WeaponDefinition: Codable, Equatable, Sendable {
    public let id: WeaponID
    public let cadenceTicks: UInt64
    public let range: Double
    public let projectileSpeed: Double
    public let projectileRadius: Double
    public let targetingRule: TargetingRule
    public let payload: PayloadDefinition

    var isValid: Bool {
        cadenceTicks > 0 && range >= 0 && projectileSpeed >= 0 && projectileRadius > 0 && payload.isValid
    }

    func weaponSystem() -> WeaponSystem {
        WeaponSystem(
            id: id,
            cadenceTicks: cadenceTicks,
            range: range,
            projectileSpeed: projectileSpeed,
            projectileRadius: projectileRadius,
            payload: payload.countermeasurePayload,
            targetingRule: targetingRule
        )
    }
}

public struct PayloadDefinition: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case damage
        case disableCameraSensors
        case spoofCameraSensors
        case processing
        case reflect
        case signalFlood
    }

    public let kind: Kind
    public let amount: Double?
    public let durationTicks: UInt64?
    public let suspicionMultiplier: Double?
    public let slowMultiplier: Double?
    public let damagePerTick: Double?
    public let damageMultiplier: Double?
    public let radius: Double?
    public let suspicionSpike: Double?

    var isValid: Bool {
        switch kind {
        case .damage: amount != nil
        case .disableCameraSensors: durationTicks != nil
        case .spoofCameraSensors: durationTicks != nil && suspicionMultiplier != nil
        case .processing: durationTicks != nil && slowMultiplier != nil && damagePerTick != nil
        case .reflect: durationTicks != nil && damageMultiplier != nil
        case .signalFlood: radius != nil && durationTicks != nil && suspicionSpike != nil
        }
    }

    var countermeasurePayload: CountermeasurePayload {
        switch kind {
        case .damage: .damage(amount!)
        case .disableCameraSensors: .disableCameraSensors(durationTicks: durationTicks!)
        case .spoofCameraSensors: .spoofCameraSensors(durationTicks: durationTicks!, suspicionMultiplier: suspicionMultiplier!)
        case .processing: .processing(durationTicks: durationTicks!, slowMultiplier: slowMultiplier!, damagePerTick: damagePerTick!)
        case .reflect: .reflect(durationTicks: durationTicks!, damageMultiplier: damageMultiplier!)
        case .signalFlood: .signalFlood(radius: radius!, durationTicks: durationTicks!, suspicionSpike: suspicionSpike!)
        }
    }
}

public enum ContentCatalogError: Error, Equatable, Sendable {
    case missingResource
    case unsupportedSchema(Int)
    case incompleteWeaponCatalog
    case duplicateWeaponID
    case invalidWeaponDefinition
}

private final class ContentBundleToken {}

private var contentBundle: Bundle {
#if SWIFT_PACKAGE
    Bundle.module
#else
    Bundle(for: ContentBundleToken.self)
#endif
}
