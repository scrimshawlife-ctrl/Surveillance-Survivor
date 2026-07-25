import Foundation
import Testing
@testable import SurveillanceCore

@Test func bundledUnlockablesValidate() throws {
    let catalog = try UnlockCatalog.loadBundled()
    #expect(catalog.forbidHiddenStatScaling)
    #expect(!catalog.items.isEmpty)
    try catalog.validate()
    for kind in UnlockCatalog.allowedKinds {
        #expect(catalog.items.contains { $0.kind == kind })
    }
}

@Test func unlockEligibilityUsesMasteryThresholds() {
    let catalog = UnlockCatalog.bundled
    var progress = MasteryProgress.initial
    #expect(catalog.eligible(for: progress).isEmpty || catalog.eligible(for: progress).allSatisfy {
        $0.requiresTotalExtractions == 0
            && $0.requiresChallengeCompletions == 0
            && $0.requiresDailyBestStreak == 0
    })

    // One extraction unlocks the first cosmetic (requiresTotalExtractions: 1).
    progress.totalExtractions = 1
    let afterOne = catalog.eligible(for: progress)
    #expect(afterOne.contains { $0.id == "cosmetic_lot_ghost_trail" })

    progress.totalExtractions = 10
    progress.challengeCompletions = ["quiet_watch": 5]
    progress.dailyBestStreak = 5
    let afterHigh = catalog.eligible(for: progress)
    #expect(afterHigh.count == catalog.items.count)
}

@Test func masteryRecordGrantsUnlocks() {
    var mastery = MasteryProgress.initial
    let entry = RunHistoryEntry(
        finishedAt: "t",
        seed: 1,
        districtId: .wichita,
        extractionCompleted: true,
        elapsedSeconds: 10,
        selectedUpgrades: [],
        challengeKind: "daily",
        challengeContractId: "quiet_watch",
        challengeDayKey: "2026-07-25"
    )
    let granted = mastery.record(entry: entry)
    #expect(mastery.totalExtractions == 1)
    #expect(!mastery.unlockedItemIds.isEmpty)
    #expect(granted.map(\.id) == mastery.lastGrantedUnlockIds)
    #expect(mastery.unlockedItemIds.contains("cosmetic_lot_ghost_trail"))

    // Second record should not re-grant the same cosmetic.
    let again = mastery.record(entry: entry)
    #expect(!again.contains { $0.id == "cosmetic_lot_ghost_trail" })
}
