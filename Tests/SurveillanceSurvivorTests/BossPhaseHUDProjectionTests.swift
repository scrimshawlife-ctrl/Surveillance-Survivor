import SpriteKit
import Testing
@testable import SurveillanceCore
@testable import SurveillanceSurvivor

@Test @MainActor func gameScenePublishesCoreBossPhaseWithoutRecomputingThresholds() {
    for district in [DistrictID.sanFrancisco, .columbus, .newYorkCity, .losAngeles, .atlanta] {
        var state = RunState(seed: 0xFACE, district: district)
        let maximum = BossCatalog.bundled.shiftManagerHealth * district.profile.bossHealthMultiplier
        state.entities = [
            Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
            Entity(id: 2, kind: .boss, position: .init(x: 100, y: 0), health: maximum * 0.1, radius: 32)
        ]
        let simulation = Simulation(state: state, rngSeed: state.seed)
        let scene = GameScene(size: CGSize(width: 844, height: 390))

        scene.installSimulationForTesting(simulation)

        #expect(scene.bossPhaseName == simulation.state.bossPhase?.displayName)
        #expect(scene.bossPhaseProgress == simulation.state.bossPhase.map { "\($0.ordinal + 1)/\($0.count)" })
    }
}

/// The HUD shows the authority's integrity as a proportion, which is only meaningful
/// if the maximum it divides by is the district's authored one. A bare number could
/// not be read as progress: the maximum spans 1000 to 1400 across the campaign, so
/// "620" says nothing about whether the fight is nearly won.
@Test @MainActor func gameScenePublishesTheDistrictAuthoredAuthorityMaximum() {
    for district in [DistrictID.wichita, .columbus, .atlanta] {
        let expected = BossCatalog.bundled.shiftManagerHealth * district.profile.bossHealthMultiplier
        var state = RunState(seed: 0xB055, district: district)
        state.activeWeapons = []
        state.entities = [
            Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
            Entity(id: 2, kind: .boss, position: .init(x: 120, y: 0), health: expected * 0.5, radius: 32)
        ]
        let scene = GameScene(size: CGSize(width: 844, height: 390))
        scene.installSimulationForTesting(Simulation(state: state, rngSeed: 0xB055))
        scene.didMove(to: SKView(frame: CGRect(origin: .zero, size: scene.size)))
        scene.update(1)
        #expect(scene.bossMaximumHealth == expected,
                "\(district) published \(String(describing: scene.bossMaximumHealth)), expected \(expected)")
    }

    // No authority alive means no meter to draw.
    var quiet = RunState(seed: 0xB056, district: .wichita)
    quiet.activeWeapons = []
    quiet.entities = [Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18)]
    let scene = GameScene(size: CGSize(width: 844, height: 390))
    scene.installSimulationForTesting(Simulation(state: quiet, rngSeed: 0xB056))
    scene.didMove(to: SKView(frame: CGRect(origin: .zero, size: scene.size)))
    scene.update(1)
    #expect(scene.bossMaximumHealth == nil)
}
