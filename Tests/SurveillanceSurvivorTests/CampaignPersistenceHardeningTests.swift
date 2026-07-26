import Foundation
import Testing
import SurveillanceCore
@testable import SurveillanceSurvivor

@Test func campaignStoreMigratesLegacyBareProgressPayload() throws {
    let suite = "CampaignLegacy-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }

    var legacy = CampaignProgress.initial
    legacy.recordRunOutcome(district: .wichita, extractionCompleted: true)
    let data = try JSONEncoder().encode(legacy)
    defaults.set(data, forKey: CampaignProgressStore.storageKey)

    let store = CampaignProgressStore(defaults: defaults)
    #expect(store.progress.isUnlocked(.louisville))
    #expect(store.lastLoadDiagnostic == "migrated-legacy-bare-progress")

    // Next save rewrites the versioned envelope.
    _ = store.applyRunOutcome(district: .louisville, extractionCompleted: false)
    let reloaded = CampaignProgressStore(defaults: defaults)
    #expect(reloaded.progress.isUnlocked(.louisville))
    #expect(reloaded.lastLoadDiagnostic == nil || reloaded.lastLoadDiagnostic?.hasPrefix("migrated") == false)
}

@Test func campaignStoreRejectsFutureSchemaWithoutUnlocking() throws {
    let suite = "CampaignFuture-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }

    let future = CampaignProgressRecord(
        schemaVersion: 99,
        progress: CampaignProgress(
            highestUnlockedLevel: 10,
            completedDistricts: DistrictID.allCases,
            lastPlayedDistrict: .atlanta
        )
    )
    let futureData = try JSONEncoder().encode(future)
    defaults.set(futureData, forKey: CampaignProgressStore.storageKey)

    let store = CampaignProgressStore(defaults: defaults)
    #expect(store.progress.highestUnlockedLevel == 1)
    #expect(store.progress.completedDistricts.isEmpty)
    #expect(store.lastLoadDiagnostic == "unsupported-future-schema-99")
    #expect(store.shouldPreserveStoredPayload)

    // Completing a run must not clobber the future-schema envelope (downgrade safety).
    _ = store.applyRunOutcome(district: .wichita, extractionCompleted: true)
    #expect(defaults.data(forKey: CampaignProgressStore.storageKey) == futureData)
    #expect(store.progress.highestUnlockedLevel == 2)
}

@Test func campaignStoreCorruptPayloadFailsClosedToInitial() {
    let suite = "CampaignCorrupt-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }

    defaults.set(Data("not-json{{{".utf8), forKey: CampaignProgressStore.storageKey)
    let store = CampaignProgressStore(defaults: defaults)
    #expect(store.progress == .initial)
    #expect(store.lastLoadDiagnostic == "corrupt-or-unreadable")
}

@Test func campaignStoreIsIdempotentAcrossSessions() {
    let suite = "CampaignIdempotent-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }

    let store = CampaignProgressStore(defaults: defaults)
    _ = store.applyRunOutcome(district: .wichita, extractionCompleted: true)
    _ = store.applyRunOutcome(district: .wichita, extractionCompleted: true)
    #expect(store.progress.completedDistricts == [.wichita])
    #expect(store.progress.highestUnlockedLevel == 2)

    let again = CampaignProgressStore(defaults: defaults)
    #expect(again.progress.completedDistricts == [.wichita])
    #expect(again.progress.highestUnlockedLevel == 2)
    #expect(again.progress.resolveSelection(.atlanta) == .louisville)
}

@Test func outOfOrderCompletionDoesNotSkipUnlockFrontier() {
    var progress = CampaignProgress.initial
    // Locked-city outcomes (daily/weekly challenges) must not raise the frontier.
    progress.recordRunOutcome(district: .louisville, extractionCompleted: true)
    #expect(progress.lastPlayedDistrict == .louisville)
    #expect(progress.completedDistricts.isEmpty)
    #expect(progress.highestUnlockedLevel == 1)
    #expect(!progress.isUnlocked(.louisville))
    #expect(!progress.isUnlocked(.tulsa))

    // Late-game challenge city must not unlock the full campaign in one extraction.
    progress.recordRunOutcome(district: .losAngeles, extractionCompleted: true)
    #expect(progress.highestUnlockedLevel == 1)
    #expect(progress.completedDistricts.isEmpty)
    #expect(!progress.isUnlocked(.losAngeles))
}

@Test func finaleCompletionDoesNotOverflowRoster() {
    var progress = CampaignProgress.initial
    for district in CampaignProgress.orderedDistricts.map(\.id) {
        progress.recordRunOutcome(district: district, extractionCompleted: true)
    }
    progress.recordRunOutcome(district: .atlanta, extractionCompleted: true)
    #expect(progress.highestUnlockedLevel == progress.maxCampaignLevel)
    #expect(progress.nextDistrict(after: .atlanta) == .atlanta)
}

@Test func campaignSanitizeRepairsImpossibleUnlockFrontier() {
    let corrupt = CampaignProgress(
        highestUnlockedLevel: 10,
        completedDistricts: [],
        lastPlayedDistrict: .atlanta
    ).sanitized()
    #expect(corrupt.highestUnlockedLevel == 1)
    #expect(corrupt.completedDistricts.isEmpty)

    let skipAhead = CampaignProgress(
        highestUnlockedLevel: 5,
        completedDistricts: [.wichita, .tulsa], // missing Louisville (level 2)
        lastPlayedDistrict: .tulsa
    ).sanitized()
    #expect(skipAhead.completedDistricts == [.wichita])
    #expect(skipAhead.highestUnlockedLevel == 2)
}
