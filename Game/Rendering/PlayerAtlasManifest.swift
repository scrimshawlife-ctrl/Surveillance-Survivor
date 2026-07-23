import CoreGraphics
import Foundation

/// Production contract for the player atlas. v0.2 intake ships individual
/// transparent frame PNGs (one cell per logical name) rather than a packed sheet,
/// so frame rectangles are the full texture bounds of each imageset.
struct PlayerAtlasManifest: Equatable, Sendable {
    enum Direction: String, CaseIterable, Sendable {
        case down
        case left
        case up
        case right
    }

    enum Motion: String, CaseIterable, Sendable {
        case idle
        case walk
    }

    struct Sequence: Equatable, Sendable {
        let assetName: String
        let frameCount: Int
        let frameDuration: TimeInterval
        let anchor: CGPoint
        /// Logical canvas of each attached player frame PNG.
        let canvasPoints: CGSize
    }

    /// Measured canvas of the attached v0.2 player frame PNGs.
    static let canvasPoints = CGSize(width: 436, height: 640)

    static let sequences: [Sequence] = [
        .init(assetName: GameAssetName.Player.idleDown, frameCount: 1, frameDuration: 0.18, anchor: CGPoint(x: 0.5, y: 0.12), canvasPoints: canvasPoints),
        .init(assetName: GameAssetName.Player.idleLeft, frameCount: 1, frameDuration: 0.18, anchor: CGPoint(x: 0.5, y: 0.12), canvasPoints: canvasPoints),
        .init(assetName: GameAssetName.Player.idleUp, frameCount: 1, frameDuration: 0.18, anchor: CGPoint(x: 0.5, y: 0.12), canvasPoints: canvasPoints),
        .init(assetName: GameAssetName.Player.idleRight, frameCount: 1, frameDuration: 0.18, anchor: CGPoint(x: 0.5, y: 0.12), canvasPoints: canvasPoints),
        .init(assetName: GameAssetName.Player.walkDown, frameCount: 1, frameDuration: 0.11, anchor: CGPoint(x: 0.5, y: 0.12), canvasPoints: canvasPoints),
        .init(assetName: GameAssetName.Player.walkLeft, frameCount: 1, frameDuration: 0.11, anchor: CGPoint(x: 0.5, y: 0.12), canvasPoints: canvasPoints),
        .init(assetName: GameAssetName.Player.walkUp, frameCount: 1, frameDuration: 0.11, anchor: CGPoint(x: 0.5, y: 0.12), canvasPoints: canvasPoints),
        .init(assetName: GameAssetName.Player.walkRight, frameCount: 1, frameDuration: 0.11, anchor: CGPoint(x: 0.5, y: 0.12), canvasPoints: canvasPoints)
    ]

    static func validate() -> Bool {
        Set(sequences.map(\.assetName)).count == sequences.count &&
        sequences.allSatisfy { $0.frameCount > 0 && $0.frameDuration > 0 }
    }
}
