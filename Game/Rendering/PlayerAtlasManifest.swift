import CoreGraphics
import Foundation

/// Production contract for the player atlas. Multi-frame sequences use the base
/// logical name as frame 1 and `{base}_{n}` for subsequent frames (n ≥ 2).
/// Anchors and roles stay aligned with `VisualAssetMap` player roles.
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

        /// Ordered texture names for this sequence (frame 1 = base name).
        var frameNames: [String] {
            guard frameCount > 1 else { return [assetName] }
            return [assetName] + (2...frameCount).map { "\(assetName)_\($0)" }
        }
    }

    /// Measured canvas of the attached player frame PNGs (Hallmark M7 tight crop).
    static let canvasPoints = CGSize(width: 414, height: 596)

    /// Idle stays single-frame until prop-stable multi-frame banks exist with:
    /// matching content bbox (feet-locked), continuous alpha (no face holes), and
    /// no opaque black canvas. Batch 2B `*_2` frames failed those checks on device
    /// (flash, size thrash, translucent face) and must not enter the idle loop.
    static let sequences: [Sequence] = [
        .init(assetName: GameAssetName.Player.idleDown, frameCount: 1, frameDuration: 0.28, anchor: CGPoint(x: 0.5, y: 0.12), canvasPoints: canvasPoints),
        .init(assetName: GameAssetName.Player.idleLeft, frameCount: 1, frameDuration: 0.28, anchor: CGPoint(x: 0.5, y: 0.12), canvasPoints: canvasPoints),
        .init(assetName: GameAssetName.Player.idleUp, frameCount: 1, frameDuration: 0.28, anchor: CGPoint(x: 0.5, y: 0.12), canvasPoints: canvasPoints),
        .init(assetName: GameAssetName.Player.idleRight, frameCount: 1, frameDuration: 0.28, anchor: CGPoint(x: 0.5, y: 0.12), canvasPoints: canvasPoints),
        .init(assetName: GameAssetName.Player.walkDown, frameCount: 4, frameDuration: 0.11, anchor: CGPoint(x: 0.5, y: 0.12), canvasPoints: canvasPoints),
        .init(assetName: GameAssetName.Player.walkLeft, frameCount: 4, frameDuration: 0.11, anchor: CGPoint(x: 0.5, y: 0.12), canvasPoints: canvasPoints),
        .init(assetName: GameAssetName.Player.walkUp, frameCount: 4, frameDuration: 0.11, anchor: CGPoint(x: 0.5, y: 0.12), canvasPoints: canvasPoints),
        .init(assetName: GameAssetName.Player.walkRight, frameCount: 4, frameDuration: 0.11, anchor: CGPoint(x: 0.5, y: 0.12), canvasPoints: canvasPoints)
    ]

    static func sequence(for assetName: String) -> Sequence? {
        sequences.first { $0.assetName == assetName }
    }

    /// Resolve the texture name for a base role asset at presentation time.
    static func frameName(baseAsset: String, at time: TimeInterval) -> String {
        guard let sequence = sequence(for: baseAsset), sequence.frameCount > 1 else {
            return baseAsset
        }
        let period = sequence.frameDuration * Double(sequence.frameCount)
        let t = period > 0 ? time.truncatingRemainder(dividingBy: period) : 0
        let index = min(sequence.frameCount - 1, max(0, Int(t / sequence.frameDuration)))
        return sequence.frameNames[index]
    }

    static func validate() -> Bool {
        Set(sequences.map(\.assetName)).count == sequences.count &&
        sequences.allSatisfy { $0.frameCount > 0 && $0.frameDuration > 0 }
    }

    /// All discrete texture stems required for multi-frame playback.
    static var allFrameAssetNames: [String] {
        sequences.flatMap(\.frameNames)
    }
}
