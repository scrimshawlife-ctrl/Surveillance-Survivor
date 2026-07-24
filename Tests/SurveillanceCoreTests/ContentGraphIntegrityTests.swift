import Foundation
import Testing
@testable import SurveillanceCore

@Test func bundledContentGraphHasNoDanglingReferences() {
    let report = ContentGraphValidator.validateBundled()
    #expect(report.isValid, "Content graph issues: \(report.issues.map(\.description).joined(separator: "; "))")
}

@Test func districtCatalogIsExactlyTenCitiesInLevelOrder() {
    let ordered = DistrictCatalog.bundled.districts.sorted { $0.level < $1.level }
    #expect(ordered.count == 10)
    #expect(ordered.map(\.level) == Array(1...10))
    #expect(ordered.map(\.id) == [
        .wichita, .louisville, .tulsa, .dayton, .oakland,
        .sanFrancisco, .columbus, .newYorkCity, .losAngeles, .atlanta
    ])
    #expect(Array(ordered.suffix(3).map(\.id)) == [.newYorkCity, .losAngeles, .atlanta])
}

@Test func everyDistrictSimulationProfileResolvesKnownArchetypes() {
    let enemies = EnemyCatalog.bundled
    let ceiling = WaveCatalog.bundled.guardPopulationCeiling
    for district in DistrictCatalog.bundled.districts {
        let profile = district.simulation
        #expect(profile.guardMaximumTarget <= ceiling)
        for guardID in profile.guardRoster {
            #expect(enemies.guards.contains { $0.id == guardID })
        }
        for sensor in profile.sensorDeploymentOrder {
            #expect(enemies.sensors.contains { $0.id == sensor })
        }
        for placement in profile.startingSensors {
            #expect(enemies.sensors.contains { $0.id == placement.archetype })
            #expect(profile.bounds.contains(placement.position))
        }
        #expect(profile.bounds.contains(profile.playerSpawn))
        #expect(profile.bounds.contains(profile.bossSpawn))
        #expect(profile.bounds.contains(profile.extractionPosition))
    }
}

@Test func upgradeAndEvolutionGraphReferencesExistingWeapons() {
    let weapons = Set(ContentCatalog.bundled.weapons.map(\.id))
    for upgrade in UpgradeCatalog.bundled.upgrades {
        if let weapon = upgrade.weapon {
            #expect(weapons.contains(weapon), "missing weapon for \(upgrade.id.rawValue)")
        }
        if let evolution = upgrade.evolution {
            #expect(evolution.rawValue == upgrade.id.rawValue)
            #expect(upgrade.weapon != nil)
            #expect((upgrade.minimumWeaponLevel ?? 0) >= 1)
        }
    }
}

@Test func audioEventCatalogCuesAreUniqueAndTriggered() {
    var seen = Set<String>()
    for cue in AudioEventCatalog.bundled.cues {
        #expect(seen.insert(cue.id.rawValue).inserted)
        #expect(!cue.assetName.isEmpty)
        #expect(!cue.triggers.isEmpty)
        #expect(cue.isValid)
    }
    #expect(AudioEventCatalog.bundled.cues.count >= 8)
}

@Test func unsupportedWeaponSchemaIsRejected() throws {
    let payload = """
    {"schemaVersion":999,"weapons":[]}
    """.data(using: .utf8)!
    let catalog = try JSONDecoder().decode(ContentCatalog.self, from: payload)
    #expect(throws: ContentCatalogError.unsupportedSchema(999)) {
        try catalog.validate()
    }
}

@Test func malformedUpgradeCatalogFailsValidation() throws {
    let payload = """
    {"schemaVersion":1,"upgrades":[]}
    """.data(using: .utf8)!
    let catalog = try JSONDecoder().decode(UpgradeCatalog.self, from: payload)
    #expect(throws: UpgradeCatalogError.incompleteCatalog) {
        try catalog.validate()
    }
}

@Test func graphValidatorFlagsGuardTargetAboveCeiling() {
    var districts = DistrictCatalog.bundled
    // Mutate a copy via re-encode: build synthetic report using public validate inputs.
    // Use Wichita profile values but force illegal target via local WaveCatalog clone.
    struct LocalWaves {
        // WaveCatalog is a struct with public let fields — decode a patched JSON.
    }
    let waveJSON = """
    {
      "schemaVersion": 2,
      "guardInitialTarget": 1,
      "guardPopulationCeiling": 1,
      "guardGrowthIntervalSeconds": 10,
      "guardSpawnIntervalTicks": 60,
      "guardSpawnRadius": 200,
      "sensorSpawnIntervalTicks": 90,
      "sensorSpawnRadius": 220
    }
    """.data(using: .utf8)!
    let tightWaves = try! JSONDecoder().decode(WaveCatalog.self, from: waveJSON)
    // Districts keep their authored targets which exceed 1.
    let report = ContentGraphValidator.validate(
        districts: districts,
        enemies: .bundled,
        weapons: .bundled,
        upgrades: .bundled,
        waves: tightWaves,
        bosses: .bundled,
        suspicion: .bundled,
        audio: .bundled
    )
    #expect(!report.isValid)
    #expect(report.issues.contains { issue in
        if case .guardTargetExceedsCeiling = issue { return true }
        return false
    })
    _ = districts
}
