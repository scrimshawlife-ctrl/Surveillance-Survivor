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
