import SpriteKit
import Testing
@testable import SurveillanceCore
@testable import SurveillanceSurvivor

/// The objective reads "Reach the Blind Spot" while the exit can sit anywhere on an
/// 1800x1080 district and the camera shows roughly a sixth of it. Measured across the
/// campaign, the exit was off-screen the moment it opened in eight of nine districts —
/// as far as 1534 units away — with no compass, arrow, or map of any kind. Winning
/// came down to wandering until you found it.
@MainActor
struct BlindSpotWayfindingTests {
    private let viewSize = CGSize(width: 844, height: 390)

    @Test func anExitAlreadyOnScreenIsNotMarked() {
        // The decal speaks for itself; a marker on top would only obscure it.
        let marker = GameScene.blindSpotMarker(
            cameraCentre: .zero,
            exit: CGPoint(x: 120, y: 40),
            viewSize: viewSize
        )
        #expect(marker == nil)
    }

    @Test func anOffScreenExitIsMarkedInItsDirection() {
        let cases: [(CGPoint, String)] = [
            (CGPoint(x: 1_500, y: 0), "east"),
            (CGPoint(x: -1_500, y: 0), "west"),
            (CGPoint(x: 0, y: 900), "north"),
            (CGPoint(x: 0, y: -900), "south"),
            (CGPoint(x: -1_200, y: 700), "north-west")
        ]
        for (exit, label) in cases {
            guard let marker = GameScene.blindSpotMarker(
                cameraCentre: .zero,
                exit: exit,
                viewSize: viewSize
            ) else {
                Issue.record("\(label) exit at \(exit) must be marked")
                continue
            }
            // The marker must point along the true bearing to the exit.
            let expected = atan2(exit.y, exit.x)
            #expect(abs(marker.rotation - expected) < 0.0001, "\(label) bearing wrong")
            // And must stay inside the viewport rather than drifting off with the target.
            #expect(abs(marker.position.x) <= viewSize.width / 2, "\(label) marker left the screen")
            #expect(abs(marker.position.y) <= viewSize.height / 2, "\(label) marker left the screen")
        }
    }

    @Test func theMarkerTracksTheExitAsThePlayerMoves() {
        // Approaching from the west, the bearing must stay eastward and then release
        // once the exit is genuinely on screen.
        let exit = CGPoint(x: 600, y: 0)
        for x in stride(from: -600.0, through: 0.0, by: 150.0) {
            let marker = GameScene.blindSpotMarker(
                cameraCentre: CGPoint(x: x, y: 0),
                exit: exit,
                viewSize: viewSize
            )
            guard let marker else {
                Issue.record("exit \(600 - x) away should still be marked")
                continue
            }
            #expect(abs(marker.rotation) < 0.0001, "should point due east from \(x)")
        }
        #expect(GameScene.blindSpotMarker(
            cameraCentre: CGPoint(x: 590, y: 0),
            exit: exit,
            viewSize: viewSize
        ) == nil, "standing on the exit must clear the marker")
    }
}
