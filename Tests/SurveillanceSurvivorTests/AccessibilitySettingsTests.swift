import SpriteKit
import Testing
@testable import SurveillanceSurvivor

@Test @MainActor func accessibilitySettingsApplyHandednessToTheInputScene() {
    let scene = GameScene(size: CGSize(width: 844, height: 390))

    scene.applyAccessibilitySettings(
        controlsOnLeft: false,
        stickScale: 1.2,
        stickOpacity: 0.5,
        reducedMotion: true,
        reducedFlash: true,
        hapticsEnabled: false
    )

    #expect(scene.controlsOnLeft == false)
}

@Test @MainActor func nextRunClearsCompletionState() {
    let scene = GameScene(size: CGSize(width: 844, height: 390))

    scene.startNextRun()

    #expect(scene.runCompleted == false)
    #expect(scene.completedRunReceipt == nil)
}

@Test @MainActor func pausingAndResumingDoesNotReplayBackgroundTime() {
    let scene = GameScene(size: CGSize(width: 844, height: 390))
    scene.update(1)
    scene.update(1.1)
    let activeTicks = scene.elapsedTicksForTesting
    #expect(activeTicks > 0)

    scene.setRunPaused(true)
    scene.update(60)
    #expect(scene.elapsedTicksForTesting == activeTicks)

    scene.setRunPaused(false)
    scene.update(60.1)
    #expect(scene.elapsedTicksForTesting == activeTicks)
    scene.update(60.2)
    #expect(scene.elapsedTicksForTesting > activeTicks)
}
