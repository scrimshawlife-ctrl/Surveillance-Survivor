import SpriteKit
import Testing
@testable import SurveillanceCore
@testable import SurveillanceSurvivor

/// Emulator-hosted smoke across the full ten-city catalog: each district
/// boots, projects MVP entities, and can open its authored Blind Spot without
/// a physical device.
@Suite("Emulator district catalog smoke")
struct EmulatorDistrictCatalogSmokeTests {
    @Test @MainActor func everyDistrictBootsProjectsAndLabelsOnEmulatorHost() {
        for district in DistrictID.allCases {
            let simulation = Simulation(seed: 0xD15_7_1C7, district: district)
            let scene = GameScene(size: CGSize(width: 844, height: 390))
            scene.installSimulationForTesting(simulation)

            #expect(scene.districtName == district.cityName, "label mismatch for \(district.rawValue)")
            #expect(scene.districtTitle == district.definition.title)
            #expect(scene.bossName == district.bossName)
            #expect(simulation.state.entities.contains { $0.kind == .player })
            #expect(
                simulation.state.entities.contains { $0.kind == .cameraPole },
                "expected starting LPR sensors for \(district.rawValue)"
            )

            guard let player = simulation.state.entities.first(where: { $0.kind == .player }) else {
                Issue.record("missing player for \(district.rawValue)")
                continue
            }
            #expect(
                scene.childNode(withName: "entity-\(player.id)") != nil,
                "player node not projected for \(district.rawValue)"
            )

            if let camera = simulation.state.entities.first(where: { $0.kind == .cameraPole }) {
                #expect(
                    scene.childNode(withName: "entity-\(camera.id)") != nil,
                    "LPR node not projected for \(district.rawValue)"
                )
            }
        }
    }

    @Test @MainActor func everyDistrictForcedBossDefeatOpensBlindSpotProjection() {
        for district in DistrictID.allCases {
            var state = RunState(seed: 0xB055, district: district)
            state.entities = [
                Entity(id: 1, kind: .player, position: .init(x: 0, y: 0), health: 100, radius: 18),
                Entity(id: 99, kind: .boss, position: .init(x: 100, y: 0), health: 0, radius: 42)
            ]
            var simulation = Simulation(state: state, rngSeed: 0xB055)
            _ = simulation.step(input: .init(autoFireEnabled: false))

            #expect(simulation.state.extractionOpen, "extraction closed for \(district.rawValue)")
            guard let extraction = simulation.state.entities.first(where: { $0.kind == .extraction }) else {
                Issue.record("no Blind Spot entity for \(district.rawValue)")
                continue
            }

            let authored = district.profile.extractionPosition
            #expect(abs(extraction.position.x - authored.x) < 0.01)
            #expect(abs(extraction.position.y - authored.y) < 0.01)

            let scene = GameScene(size: CGSize(width: 844, height: 390))
            scene.installSimulationForTesting(simulation)
            let node = scene.childNode(withName: "entity-\(extraction.id)")
            #expect(node != nil, "Blind Spot not projected for \(district.rawValue)")
            // Mapped decal when present; shape fallback still yields a node.
            if let sprite = node as? SKSpriteNode {
                #expect(sprite.userData?["asset"] as? String == GameAssetName.Environment.blindSpotDecal)
            }
        }
    }

    @Test func campaignChainUnlocksFirstThreeCitiesInOrder() {
        let suite = "EmulatorDistrictChain-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = CampaignProgressStore(defaults: defaults)
        #expect(store.progress.unlockedDistricts.map(\.id) == [.wichita])

        _ = store.applyRunOutcome(district: .wichita, extractionCompleted: true)
        #expect(store.progress.isUnlocked(.louisville))
        #expect(store.progress.nextDistrict(after: .wichita) == .louisville)

        _ = store.applyRunOutcome(district: .louisville, extractionCompleted: true)
        #expect(store.progress.isUnlocked(.tulsa))
        #expect(store.progress.nextDistrict(after: .louisville) == .tulsa)
        #expect(store.progress.completedDistricts == [.wichita, .louisville])

        // Defeat must not skip ahead.
        _ = store.applyRunOutcome(district: .tulsa, extractionCompleted: false)
        #expect(!store.progress.isUnlocked(.dayton))
        #expect(store.progress.highestUnlockedLevel == 3)
    }
}
