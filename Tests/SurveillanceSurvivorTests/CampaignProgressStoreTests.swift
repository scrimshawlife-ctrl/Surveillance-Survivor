import Foundation
import Testing
import SurveillanceCore
@testable import SurveillanceSurvivor

@Test func campaignProgressStoreRoundTripsUnlocks() {
    let suiteName = "CampaignProgressStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let store = CampaignProgressStore(defaults: defaults)
    #expect(store.progress.isUnlocked(.wichita))
    #expect(!store.progress.isUnlocked(.louisville))

    let afterWin = store.applyRunOutcome(district: .wichita, extractionCompleted: true)
    #expect(afterWin.isUnlocked(.louisville))
    #expect(afterWin.completedDistricts == [.wichita])

    let reloaded = CampaignProgressStore(defaults: defaults)
    #expect(reloaded.progress.highestUnlockedLevel == 2)
    #expect(reloaded.progress.completedDistricts == [.wichita])
    #expect(reloaded.progress.resolveSelection(.atlanta) == .louisville)
}

@Test func campaignProgressStoreIgnoresDefeatForUnlocks() {
    let suiteName = "CampaignProgressStoreDefeat-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let store = CampaignProgressStore(defaults: defaults)
    _ = store.applyRunOutcome(district: .wichita, extractionCompleted: false)
    #expect(store.progress.highestUnlockedLevel == 1)
    #expect(store.progress.completedDistricts.isEmpty)
    #expect(store.progress.lastPlayedDistrict == .wichita)
}
