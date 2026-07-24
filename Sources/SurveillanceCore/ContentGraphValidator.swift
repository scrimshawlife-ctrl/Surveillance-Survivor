import Foundation

/// Cross-catalog referential integrity. Runs at initialization/test time only —
/// never from the fixed-step path.
public enum ContentGraphValidator: Sendable {
    public enum Issue: Error, Equatable, Sendable, CustomStringConvertible {
        case districtOrderMismatch([String])
        case finalTrilogyMismatch(expected: [String], found: [String])
        case guardTargetExceedsCeiling(district: String, target: Int, ceiling: Int)
        case unknownGuardInRoster(district: String, archetype: String)
        case unknownSensorInRoster(district: String, archetype: String)
        case unknownSensorPlacement(district: String, archetype: String)
        case upgradeWeaponMissing(upgrade: String, weapon: String)
        case evolutionWeaponMissing(upgrade: String, weapon: String)
        case evolutionIdMismatch(upgrade: String, evolution: String)
        case audioCueDuplicate(String)
        case audioCueEmptyAsset(String)
        case audioCueEmptyTriggers(String)
        case suspicionTierCount(Int)
        case bossValuesNonPositive

        public var description: String {
            switch self {
            case .districtOrderMismatch(let ids):
                "District order mismatch: \(ids.joined(separator: ","))"
            case .finalTrilogyMismatch(let expected, let found):
                "Final trilogy expected \(expected) found \(found)"
            case .guardTargetExceedsCeiling(let district, let target, let ceiling):
                "District \(district) guardMaximumTarget \(target) exceeds wave ceiling \(ceiling)"
            case .unknownGuardInRoster(let district, let archetype):
                "District \(district) references unknown guard \(archetype)"
            case .unknownSensorInRoster(let district, let archetype):
                "District \(district) references unknown sensor \(archetype)"
            case .unknownSensorPlacement(let district, let archetype):
                "District \(district) starting sensor unknown archetype \(archetype)"
            case .upgradeWeaponMissing(let upgrade, let weapon):
                "Upgrade \(upgrade) references missing weapon \(weapon)"
            case .evolutionWeaponMissing(let upgrade, let weapon):
                "Evolution \(upgrade) requires missing weapon \(weapon)"
            case .evolutionIdMismatch(let upgrade, let evolution):
                "Evolution upgrade \(upgrade) id does not match evolution \(evolution)"
            case .audioCueDuplicate(let id):
                "Duplicate audio cue id \(id)"
            case .audioCueEmptyAsset(let id):
                "Audio cue \(id) has empty asset name"
            case .audioCueEmptyTriggers(let id):
                "Audio cue \(id) has no triggers"
            case .suspicionTierCount(let count):
                "Expected 6 suspicion tier thresholds, found \(count)"
            case .bossValuesNonPositive:
                "Boss catalog contains non-positive gameplay scalars"
            }
        }
    }

    public struct Report: Equatable, Sendable {
        public let issues: [Issue]
        public var isValid: Bool { issues.isEmpty }
    }

    /// Validate the live bundled catalogs as a single graph.
    public static func validateBundled() -> Report {
        validate(
            districts: .bundled,
            enemies: .bundled,
            weapons: .bundled,
            upgrades: .bundled,
            waves: .bundled,
            bosses: .bundled,
            suspicion: .bundled,
            audio: .bundled
        )
    }

    public static func validate(
        districts: DistrictCatalog,
        enemies: EnemyCatalog,
        weapons: ContentCatalog,
        upgrades: UpgradeCatalog,
        waves: WaveCatalog,
        bosses: BossCatalog,
        suspicion: SuspicionCatalog,
        audio: AudioEventCatalog
    ) -> Report {
        var issues: [Issue] = []

        let ordered = districts.districts.sorted { $0.level < $1.level }
        let orderedIDs = ordered.map(\.id.rawValue)
        let expectedOrder = DistrictID.allCases
            .map { ($0, $0.definition.level) }
            .sorted { $0.1 < $1.1 }
            .map(\.0.rawValue)
        // Prefer catalog levels over enum declaration order.
        let canonicalByLevel = DistrictID.allCases.sorted { $0.definition.level < $1.definition.level }.map(\.rawValue)
        if orderedIDs != canonicalByLevel {
            issues.append(.districtOrderMismatch(orderedIDs))
        }

        let trilogy = Array(ordered.suffix(3).map(\.id.rawValue))
        let expectedTrilogy = ["newYorkCity", "losAngeles", "atlanta"]
        if trilogy != expectedTrilogy {
            issues.append(.finalTrilogyMismatch(expected: expectedTrilogy, found: trilogy))
        }

        let knownGuards = Set(enemies.guards.map(\.id))
        let knownSensors = Set(enemies.sensors.map(\.id))
        let knownWeapons = Set(weapons.weapons.map(\.id))
        let ceiling = waves.guardPopulationCeiling

        for district in districts.districts {
            let profile = district.simulation
            if profile.guardMaximumTarget > ceiling {
                issues.append(
                    .guardTargetExceedsCeiling(
                        district: district.id.rawValue,
                        target: profile.guardMaximumTarget,
                        ceiling: ceiling
                    )
                )
            }
            for guardID in profile.guardRoster where !knownGuards.contains(guardID) {
                issues.append(.unknownGuardInRoster(district: district.id.rawValue, archetype: guardID.rawValue))
            }
            for sensor in profile.sensorDeploymentOrder where !knownSensors.contains(sensor) {
                issues.append(.unknownSensorInRoster(district: district.id.rawValue, archetype: sensor.rawValue))
            }
            for placement in profile.startingSensors where !knownSensors.contains(placement.archetype) {
                issues.append(
                    .unknownSensorPlacement(
                        district: district.id.rawValue,
                        archetype: placement.archetype.rawValue
                    )
                )
            }
        }

        for upgrade in upgrades.upgrades {
            if let weapon = upgrade.weapon, !knownWeapons.contains(weapon) {
                issues.append(.upgradeWeaponMissing(upgrade: upgrade.id.rawValue, weapon: weapon.rawValue))
            }
            if let evolution = upgrade.evolution {
                if evolution.rawValue != upgrade.id.rawValue {
                    issues.append(
                        .evolutionIdMismatch(upgrade: upgrade.id.rawValue, evolution: evolution.rawValue)
                    )
                }
                if let weapon = upgrade.weapon, !knownWeapons.contains(weapon) {
                    issues.append(
                        .evolutionWeaponMissing(upgrade: upgrade.id.rawValue, weapon: weapon.rawValue)
                    )
                }
            }
        }

        var seenCues = Set<String>()
        for cue in audio.cues {
            if !seenCues.insert(cue.id.rawValue).inserted {
                issues.append(.audioCueDuplicate(cue.id.rawValue))
            }
            if cue.assetName.isEmpty {
                issues.append(.audioCueEmptyAsset(cue.id.rawValue))
            }
            if cue.triggers.isEmpty {
                issues.append(.audioCueEmptyTriggers(cue.id.rawValue))
            }
        }

        // Five thresholds separate tiers 0…5 (background through total visibility).
        if suspicion.tierThresholds.count != 5 {
            issues.append(.suspicionTierCount(suspicion.tierThresholds.count))
        }

        if bosses.playerHealth <= 0
            || bosses.shiftManagerHealth <= 0
            || bosses.shiftManagerRadius <= 0
            || bosses.shiftManagerSpeed < 0
            || bosses.blindSpotHealth <= 0
            || bosses.blindSpotRadius <= 0 {
            issues.append(.bossValuesNonPositive)
        }

        // Silence unused if enums change — weapons catalog already self-validates completeness.
        _ = expectedOrder

        return Report(issues: issues)
    }
}
