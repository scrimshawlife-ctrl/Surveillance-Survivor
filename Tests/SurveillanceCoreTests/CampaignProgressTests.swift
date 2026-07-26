import Foundation
import Testing
@testable import SurveillanceCore

@Test func campaignStartsWithOnlyOpenerUnlocked() {
    let progress = CampaignProgress.initial
    #expect(progress.isUnlocked(.wichita))
    #expect(!progress.isUnlocked(.louisville))
    #expect(!progress.isUnlocked(.atlanta))
    #expect(progress.unlockedDistricts.map(\.id) == [.wichita])
}

@Test func successfulExtractionUnlocksTheNextDistrictInOrder() {
    var progress = CampaignProgress.initial
    progress.recordRunOutcome(district: .wichita, extractionCompleted: true)

    #expect(progress.completedDistricts == [.wichita])
    #expect(progress.isUnlocked(.louisville))
    #expect(!progress.isUnlocked(.tulsa))
    #expect(progress.nextDistrict(after: .wichita) == .louisville)
    #expect(progress.highestUnlockedLevel == 2)
}

@Test func defeatDoesNotUnlockTheNextDistrict() {
    var progress = CampaignProgress.initial
    progress.recordRunOutcome(district: .wichita, extractionCompleted: false)

    #expect(progress.completedDistricts.isEmpty)
    #expect(progress.lastPlayedDistrict == .wichita)
    #expect(!progress.isUnlocked(.louisville))
    #expect(progress.highestUnlockedLevel == 1)
}

@Test func campaignUnlocksAreMonotonicAndCapAtFinale() {
    var progress = CampaignProgress.initial
    for district in CampaignProgress.orderedDistricts.map(\.id) {
        progress.recordRunOutcome(district: district, extractionCompleted: true)
    }

    #expect(progress.highestUnlockedLevel == progress.maxCampaignLevel)
    #expect(DistrictID.allCases.allSatisfy(progress.isUnlocked))
    #expect(progress.nextDistrict(after: .atlanta) == .atlanta)
    #expect(Set(progress.completedDistricts) == Set(DistrictID.allCases))
}

@Test func resolveSelectionNeverReturnsALockedDistrict() {
    var progress = CampaignProgress.initial
    #expect(progress.resolveSelection(.atlanta) == .wichita)

    progress.recordRunOutcome(district: .wichita, extractionCompleted: true)
    #expect(progress.resolveSelection(.atlanta) == .louisville)
    #expect(progress.resolveSelection(.louisville) == .louisville)
}

@Test func repeatedWinsDoNotDuplicateCompletedEntries() {
    var progress = CampaignProgress.initial
    progress.recordRunOutcome(district: .wichita, extractionCompleted: true)
    progress.recordRunOutcome(district: .wichita, extractionCompleted: true)
    #expect(progress.completedDistricts == [.wichita])
    #expect(progress.highestUnlockedLevel == 2)
}

@Test func lockedDistrictExtractionDoesNotSkipCampaignFrontier() {
    var progress = CampaignProgress.initial
    // Concrete daily-challenge path: Los Angeles (level 9) while only Wichita is unlocked.
    progress.recordRunOutcome(district: .losAngeles, extractionCompleted: true)

    #expect(progress.lastPlayedDistrict == .losAngeles)
    #expect(progress.completedDistricts.isEmpty)
    #expect(progress.highestUnlockedLevel == 1)
    #expect(!progress.isUnlocked(.louisville))
    #expect(!progress.isUnlocked(.losAngeles))
    #expect(progress.resolveSelection(.losAngeles) == .wichita)
}

@Test func unlockedReplayDoesNotJumpPastFrontier() {
    var progress = CampaignProgress.initial
    progress.recordRunOutcome(district: .wichita, extractionCompleted: true)
    progress.recordRunOutcome(district: .louisville, extractionCompleted: true)
    // Replaying Wichita after frontier is Louisville+ must not alter unlocks.
    progress.recordRunOutcome(district: .wichita, extractionCompleted: true)

    #expect(progress.highestUnlockedLevel == 3)
    #expect(progress.completedDistricts == [.wichita, .louisville])
    #expect(progress.isUnlocked(.tulsa))
    #expect(!progress.isUnlocked(.columbus))
}

@Test func challengeExtractionOnUnlockedFrontierStillAdvancesCampaign() {
    var progress = CampaignProgress.initial
    // Daily/weekly visits to an already-unlocked city may still clear the frontier.
    progress.recordRunOutcome(district: .wichita, extractionCompleted: true)
    #expect(progress.highestUnlockedLevel == 2)
    #expect(progress.completedDistricts == [.wichita])
}

@Test func dailyChallengeReceiptCannotUnlockWholeCampaign() {
    // 2026-07-26 UTC daily resolves to Los Angeles (level 9).
    let cal = ChallengeResolver.utcCalendar
    let day = cal.date(from: DateComponents(year: 2026, month: 7, day: 26))!
    let daily = ChallengeResolver.daily(for: day)
    #expect(daily.districtId == .losAngeles)

    var progress = CampaignProgress.initial
    progress.recordRunOutcome(district: daily.districtId, extractionCompleted: true)
    #expect(progress.highestUnlockedLevel == 1)
    #expect(progress.completedDistricts.isEmpty)
    #expect(DistrictID.allCases.filter(progress.isUnlocked) == [.wichita])
}
