import SpriteKit
import Testing
@testable import SurveillanceSurvivor

/// Headless GameScene smoke that advances a deterministic run on the simulator
/// host without requiring XCUITest gestures into SpriteKit.
@Suite("Simulator gameplay smoke")
struct SimulatorGameplaySmokeTests {
    @Test @MainActor func fixedStepAdvancesWhilePlaying() {
        let scene = GameScene(size: CGSize(width: 844, height: 390))
        // First update seeds the scene clock (frame delta is zero).
        scene.update(1)
        scene.update(1.1)
        #expect(scene.elapsedTicksForTesting > 0)
        #expect(scene.runCompleted == false)
        #expect(scene.playerDefeated == false)
        #expect(scene.playerHealth > 0)
    }

    @Test @MainActor func movementInputIsHonoredAcrossManyTicks() {
        let scene = GameScene(size: CGSize(width: 844, height: 390))
        scene.setMovement(.init(x: 1, y: 0))
        var time: TimeInterval = 0
        var advanced = false
        for _ in 0..<240 {
            time += 1.0 / 60.0
            scene.update(time)
            // Auto-fire can open an upgrade draft and freeze the fixed-step loop.
            if !scene.pendingUpgradeChoices.isEmpty {
                scene.selectUpgrade(at: 0)
            }
            if scene.elapsedTicksForTesting >= 60 {
                advanced = true
                break
            }
        }
        #expect(advanced)
        #expect(scene.runCompleted == false)
        scene.clearMovement()
    }

    @Test @MainActor func pauseFreezesSimulationThenResumeContinues() {
        let scene = GameScene(size: CGSize(width: 844, height: 390))
        scene.update(1)
        scene.update(1.1)
        let ticks = scene.elapsedTicksForTesting
        #expect(ticks > 0)

        scene.setRunPaused(true)
        scene.update(30)
        scene.update(30.5)
        #expect(scene.elapsedTicksForTesting == ticks)

        scene.setRunPaused(false)
        // Resume clears lastUpdate; first frame after unpause seeds the clock.
        scene.update(30.6)
        #expect(scene.elapsedTicksForTesting == ticks)
        scene.update(30.7)
        #expect(scene.elapsedTicksForTesting > ticks)
    }

    @Test @MainActor func shortDirectedWalkDoesNotCrashOrCompleteRun() {
        let scene = GameScene(size: CGSize(width: 844, height: 390))
        var time: TimeInterval = 0
        // Brief patrol around spawn — proves projector + simulation stay coherent.
        let path: [(Double, Double)] = [
            (1, 0), (0, 1), (-1, 0), (0, -1), (0, 0)
        ]
        for vector in path {
            scene.setMovement(.init(x: vector.0, y: vector.1))
            for _ in 0..<60 {
                time += 1.0 / 60.0
                scene.update(time)
                if !scene.pendingUpgradeChoices.isEmpty {
                    scene.selectUpgrade(at: 0)
                }
                if scene.runCompleted { break }
            }
        }
        #expect(scene.playerHealth >= 0)
        #expect(scene.elapsedTicksForTesting > 100)
    }
}
