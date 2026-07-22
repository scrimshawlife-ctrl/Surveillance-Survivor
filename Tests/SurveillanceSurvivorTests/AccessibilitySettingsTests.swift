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
