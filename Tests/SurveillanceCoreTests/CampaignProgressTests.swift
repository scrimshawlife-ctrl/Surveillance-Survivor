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
