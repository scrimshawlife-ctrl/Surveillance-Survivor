import Testing
@testable import SurveillanceCore

@Test func bundledAudioEventCatalogLoadsAndValidates() throws {
    let catalog = try AudioEventCatalog.loadBundled()
    #expect(catalog.schemaVersion == AudioEventCatalog.currentSchemaVersion)
    #expect(!catalog.cues.isEmpty)
    try catalog.validate()
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
