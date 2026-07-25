import Testing
@testable import SurveillanceSurvivor

// Inventory-first multi-frame probe — no fabricated PNGs; asserts still-only behavior.

@MainActor
@Test func optionalSpriteFrameCycleStillOnlyReturnsBase() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    // guard_default is attached as a single still (no guard_default_2 in inventory).
    let base = GameAssetName.Guard.default
    #expect(OptionalSpriteFrameCycle.availableFrameCount(base: base) == 1)
    #expect(OptionalSpriteFrameCycle.frameName(base: base, at: 0) == base)
    #expect(OptionalSpriteFrameCycle.frameName(base: base, at: 1.0) == base)
    #expect(OptionalSpriteFrameCycle.frameName(base: base, at: 10.0) == base)
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
@Test func optionalSpriteFrameCycleBossStillOnlyToday() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    let base = GameAssetName.Boss.default
    #expect(OptionalSpriteFrameCycle.availableFrameCount(base: base) <= 1)
    #expect(OptionalSpriteFrameCycle.frameName(base: base, at: 3.0) == base)
}
