import Testing
import SurveillanceCore
@testable import SurveillanceSurvivor

// Inventory-first multi-frame probe — no fabricated PNGs.
//
// Guards and the boss were still-only until Batch 6 delivered their walk cycles.
// The two tests that pinned them at one frame now assert the opposite contract:
// the banks are attached, and the cycle must actually advance through them.

@MainActor
@Test func optionalSpriteFrameCycleGuardWalkBankIsAttached() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    let base = GameAssetName.Guard.default
    let count = OptionalSpriteFrameCycle.availableFrameCount(base: base)
    #expect(count == 4)

    // Frame 1 is the bare stem; every later frame is stem_N. Walking one full period
    // must visit every frame exactly once and return to the stem.
    let duration = 0.14
    let visited = (0..<count).map {
        OptionalSpriteFrameCycle.frameName(base: base, at: duration * (Double($0) + 0.5), frameDuration: duration)
    }
    #expect(visited == [base, "\(base)_2", "\(base)_3", "\(base)_4"])
    #expect(Set(visited).count == count)
    #expect(OptionalSpriteFrameCycle.frameName(base: base, at: duration * Double(count), frameDuration: duration) == base)
}

@MainActor
@Test func optionalSpriteFrameCycleEveryGuardArchetypeHasFullBank() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    // A partially-delivered roster would animate some archetypes and freeze others,
    // which reads as a rendering bug rather than as missing art.
    for archetype in GuardArchetype.allCases {
        let base = GameAssetName.Guard.asset(for: archetype)
        #expect(OptionalSpriteFrameCycle.availableFrameCount(base: base) == 4, "\(base) is not a 4-frame bank")
    }
}

@MainActor
@Test func optionalSpriteFrameCycleMissingBaseReportsZeroFrames() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    let ghost = "definitely_not_a_runtime_sprite_zz"
    #expect(OptionalSpriteFrameCycle.availableFrameCount(base: ghost) == 0)
    #expect(OptionalSpriteFrameCycle.frameName(base: ghost, at: 0.5) == ghost)
}

@MainActor
@Test func optionalSpriteFrameCyclePlayerWalkHasMultiFrameWhenAttached() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    // Player walk multi-frame bank is inventory-attached (Batch 2).
    let base = GameAssetName.Player.walkDown
    let count = OptionalSpriteFrameCycle.availableFrameCount(base: base)
    #expect(count >= 1)
    if count > 1 {
        let early = OptionalSpriteFrameCycle.frameName(base: base, at: 0, frameDuration: 0.11)
        let late = OptionalSpriteFrameCycle.frameName(base: base, at: 0.11 * 2.1, frameDuration: 0.11)
        #expect(early == base)
        #expect(late == "\(base)_3" || late == "\(base)_2" || late.hasPrefix(base))
        #expect(late != early || count == 1)
    }
}

@MainActor
@Test func optionalSpriteFrameCycleBossWalkBankIsAttached() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    let base = GameAssetName.Boss.default
    #expect(OptionalSpriteFrameCycle.availableFrameCount(base: base) == 4)
    #expect(OptionalSpriteFrameCycle.frameName(base: base, at: 0, frameDuration: 0.14) == base)
    #expect(OptionalSpriteFrameCycle.frameName(base: base, at: 0.21, frameDuration: 0.14) == "\(base)_2")
}

@MainActor
@Test func hostileStateGatesTheWalkCycleOnMovement() {
    // The projector advances enemy frames only while the sim reports movement, so a
    // halted guard holds its still rather than marching on the spot. Guard the
    // threshold itself: presentation must not invent its own idea of "moving".
    func hostile(speed: Double) -> Entity {
        Entity(
            id: 1,
            kind: .securityGuard,
            guardArchetype: .radioGuy,
            position: .init(),
            velocity: .init(x: speed, y: 0),
            health: 40,
            radius: 14
        )
    }
    let halted = hostile(speed: 0)
    let creeping = hostile(speed: 3)
    let walking = hostile(speed: 40)
    #expect(EntityAnimationStateMachine.hostileState(entity: halted) != .moving)
    #expect(EntityAnimationStateMachine.hostileState(entity: creeping) != .moving)
    #expect(EntityAnimationStateMachine.hostileState(entity: walking) == .moving)
}

@MainActor
@Test func reducedMotionHoldsSpriteFrameCycles() {
    // Reduced-motion resolves to .minimal. Looping limb animation is what that
    // setting exists to suppress, so cycles must hold frame 1 there and run everywhere
    // else. Frame index is presentation-only; holding it cannot alter combat truth.
    #expect(PresentationQualityTier.resolve(reducedMotion: true, reducedFlash: false) == .minimal)
    #expect(PresentationQualityTier.minimal.advancesSpriteFrameCycles == false)
    #expect(PresentationQualityTier.reduced.advancesSpriteFrameCycles)
    #expect(PresentationQualityTier.full.advancesSpriteFrameCycles)
}
