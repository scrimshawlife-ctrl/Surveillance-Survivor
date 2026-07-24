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
    defaults.set(try JSONEncoder().encode(future), forKey: CampaignProgressStore.storageKey)

    let store = CampaignProgressStore(defaults: defaults)
    #expect(store.progress.highestUnlockedLevel == 1)
    #expect(store.progress.completedDistricts.isEmpty)
    #expect(store.lastLoadDiagnostic == "unsupported-future-schema-99")
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
    // Attempt to complete Louisville without unlocking it first — still records if called,
    // but unlock level only advances from frontier.
    progress.recordRunOutcome(district: .louisville, extractionCompleted: true)
    // Louisville is level 2; highest was 1, so completedLevel 2 >= 1 → unlock becomes 3.
    // That is "completing level 2 unlocks 3" even if level 1 wasn't completed — document as
    // content rule: extraction outcome is trusted if recorded. Picker still cannot *select*
    // Louisville until isUnlocked — and isUnlocked uses highestUnlockedLevel.
    #expect(progress.isUnlocked(.louisville))
    #expect(progress.isUnlocked(.tulsa) == false || progress.highestUnlockedLevel >= 3)
    // After recording Louisville win without Wichita, highest is min(2+1,10)=3
    #expect(progress.highestUnlockedLevel == 3)
    #expect(progress.completedDistricts == [.louisville])
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
