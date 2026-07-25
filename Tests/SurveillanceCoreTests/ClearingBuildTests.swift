import Foundation
import Testing
@testable import SurveillanceCore

@Test func bundledClearingBuildsValidateAndAreDistinct() throws {
    let catalog = try ClearingBuildCatalog.loadBundled()
    #expect(catalog.forbidHiddenStatScaling)
    #expect(catalog.builds.count >= 3)
    #expect(Set(catalog.builds.map(\.strategy)).count == catalog.builds.count)
    try catalog.validate()
}

@Test func clearingBuildsActivateExpectedSynergiesOnly() {
    let catalog = ClearingBuildCatalog.bundled
    for build in catalog.builds {
        let choices = build.requiredUpgrades.compactMap { UpgradeChoice(rawValue: $0) }
        #expect(choices.count == build.requiredUpgrades.count)
        let state = BuildEngine.evaluate(selected: choices)
        for synergy in build.expectedSynergies {
            #expect(state.activeSynergyIds.contains(synergy), "\(build.id) missing \(synergy)")
        }
        for forbidden in build.forbiddenSynergies {
            #expect(!state.activeSynergyIds.contains(forbidden), "\(build.id) has forbidden \(forbidden)")
        }
    }
}

@Test func clearingBuildMatcherMatchesSubsetOfSelectedUpgrades() {
    let catalog = ClearingBuildCatalog.bundled
    let quiet = catalog.build("quiet_ghost")!
    let selected = quiet.requiredUpgrades.compactMap { UpgradeChoice(rawValue: $0) }
    #expect(ClearingBuildMatcher.match(selected: selected)?.id == "quiet_ghost")
    #expect(ClearingBuildMatcher.match(selected: [.precisionDart]) == nil)
}

@Test func receiptReportsMatchedClearingBuildId() {
    let quiet = ClearingBuildCatalog.bundled.build("quiet_ghost")!
    let selected = quiet.requiredUpgrades.compactMap { UpgradeChoice(rawValue: $0) }
    #expect(selected.count == quiet.requiredUpgrades.count)
    let receipt = RunReceipt(
        seed: 55,
        district: .wichita,
        elapsedTicks: 1,
        elapsedSeconds: 1.0 / 60.0,
        suspicionTimeline: [],
        eventSequence: [],
        offeredUpgrades: [],
        selectedUpgrades: selected,
        spawnedEntities: [:],
        deathsByArchetype: [:],
        damageDealt: 0,
        damageTaken: 0,
        bossPhaseDurations: [],
        extractionCompleted: false
    )
    #expect(receipt.schemaVersion == 10)
    #expect(receipt.matchedClearingBuildId == "quiet_ghost")
}
