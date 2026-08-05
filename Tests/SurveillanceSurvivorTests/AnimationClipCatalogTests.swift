import Testing
import SurveillanceCore
@testable import SurveillanceSurvivor

// The clips these cover shipped in #159 as PNGs that nothing selected, so the
// animation manifest still recorded them as `missing`. These assert the selection
// step: which state maps to which bank, and how each playback mode advances.

@MainActor
@Test func clipCatalogMapsStatesToShippedBanks() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    #expect(AnimationClipCatalog.clip(for: .player, state: .defeated)?.stem == "player_defeat")
    #expect(AnimationClipCatalog.clip(for: .player, state: .extracting)?.stem == "player_extract")
    #expect(AnimationClipCatalog.clip(for: .cameraPole, state: .scanning)?.stem == "lpr_scan_loop")
    #expect(AnimationClipCatalog.clip(for: .cameraPole, state: .destroyed)?.stem == "lpr_destroy_sequence")

    // Locomotion must fall through to the walk/idle atlas, not to a clip.
    #expect(AnimationClipCatalog.clip(for: .player, state: .moving) == nil)
    #expect(AnimationClipCatalog.clip(for: .player, state: .idle) == nil)
    // `.damaged` is the sustained health-below-30 state. Binding the hit reaction
    // there would freeze the walk cycle for the rest of the run.
    #expect(AnimationClipCatalog.clip(for: .player, state: .damaged) == nil)
    // Guards and the boss use their own walk banks, not clips.
    #expect(AnimationClipCatalog.clip(for: .securityGuard, state: .moving) == nil)
}

@MainActor
@Test func clipCatalogBanksAreActuallyOnDisk() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    // A mapping to a bank that is not attached would silently render the bare stem
    // forever, which looks identical to "not wired".
    let expected: [(String, Int)] = [
        ("player_damage", 4),
        ("player_defeat", 10),
        ("player_extract", 10),
        ("lpr_scan_loop", 6),
        ("lpr_destroy_sequence", 10),
    ]
    for (stem, count) in expected {
        #expect(OptionalSpriteFrameCycle.availableFrameCount(base: stem) == count, "\(stem) bank is not \(count) frames")
    }
}

@MainActor
@Test func oneShotAdvancesOnceAndHoldsItsFinalFrame() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    let clip = AnimationClip(stem: "player_defeat", playback: .oneShot, frameDuration: 0.10)
    let count = OptionalSpriteFrameCycle.availableFrameCount(base: clip.stem)
    #expect(count == 10)

    #expect(AnimationClipCatalog.frameName(for: clip, elapsed: 0) == "player_defeat")
    #expect(AnimationClipCatalog.frameName(for: clip, elapsed: 0.15) == "player_defeat_2")
    #expect(AnimationClipCatalog.frameName(for: clip, elapsed: 0.95) == "player_defeat_10")
    // Past the end it holds rather than wrapping — a defeat clip must not loop.
    #expect(AnimationClipCatalog.frameName(for: clip, elapsed: 5.0) == "player_defeat_10")
    #expect(AnimationClipCatalog.frameName(for: clip, elapsed: 60.0) == "player_defeat_10")

    #expect(AnimationClipCatalog.hasFinished(clip, elapsed: 0.5) == false)
    #expect(AnimationClipCatalog.hasFinished(clip, elapsed: 0.95))
}

@MainActor
@Test func loopWrapsAndVisitsEveryFrame() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    let clip = AnimationClip(stem: "lpr_scan_loop", playback: .loop, frameDuration: 0.16)
    let count = OptionalSpriteFrameCycle.availableFrameCount(base: clip.stem)
    #expect(count == 6)

    let visited = (0..<count).map {
        AnimationClipCatalog.frameName(for: clip, elapsed: 0.16 * (Double($0) + 0.5))
    }
    #expect(Set(visited).count == count)
    #expect(visited.first == "lpr_scan_loop")
    // Wraps back to frame 1 rather than sticking, and never reports completion.
    #expect(AnimationClipCatalog.frameName(for: clip, elapsed: 0.16 * 6) == "lpr_scan_loop")
    #expect(AnimationClipCatalog.hasFinished(clip, elapsed: 999) == false)
}

@MainActor
@Test func reducedMotionHoldsClipsOnFrameOne() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    // Same doctrine as the walk cycles: reduced motion suppresses the looping, and
    // frame index is presentation-only so holding it cannot change combat truth.
    let loop = AnimationClip(stem: "lpr_scan_loop", playback: .loop, frameDuration: 0.16)
    let once = AnimationClip(stem: "player_extract", playback: .oneShot, frameDuration: 0.10)
    #expect(AnimationClipCatalog.frameName(for: loop, elapsed: 3.0, holdStill: true) == "lpr_scan_loop")
    #expect(AnimationClipCatalog.frameName(for: once, elapsed: 3.0, holdStill: true) == "player_extract")
}

@MainActor
@Test func missingBankDegradesToTheStillNotToNothing() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    let ghost = AnimationClip(stem: "definitely_not_a_runtime_clip_zz", playback: .oneShot, frameDuration: 0.1)
    #expect(AnimationClipCatalog.frameName(for: ghost, elapsed: 0.5) == ghost.stem)
    // A bank that cannot play is finished immediately, so the projector falls back
    // to its ordinary still instead of stalling on a clip that will never advance.
    #expect(AnimationClipCatalog.hasFinished(ghost, elapsed: 0))
}
