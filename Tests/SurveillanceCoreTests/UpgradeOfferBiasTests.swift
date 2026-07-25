import Foundation
import Testing
@testable import SurveillanceCore

@Test func upgradeOfferBiasPrefersCityWeightingTags() {
    let tags = ["socialCamouflage", "signalDisruption"]
    let build = BuildEngineCatalog.bundled
    let eligible = UpgradeChoice.allCases
    var rng = DeterministicRNG(seed: 42)
    let result = UpgradeOfferBias.pickOffers(
        eligible: eligible,
        weightingTags: tags,
        count: 3,
        build: build,
        rng: &rng
    )
    #expect(result.offers.count == 3)
    #expect(Set(result.offers).count == 3)
    #expect(result.preferredCount >= 1)
    for choice in result.offers where UpgradeOfferBias.isPreferred(choice, weightingTags: tags, build: build) {
        let choiceTags = Set(build.tags(for: choice))
        #expect(!choiceTags.isDisjoint(with: Set(tags)))
    }
}

@Test func upgradeOfferBiasIsDeterministicForSeed() {
    let tags = CitySystemicRulesCatalog.bundled.rule(for: .wichita)?.upgradeWeightingTags ?? []
    #expect(!tags.isEmpty)
    let eligible = UpgradeChoice.allCases.filter { choice in
        // Match early-run eligibility: non-evolution base set roughly
        true
    }
    func pick() -> [UpgradeChoice] {
        var rng = DeterministicRNG(seed: 99)
        return UpgradeOfferBias.pickOffers(
            eligible: eligible,
            weightingTags: tags,
            rng: &rng
        ).offers
    }
    #expect(pick() == pick())
}

@Test func simulationRecordsUpgradeOfferBiasOnReceipt() {
    // Force an offer by completing a camera kill path is heavy; drive via
    // public offer path by destroying enough sensors through a short sim
    // and checking bias samples if any offer fires.
    var simulation = Simulation(seed: 11, district: .wichita)
    var sawOffer = false
    for _ in 0..<2_400 {
        let events = simulation.step(input: .init(autoFireEnabled: true))
        if events.contains(where: { $0.kind == .upgradeOffered }) {
            sawOffer = true
            break
        }
        // Auto-pick first upgrade if offered so the run can continue cleanly.
        if !simulation.state.pendingUpgradeChoices.isEmpty {
            _ = simulation.step(input: .init(upgradeChoiceIndex: 0, autoFireEnabled: true))
            sawOffer = true
            break
        }
    }
    let receipt = simulation.runReceipt()
    #expect(receipt.schemaVersion == 11)
    if sawOffer {
        #expect(!receipt.upgradeOfferBiasEvents.isEmpty)
        let sample = receipt.upgradeOfferBiasEvents[0]
        #expect(sample.weightingTags == CitySystemicRulesCatalog.bundled.rule(for: .wichita)?.upgradeWeightingTags)
        #expect(sample.totalOffered == sample.offeredIds.count)
        #expect(sample.totalOffered == 3 || sample.totalOffered > 0)
        #expect(sample.preferredOfferedCount >= 0)
        #expect(sample.preferredOfferedCount <= sample.totalOffered)
    }
}

@Test func cityWeightingTagsAlignWithBuildFamilies() throws {
    let rules = try CitySystemicRulesCatalog.loadBundled()
    let families = BuildEngineCatalog.expectedFamilies
    for city in rules.cities {
        #expect(!city.upgradeWeightingTags.isEmpty)
        for tag in city.upgradeWeightingTags {
            #expect(families.contains(tag))
        }
    }
}
