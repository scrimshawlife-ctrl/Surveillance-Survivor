import Foundation
import Testing
@testable import SurveillanceCore

@Test func unlockPresentationEmptyWithoutUnlocks() {
    let profile = UnlockPresentationResolver.resolve(unlockedItemIds: [])
    #expect(profile == .empty)
    #expect(!profile.hasAnyPresentation)
}

@Test func unlockPresentationResolvesCosmeticsAndRadio() {
    let profile = UnlockPresentationResolver.resolve(
        unlockedItemIds: [
            "cosmetic_lot_ghost_trail",
            "cosmetic_redaction_vignette",
            "radio_set_prairie_dispatch"
        ]
    )
    #expect(profile.showsLotGhostTrail)
    #expect(profile.showsRedactionVignette)
    #expect(profile.radioLanguage == "zoning_corridor_dispatch")
    #expect(profile.weatherLightingModifier == nil)
}

@Test func unlockPresentationPrefersHigherTierRadioSet() {
    let profile = UnlockPresentationResolver.resolve(
        unlockedItemIds: [
            "radio_set_prairie_dispatch",
            "radio_set_multi_agency"
        ]
    )
    #expect(profile.radioLanguage == "multi_agency_handoff")
}

@Test func unlockPresentationFromMasteryProgress() {
    var mastery = MasteryProgress.initial
    mastery.totalExtractions = 10
    mastery.challengeCompletions = ["quiet_watch": 5]
    mastery.dailyBestStreak = 5
    _ = mastery.grantUnlocks()
    let profile = UnlockPresentationResolver.resolve(progress: mastery)
    #expect(profile.hasAnyPresentation)
    #expect(profile.audioMotifId == "tulsa_pipeline_pulse")
    #expect(profile.weatherLightingModifier == "marine_layer_soft_edges")
}
