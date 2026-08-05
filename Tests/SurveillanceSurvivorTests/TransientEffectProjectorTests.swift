import SpriteKit
import Testing
import SurveillanceCore
@testable import SurveillanceSurvivor

// These four banks shipped in #159 and never played because nothing owned them:
// they are not an entity's texture, so there was nowhere to put them. These tests
// cover the spawn/despawn lifecycle and, above all, that effects do not leak —
// a burst that never clears would accumulate a node per frame.

@MainActor
private func effectNodes(in scene: SKScene, stem: String? = nil) -> [SKNode] {
    scene.children.filter { node in
        guard let name = node.name, name.hasPrefix(TransientEffectProjector.nodeNamePrefix) else { return false }
        guard let stem else { return true }
        return name == "\(TransientEffectProjector.nodeNamePrefix)\(stem)"
    }
}

@MainActor
private func camera(id: UInt64, health: Double, disabledUntil: UInt64? = nil) -> Entity {
    Entity(
        id: id,
        kind: .cameraPole,
        sensorArchetype: .lprCameraPole,
        position: .init(x: 100, y: 100),
        health: health,
        radius: 12,
        sensorDisabledUntilTick: disabledUntil
    )
}

@MainActor
@Test func blindSpotOpeningFiresOnceWhenTheExtractionAppears() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    let scene = SKScene(size: CGSize(width: 400, height: 400))
    let projector = TransientEffectProjector()
    let extraction = Entity(id: 7, kind: .extraction, position: .init(x: 50, y: 60), health: 1, radius: 40)

    projector.synchronize(entities: [extraction], bossPhase: nil, animationDelta: 1.0 / 60.0, in: scene)
    #expect(effectNodes(in: scene, stem: "fx_blind_spot_open").count == 1)

    // Still present across later frames, but never spawned a second time — the
    // Blind Spot opening is a one-time reveal, not a per-frame effect.
    for _ in 0..<5 {
        projector.synchronize(entities: [extraction], bossPhase: nil, animationDelta: 1.0 / 60.0, in: scene)
    }
    #expect(effectNodes(in: scene, stem: "fx_blind_spot_open").count == 1)
}

@MainActor
@Test func hardwareImpactFiresOnDamageAndClearsWhenTheClipEnds() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    let scene = SKScene(size: CGSize(width: 400, height: 400))
    let projector = TransientEffectProjector()

    projector.synchronize(entities: [camera(id: 1, health: 100)], bossPhase: nil, in: scene)
    #expect(effectNodes(in: scene, stem: "fx_impact_surveillance_hardware").isEmpty)

    projector.synchronize(entities: [camera(id: 1, health: 60)], bossPhase: nil, in: scene)
    #expect(effectNodes(in: scene, stem: "fx_impact_surveillance_hardware").count == 1)

    // Undamaged frames must not re-fire, or a stationary damaged camera would
    // emit an impact every frame forever.
    for _ in 0..<3 {
        projector.synchronize(entities: [camera(id: 1, health: 60)], bossPhase: nil, in: scene)
    }
    #expect(effectNodes(in: scene, stem: "fx_impact_surveillance_hardware").count == 1)

    // 6 frames at 0.06s: well past the end.
    for _ in 0..<40 {
        projector.synchronize(entities: [camera(id: 1, health: 60)], bossPhase: nil, animationDelta: 0.02, in: scene)
    }
    #expect(effectNodes(in: scene, stem: "fx_impact_surveillance_hardware").isEmpty)
}

@MainActor
@Test func redactionFieldTracksTheDisabledCameraAndDetaches() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    let scene = SKScene(size: CGSize(width: 400, height: 400))
    let projector = TransientEffectProjector()

    projector.synchronize(entities: [camera(id: 3, health: 100)], bossPhase: nil, in: scene)
    #expect(effectNodes(in: scene, stem: "fx_redaction_field").isEmpty)

    // redactionOrdinance disables sensors for a duration; the field lasts exactly
    // as long as the camera stays dark.
    projector.synchronize(entities: [camera(id: 3, health: 100, disabledUntil: 900)], bossPhase: nil, in: scene)
    #expect(effectNodes(in: scene, stem: "fx_redaction_field").count == 1)

    // It loops, so it must survive well past one period rather than expiring.
    for _ in 0..<60 {
        projector.synchronize(entities: [camera(id: 3, health: 100, disabledUntil: 900)], bossPhase: nil, animationDelta: 0.05, in: scene)
    }
    #expect(effectNodes(in: scene, stem: "fx_redaction_field").count == 1)

    projector.synchronize(entities: [camera(id: 3, health: 100)], bossPhase: nil, in: scene)
    #expect(effectNodes(in: scene, stem: "fx_redaction_field").isEmpty)
}

@MainActor
@Test func redactionFieldIsRemovedWhenItsCameraDespawns() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    let scene = SKScene(size: CGSize(width: 400, height: 400))
    let projector = TransientEffectProjector()

    projector.synchronize(entities: [camera(id: 4, health: 100, disabledUntil: 900)], bossPhase: nil, in: scene)
    #expect(effectNodes(in: scene, stem: "fx_redaction_field").count == 1)

    // The camera is gone; an attached loop with no owner would otherwise hang in
    // the scene for the rest of the run.
    projector.synchronize(entities: [], bossPhase: nil, in: scene)
    #expect(effectNodes(in: scene, stem: "fx_redaction_field").isEmpty)
}

@MainActor
@Test func bossTelegraphFiresOnPhaseChangeOnly() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    let scene = SKScene(size: CGSize(width: 400, height: 400))
    let projector = TransientEffectProjector()
    let boss = Entity(id: 9, kind: .boss, position: .init(x: 10, y: 10), health: 500, radius: 32)
    let first = BossPhase.resolve(district: .wichita, health: 500, maximumHealth: 500)
    let second = BossPhase.resolve(district: .wichita, health: 100, maximumHealth: 500)

    projector.synchronize(entities: [boss], bossPhase: first, in: scene)
    let afterFirst = effectNodes(in: scene, stem: "boss_telegraph_primary").count

    // Holding the same phase must not re-fire; a telegraph every frame would be
    // a strobe rather than a tell.
    for _ in 0..<4 {
        projector.synchronize(entities: [boss], bossPhase: first, in: scene)
    }
    #expect(effectNodes(in: scene, stem: "boss_telegraph_primary").count == afterFirst)

    if first != second {
        projector.synchronize(entities: [boss], bossPhase: second, in: scene)
        #expect(effectNodes(in: scene, stem: "boss_telegraph_primary").count == afterFirst + 1)
    }
}

@MainActor
@Test func resetDropsEveryLiveEffect() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    let scene = SKScene(size: CGSize(width: 400, height: 400))
    let projector = TransientEffectProjector()
    let extraction = Entity(id: 7, kind: .extraction, position: .init(), health: 1, radius: 40)

    projector.synchronize(entities: [extraction, camera(id: 3, health: 100, disabledUntil: 900)], bossPhase: nil, in: scene)
    #expect(!effectNodes(in: scene).isEmpty)

    // A new run must not inherit a half-played clip from the previous one.
    projector.reset()
    #expect(effectNodes(in: scene).isEmpty)
}

@MainActor
@Test func effectsDoNotAccumulateAcrossASustainedRun() {
    OptionalSpriteFrameCycle.resetCacheForTesting()
    let scene = SKScene(size: CGSize(width: 400, height: 400))
    let projector = TransientEffectProjector()
    var health = 400.0
    let boss = Entity(id: 9, kind: .boss, position: .init(), health: 500, radius: 32)

    // Damage the camera repeatedly over a long stretch. Bursts must retire as fast
    // as they spawn; an unbounded node count is the failure this guards.
    for step in 0..<300 {
        if step % 20 == 0 { health -= 5 }
        projector.synchronize(
            entities: [camera(id: 1, health: health), boss],
            bossPhase: nil,
            animationDelta: 0.02,
            in: scene
        )
    }
    #expect(effectNodes(in: scene).count < 8, "effects accumulated: \(effectNodes(in: scene).count)")
}
