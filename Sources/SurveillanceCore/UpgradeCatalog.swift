import Foundation

public struct UpgradeCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    /// Minimum gameplay ticks between draft screens. Cameras cluster spatially, so
    /// destroying them clustered the drafts too: measured offers in Dayton landed at
    /// 1s, 3s, 7s and 9s — four full-screen modals in the opening nine seconds, before
    /// the player had oriented. Offers are deferred by this interval, never dropped.
    public let minimumDraftIntervalTicks: UInt64
    public let upgrades: [UpgradeDefinition]

    public static let currentSchemaVersion = 2

    public static let bundled: UpgradeCatalog = {
        do { return try loadBundled() }
        catch { preconditionFailure("Invalid bundled upgrade catalog: \(error)") }
    }()

    public static func loadBundled() throws -> UpgradeCatalog {
        guard let url = contentBundle.url(forResource: "upgrades", withExtension: "json", subdirectory: "Content")
            ?? contentBundle.url(forResource: "upgrades", withExtension: "json") else {
            throw UpgradeCatalogError.missingResource
        }
        let catalog = try JSONDecoder().decode(UpgradeCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func upgrade(_ id: UpgradeChoice) -> UpgradeDefinition {
        guard let upgrade = upgrades.first(where: { $0.id == id }) else {
            preconditionFailure("Missing upgrade definition: \(id.rawValue)")
        }
        return upgrade
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else { throw UpgradeCatalogError.unsupportedSchema(schemaVersion) }
        guard minimumDraftIntervalTicks > 0,
              upgrades.count == UpgradeChoice.allCases.count,
              Set(upgrades.map(\.id)) == Set(UpgradeChoice.allCases) else { throw UpgradeCatalogError.incompleteCatalog }
        guard Set(upgrades.map(\.id)).count == upgrades.count else { throw UpgradeCatalogError.duplicateUpgradeID }
        guard upgrades.allSatisfy(\.isValid) else { throw UpgradeCatalogError.invalidDefinition }
    }
}

public struct UpgradeDefinition: Codable, Equatable, Sendable {
    public let id: UpgradeChoice
    public let weapon: WeaponID?
    public let addsWeapon: Bool
    public let evolution: WeaponEvolution?
    public let minimumWeaponLevel: Int?
    public let effect: UpgradeEffect

    var isValid: Bool {
        if addsWeapon && weapon == nil { return false }
        if let evolution {
            guard weapon != nil, (minimumWeaponLevel ?? 0) >= 1, evolution.rawValue == id.rawValue else { return false }
        } else if minimumWeaponLevel != nil {
            return false
        }
        return effect.isValid
    }
}

public struct UpgradeEffect: Codable, Equatable, Sendable {
    public let cadenceReduction: UInt64?
    public let minimumCadence: UInt64?
    public let damageIncrease: Double?
    public let projectileSpeedIncrease: Double?
    public let disableDurationIncrease: UInt64?
    public let spoofDurationIncrease: UInt64?
    public let suspicionMultiplierReduction: Double?
    public let minimumSuspicionMultiplier: Double?
    public let suspicionMultiplierSet: Double?
    public let processingDurationIncrease: UInt64?
    public let slowMultiplierReduction: Double?
    public let minimumSlowMultiplier: Double?
    public let slowMultiplierSet: Double?
    public let processingDamageIncrease: Double?
    public let projectileRadiusIncrease: Double?
    public let suspicionReduction: Double?
    /// Integrity restored immediately on selection, clamped to the authored maximum.
    public let integrityRestore: Double?
    /// Integrity recovered per second while no sensor has contact. Explicit, authored,
    /// and player-chosen — the opposite of the hidden difficulty scaling the build
    /// engine forbids.
    public let integrityRegenPerSecond: Double?

    var isValid: Bool {
        let hasAppliedField = cadenceReduction != nil
            || minimumCadence != nil
            || damageIncrease != nil
            || projectileSpeedIncrease != nil
            || disableDurationIncrease != nil
            || spoofDurationIncrease != nil
            || suspicionMultiplierReduction != nil
            || minimumSuspicionMultiplier != nil
            || suspicionMultiplierSet != nil
            || processingDurationIncrease != nil
            || slowMultiplierReduction != nil
            || minimumSlowMultiplier != nil
            || slowMultiplierSet != nil
            || processingDamageIncrease != nil
            || projectileRadiusIncrease != nil
            || suspicionReduction != nil
            || integrityRestore != nil
            || integrityRegenPerSecond != nil
        guard hasAppliedField else { return false }
        return cadenceReduction.map { $0 > 0 } ?? true
            && minimumCadence.map { $0 > 0 } ?? true
            && damageIncrease.map { $0 > 0 } ?? true
            && projectileSpeedIncrease.map { $0 > 0 } ?? true
            && disableDurationIncrease.map { $0 > 0 } ?? true
            && spoofDurationIncrease.map { $0 > 0 } ?? true
            && suspicionMultiplierReduction.map { $0 > 0 } ?? true
            && minimumSuspicionMultiplier.map { (0...1).contains($0) } ?? true
            && suspicionMultiplierSet.map { (0...1).contains($0) } ?? true
            && processingDurationIncrease.map { $0 > 0 } ?? true
            && slowMultiplierReduction.map { $0 > 0 } ?? true
            && minimumSlowMultiplier.map { (0...1).contains($0) } ?? true
            && slowMultiplierSet.map { (0...1).contains($0) } ?? true
            && processingDamageIncrease.map { $0 > 0 } ?? true
            && projectileRadiusIncrease.map { $0 > 0 } ?? true
            && suspicionReduction.map { $0 > 0 } ?? true
            && integrityRestore.map { $0 > 0 } ?? true
            && integrityRegenPerSecond.map { $0 > 0 } ?? true
    }
}

public enum UpgradeCatalogError: Error, Equatable, Sendable {
    case missingResource
    case unsupportedSchema(Int)
    case incompleteCatalog
    case duplicateUpgradeID
    case invalidDefinition
}
