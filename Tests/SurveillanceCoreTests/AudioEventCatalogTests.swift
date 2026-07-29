import Foundation
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

@Test func adaptiveAudioHookRejectsNegativeGainDomains() throws {
    let payload = """
    {
      "schemaVersion": 2,
      "schemaId": "surveillance-survivor/audio_events",
      "adaptiveHooks": [
        {
          "id": "bad_gain",
          "kind": "gainScaleBySuspicionTier",
          "note": "test",
          "stemStatus": "runtime",
          "appliesToCategories": ["combat"],
          "gainByTier": { "0": -1 }
        }
      ],
      "cues": [
        {
          "id": "weapon_fire",
          "assetName": "sfx_weapon_fire",
          "category": "combat",
          "bus": "sfx",
          "priority": 1,
          "gain": 1,
          "cooldownTicks": 0,
          "triggers": [{ "kind": "weaponFired" }]
        }
      ]
    }
    """.data(using: .utf8)!
    let catalog = try JSONDecoder().decode(AudioEventCatalog.self, from: payload)
    #expect(throws: AudioEventCatalogError.invalidDefinition) {
        try catalog.validate()
    }
}

// MARK: - Runtime integration of looping city audio

@Test func bundledCatalogAuthorsASceneForEveryDistrict() throws {
    let catalog = try AudioEventCatalog.loadBundled()
    guard let scenes = catalog.scenes else {
        Issue.record("Bundled catalog must author looping scenes")
        return
    }
    #expect(scenes.districts.count == DistrictID.allCases.count)
    for district in DistrictID.allCases {
        guard let definition = scenes.definition(for: district) else {
            Issue.record("Missing scene for \(district.rawValue)")
            continue
        }
        #expect(definition.isValid)
    }
}

@Test func sceneProjectsCityBedAndRunLoopOutsideBossFights() throws {
    let catalog = try AudioEventCatalog.loadBundled()
    let scenes = try #require(catalog.scenes)
    let state = RunState(seed: 5, district: .tulsa)
    let scene = AudioSceneProjector.scene(for: state, catalog: scenes)

    #expect(scene.ambience == "amb_tulsa_city_identity_loop")
    #expect(scene.music == "music_tulsa_run_loop")
    #expect(scene.overlay == nil)
    #expect(scene.bossPhase == nil)
}

@Test func sceneSwitchesToBossLoopWhileTheAuthorityLives() throws {
    let catalog = try AudioEventCatalog.loadBundled()
    let scenes = try #require(catalog.scenes)
    var state = RunState(seed: 6, district: .oakland)
    state.entities.append(Entity(id: 900, kind: .boss, position: .init(), health: 400, radius: 42))

    let scene = AudioSceneProjector.scene(for: state, catalog: scenes)
    #expect(scene.music == "music_oakland_boss_loop")
    #expect(scene.ambience == "amb_oakland_city_identity_loop")
}

@Test func atlantaAdvancesItsMusicWithTheAuthoritativeBossPhase() throws {
    let catalog = try AudioEventCatalog.loadBundled()
    let scenes = try #require(catalog.scenes)

    // The simulation owns phase identity and already accounts for the district's
    // boss health multiplier, so audio follows state.bossPhase rather than
    // re-deriving thresholds from health.
    let expected = [1, 1, 2, 3, 3, 4]
    for ordinal in 0..<6 {
        var state = RunState(seed: 7, district: .atlanta)
        state.entities.append(Entity(id: 901, kind: .boss, position: .init(),
                                     health: 900, radius: 42))
        state.bossPhase = BossPhase(district: .atlanta, id: "p\(ordinal)",
                                    displayName: "Phase \(ordinal)",
                                    ordinal: ordinal, count: 6)
        let scene = AudioSceneProjector.scene(for: state, catalog: scenes)
        #expect(scene.bossPhase == expected[ordinal],
                "sim phase \(ordinal + 1) of 6 should sound movement \(expected[ordinal])")
        #expect(scene.music == "music_atlanta_boss_phase_\(expected[ordinal])_loop")
    }
}

@Test func extractionOpensTheBlindSpotOverlay() throws {
    let catalog = try AudioEventCatalog.loadBundled()
    let scenes = try #require(catalog.scenes)
    var state = RunState(seed: 8, district: .dayton)
    state.extractionOpen = true

    let scene = AudioSceneProjector.scene(for: state, catalog: scenes)
    #expect(scene.overlay == "sfx_blind_spot_field_loop")
}

@Test func completedRunSilencesEveryLoop() throws {
    let catalog = try AudioEventCatalog.loadBundled()
    let scenes = try #require(catalog.scenes)
    var state = RunState(seed: 9, district: .wichita)
    state.runCompleted = true

    let scene = AudioSceneProjector.scene(for: state, catalog: scenes)
    #expect(scene.ambience == nil)
    #expect(scene.music == nil)
    #expect(scene.overlay == nil)
}

@Test func districtScopedCueReplacesTheGenericOneInItsCity() throws {
    let catalog = try AudioEventCatalog.loadBundled()
    var resolver = AudioCueResolver(catalog: catalog)
    let event = RunEvent(.cityStateChanged, "Infrastructure integrity shifted")

    let inTulsa = resolver.resolve(events: [event], atTick: 600, district: .tulsa)
    #expect(inTulsa.map(\.assetName) == ["sfx_tulsa_behavioral_crude_extract"])
    #expect(inTulsa.contains { $0.assetName == "sfx_city_state_changed" } == false)
}

@Test func genericCuePlaysWhenTheDistrictAuthorsNoScopedCue() throws {
    let catalog = try AudioEventCatalog.loadBundled()
    // A cue list with no scoped entry for this event must still resolve generically.
    var resolver = AudioCueResolver(catalog: catalog)
    let event = RunEvent(.coordinationChanged, "Coordination chain updated")

    let requests = resolver.resolve(events: [event], atTick: 600, district: .tulsa)
    #expect(requests.map(\.assetName) == ["sfx_coordination_changed"])
}

@Test func sensorContactNowSoundsTheCameraScanSweep() throws {
    let catalog = try AudioEventCatalog.loadBundled()
    var resolver = AudioCueResolver(catalog: catalog)
    let requests = resolver.resolve(events: [RunEvent(.sensorContact, "LPR scan contact")], atTick: 300)
    #expect(requests.map(\.assetName) == ["sfx_camera_scan_sweep"])
}

@Test func everyDistrictLayersOnAReusableFoundationBed() throws {
    let catalog = try AudioEventCatalog.loadBundled()
    let scenes = try #require(catalog.scenes)
    // Batch 3 authors the shared beds as foundations that city ambience layers
    // over, so every district must name one and it must be a shared asset.
    for district in DistrictID.allCases {
        let definition = try #require(scenes.definition(for: district))
        let foundation = try #require(definition.foundationAsset,
                                      "\(district.rawValue) names no foundation bed")
        #expect(foundation.hasPrefix("amb_shared_"))
        #expect(foundation != definition.ambienceAsset)
    }
    // All five shared beds must actually be used, or one is dead content.
    let used = Set(scenes.districts.compactMap(\.foundationAsset))
    #expect(used.count == 5)
}

@Test func sceneCarriesFoundationBeneathCityAmbience() throws {
    let catalog = try AudioEventCatalog.loadBundled()
    let scenes = try #require(catalog.scenes)
    let scene = AudioSceneProjector.scene(for: RunState(seed: 11, district: .oakland), catalog: scenes)

    #expect(scene.foundation == "amb_shared_evidence_warehouse_loop")
    #expect(scene.ambience == "amb_oakland_city_identity_loop")
    // Foundation and city bed sound together; the city one does not replace it.
    #expect(scene.foundation != scene.ambience)
}

@Test func completedRunSilencesTheFoundationToo() throws {
    let catalog = try AudioEventCatalog.loadBundled()
    let scenes = try #require(catalog.scenes)
    var state = RunState(seed: 12, district: .atlanta)
    state.runCompleted = true
    let scene = AudioSceneProjector.scene(for: state, catalog: scenes)
    #expect(scene.foundation == nil)
    #expect(scene.ambience == nil)
}

@Test func bossMusicFollowsTheAuthoritativePhaseNotAHealthGuess() throws {
    let catalog = try AudioEventCatalog.loadBundled()
    let scenes = try #require(catalog.scenes)
    let definition = try #require(scenes.definition(for: .atlanta))
    let loops = try #require(definition.bossPhaseAssets)

    // Atlanta authors six simulation phases against four music movements, so the
    // ordinal is scaled rather than clamped — clamping would hold the last loop
    // across the final three phases.
    var seen: [Int] = []
    for ordinal in 0..<6 {
        let phase = BossPhase(district: .atlanta, id: "p\(ordinal)",
                              displayName: "Phase \(ordinal)", ordinal: ordinal, count: 6)
        seen.append(AudioSceneProjector.phaseIndex(for: phase, assetCount: loops.count))
    }
    #expect(seen == [0, 0, 1, 2, 2, 3])
    #expect(seen.first == 0 && seen.last == loops.count - 1)
    // Monotonic: music never steps backwards as the fight advances.
    #expect(zip(seen, seen.dropFirst()).allSatisfy { $0 <= $1 })
}

@Test func bossMusicOpensOnTheFirstMovementWithoutAnAuthoritativePhase() throws {
    let catalog = try AudioEventCatalog.loadBundled()
    let scenes = try #require(catalog.scenes)
    var state = RunState(seed: 21, district: .atlanta)
    state.bossPhase = nil
    state.entities.append(Entity(id: 950, kind: .boss, position: .init(), health: 900, radius: 42))

    // Health is deliberately not consulted: the district scales boss health by 3x,
    // so any local health heuristic disagrees with the simulation's own phase bands.
    let scene = AudioSceneProjector.scene(for: state, catalog: scenes)
    #expect(scene.music == "music_atlanta_boss_phase_1_loop")
    #expect(scene.bossPhase == 1)
}
