import Foundation
import SurveillanceCore

/// How a multi-frame clip advances once it starts.
enum ClipPlayback: Equatable, Sendable {
    /// Repeats for as long as the entity stays in the triggering state.
    case loop
    /// Plays once from frame 1 and holds its final frame.
    case oneShot
}

/// A presentation clip keyed to an authoritative entity state.
struct AnimationClip: Equatable, Sendable {
    let stem: String
    let playback: ClipPlayback
    let frameDuration: TimeInterval
}

/// Maps `EntityAnimationState` — which is already derived from authoritative entity
/// fields — onto the multi-frame banks that shipped in #159.
///
/// The frames were on disk but nothing selected them, so `GAMEPLAY_ANIMATION_MANIFEST`
/// still recorded several of these clips as `missing`. This catalog is the missing
/// selection step; it introduces no new art and no new simulation state.
///
/// Isolation: this reads state, it never produces it. Clip identity and frame index
/// have no bearing on hits, damage or timing — those stay in `SurveillanceCore`.
enum AnimationClipCatalog {
    static func clip(for kind: EntityKind, state: EntityAnimationState) -> AnimationClip? {
        switch (kind, state) {
        case (.player, .defeated):
            // Terminal: play through, then hold the final pose under the defeat UI.
            return AnimationClip(stem: GameAssetName.Player.defeat, playback: .oneShot, frameDuration: 0.10)
        case (.player, .extracting):
            // Terminal: the run ends on the last frame, so holding it is correct.
            return AnimationClip(stem: GameAssetName.Player.extract, playback: .oneShot, frameDuration: 0.10)
        case (.cameraPole, .scanning):
            // Deliberately no clip. The lpr_scan_loop frames translate inside their
            // canvas — content spans the full 256px width, the horizontal centre
            // drifts 52px across the loop, and three frames touch both edges — so
            // played back the camera slid off its tile and re-entered from the left.
            // The still is a 46px-wide pole; the loop is a 203-256px assembly, which
            // also made the LPR read as far larger than the player.
            //
            // The sweep is projected instead from the sim's own `heading`, which
            // already drives the scan cone, as a bounded swivel in EntityProjector.
            // Restore a clip here only if a scan bank arrives that holds its
            // position and width across frames.
            return nil
        case (.cameraPole, .destroyed):
            return AnimationClip(stem: "lpr_destroy_sequence", playback: .oneShot, frameDuration: 0.09)
        default:
            return nil
        }
    }

    /// Hit reaction. Deliberately not keyed to `.damaged`, which is the sustained
    /// "health below 30" state — binding it there would freeze the walk cycle for the
    /// rest of the run. The projector triggers this on an observed health decrease.
    static let playerDamage = AnimationClip(
        stem: GameAssetName.Player.damage,
        playback: .oneShot,
        frameDuration: 0.08
    )

    /// Resolve the texture stem for `clip` at `elapsed` seconds since it started.
    ///
    /// Frame 1 is the bare stem and frames 2…N are `stem_N`, matching
    /// `OptionalSpriteFrameCycle`. Returns the bare stem when the bank is absent, so a
    /// missing clip degrades to the existing still rather than to nothing.
    @MainActor
    static func frameName(for clip: AnimationClip, elapsed: TimeInterval, holdStill: Bool = false) -> String {
        let count = OptionalSpriteFrameCycle.availableFrameCount(base: clip.stem)
        guard count > 1, !holdStill, clip.frameDuration > 0 else { return clip.stem }
        let step = Int(max(0, elapsed) / clip.frameDuration)
        let index: Int
        switch clip.playback {
        case .loop:
            index = step % count
        case .oneShot:
            index = min(count - 1, step)
        }
        return index == 0 ? clip.stem : "\(clip.stem)_\(index + 1)"
    }

    /// Whether a one-shot has reached its final frame. Loops never finish.
    @MainActor
    static func hasFinished(_ clip: AnimationClip, elapsed: TimeInterval) -> Bool {
        guard clip.playback == .oneShot else { return false }
        let count = OptionalSpriteFrameCycle.availableFrameCount(base: clip.stem)
        guard count > 1, clip.frameDuration > 0 else { return true }
        return Int(max(0, elapsed) / clip.frameDuration) >= count - 1
    }
}
