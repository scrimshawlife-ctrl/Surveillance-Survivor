import SpriteKit
import Testing
@testable import SurveillanceCore
@testable import SurveillanceSurvivor

/// The marker geometry is covered by `BlindSpotWayfindingTests`. This covers the part
/// geometry cannot: that the node is actually built, attached to the camera, and
/// driven by simulation truth. A correct bearing helps nobody if the node was never
/// added to the scene or never leaves `isHidden`.
@MainActor
struct BlindSpotCompassWiringTests {
    private func scene(extractionAt exit: Vector2?, playerAt player: Vector2) -> GameScene {
        let scene = GameScene(size: CGSize(width: 844, height: 390))
        var state = RunState(seed: 4_242, district: .wichita)
        state.activeWeapons = []
        state.entities = [
            Entity(id: 1, kind: .player, position: player, health: 100, radius: 18)
        ]
        if let exit {
            state.extractionOpen = true
            state.entities.append(
                Entity(id: 2, kind: .extraction, position: exit, health: 1, radius: 60)
            )
        }
        scene.installSimulationForTesting(Simulation(state: state, rngSeed: 4_242))
        // didMove builds the camera-attached chrome; render drives the update.
        scene.didMove(to: SKView(frame: CGRect(origin: .zero, size: scene.size)))
        return scene
    }

    private func compass(in scene: GameScene) -> SKNode? {
        scene.camera?.children.first { $0.children.contains { $0.name == "blind-spot-arrow" } }
    }

    @Test func theMarkerIsBuiltAndAttachedToTheCamera() {
        let scene = scene(extractionAt: .init(x: 1_500, y: 0), playerAt: .init())
        #expect(compass(in: scene) != nil, "marker never reached the camera, so it can never be seen")
    }

    @Test func theMarkerStaysHiddenUntilTheBlindSpotOpens() {
        let scene = scene(extractionAt: nil, playerAt: .init())
        scene.update(1)
        #expect(compass(in: scene)?.isHidden == true,
                "nothing to point at yet — the marker must not appear")
    }
}
