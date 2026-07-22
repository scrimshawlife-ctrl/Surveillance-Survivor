import CoreGraphics
import Foundation

/// Production contract for the player atlas. Pixel rects remain unset until the
/// final v0.2 atlas dimensions are attached and verified. Runtime code must not
/// infer or guess frame coordinates from presentation boards.
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
    }

    static let sequences: [Sequence] = [
        .init(assetName: GameAssetName.Player.idleDown, frameCount: 1, frameDuration: 0.18, anchor: CGPoint(x: 0.5, y: 0.18)),
        .init(assetName: GameAssetName.Player.idleLeft, frameCount: 1, frameDuration: 0.18, anchor: CGPoint(x: 0.5, y: 0.18)),
        .init(assetName: GameAssetName.Player.idleUp, frameCount: 1, frameDuration: 0.18, anchor: CGPoint(x: 0.5, y: 0.18)),
        .init(assetName: GameAssetName.Player.idleRight, frameCount: 1, frameDuration: 0.18, anchor: CGPoint(x: 0.5, y: 0.18)),
        .init(assetName: GameAssetName.Player.walkDown, frameCount: 1, frameDuration: 0.11, anchor: CGPoint(x: 0.5, y: 0.18)),
        .init(assetName: GameAssetName.Player.walkLeft, frameCount: 1, frameDuration: 0.11, anchor: CGPoint(x: 0.5, y: 0.18)),
        .init(assetName: GameAssetName.Player.walkUp, frameCount: 1, frameDuration: 0.11, anchor: CGPoint(x: 0.5, y: 0.18)),
        .init(assetName: GameAssetName.Player.walkRight, frameCount: 1, frameDuration: 0.11, anchor: CGPoint(x: 0.5, y: 0.18))
    ]

    static func validate() -> Bool {
        Set(sequences.map(\.assetName)).count == sequences.count &&
        sequences.allSatisfy { $0.frameCount > 0 && $0.frameDuration > 0 }
    }
}
