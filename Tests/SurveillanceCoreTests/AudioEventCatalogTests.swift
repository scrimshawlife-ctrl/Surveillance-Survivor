import Testing
@testable import SurveillanceCore

@Test func bundledAudioEventCatalogLoadsAndValidates() throws {
    let catalog = try AudioEventCatalog.loadBundled()
    #expect(catalog.schemaVersion == AudioEventCatalog.currentSchemaVersion)
    #expect(!catalog.cues.isEmpty)
    #expect(!catalog.adaptiveHooks.isEmpty)
    try catalog.validate()
}

@Test func adaptiveAudioHooksScaleGainBySuspicionTier() throws {
    let catalog = try AudioEventCatalog.loadBundled()
    let low = catalog.adaptiveGain(category: .combat, tier: .backgroundNoise)
    let high = catalog.adaptiveGain(category: .combat, tier: .totalVisibility)
    #expect(high > low)
    #expect(catalog.adaptiveHooks.contains { $0.kind == "zoneMotif" })
}

@Test func audioResolverAppliesAdaptiveGainForSuspicionTier() {
    var lowResolver = AudioCueResolver(catalog: .bundled)
    var highResolver = AudioCueResolver(catalog: .bundled)
    let event = RunEvent(.weaponFired, "kinetic")
    let low = lowResolver.resolve(
        events: [event],
        atTick: 1,
        suspicionTier: .backgroundNoise
    )
    let high = highResolver.resolve(
        events: [event],
        atTick: 1,
        suspicionTier: .totalVisibility
    )
    let lowGain = low.first { $0.cueID.rawValue.contains("weapon") || $0.sourceEvent == .weaponFired }?.gain
        ?? low.first?.gain
    let highGain = high.first { $0.sourceEvent == .weaponFired }?.gain ?? high.first?.gain
    #expect(lowGain != nil && highGain != nil)
    #expect((highGain ?? 0) > (lowGain ?? 0))
}

@Test func landmarkAndDirectorEventsResolveCatalogCues() {
    var resolver = AudioCueResolver(catalog: .bundled)
    let landmark = resolver.resolve(
        events: [RunEvent(.landmarkEncounterChanged, "Landmark: entered")],
        atTick: 10
    )
    #expect(landmark.contains { $0.cueID.rawValue == "landmark_pressure" })
    let director = resolver.resolve(
        events: [RunEvent(.directorDecision, "Director: surge")],
        atTick: 50
    )
    #expect(director.contains { $0.cueID.rawValue == "director_decision" })
}

@Test func audioResolverMapsTierAndExtractionWithCooldown() {
    var resolver = AudioCueResolver(catalog: .bundled)

    let tier = RunEvent(.tierChanged, "tier 2")
    let first = resolver.resolve(events: [tier], atTick: 100)
    #expect(first.contains { $0.cueID.rawValue == "suspicion_tier_up" })

    // Cooldown should suppress the same cue immediately after.
    let second = resolver.resolve(events: [tier], atTick: 105)
    #expect(!second.contains { $0.cueID.rawValue == "suspicion_tier_up" })

    let later = resolver.resolve(events: [tier], atTick: 130)
    #expect(later.contains { $0.cueID.rawValue == "suspicion_tier_up" })

    let extract = resolver.resolve(
        events: [RunEvent(.extractionCompleted, "Extracted through Blind Spot")],
        atTick: 200
    )
    #expect(extract.contains { $0.cueID.rawValue == "extraction_completed" })
    #expect(extract.first?.bus == .music)
}

@Test func audioResolverMatchesCameraPoleDestructionByMessage() {
    var resolver = AudioCueResolver(catalog: .bundled)
    let camera = RunEvent(.entityDestroyed, "cameraPole destroyed")
    let guardDeath = RunEvent(.entityDestroyed, "securityGuard destroyed")

    let cameraCues = resolver.resolve(events: [camera], atTick: 10)
    #expect(cameraCues.contains { $0.cueID.rawValue == "lpr_destroyed" })

    let guardCues = resolver.resolve(events: [guardDeath], atTick: 40)
    #expect(!guardCues.contains { $0.cueID.rawValue == "lpr_destroyed" })
}

@Test func audioResolverOrdersByPriority() {
    var resolver = AudioCueResolver(catalog: .bundled)
    let events = [
        RunEvent(.weaponFired, "kinetic"),
        RunEvent(.playerDefeated, "down")
    ]
    let requests = resolver.resolve(events: events, atTick: 1)
    #expect(!requests.isEmpty)
    #expect(requests.first?.cueID.rawValue == "player_defeated")
}
