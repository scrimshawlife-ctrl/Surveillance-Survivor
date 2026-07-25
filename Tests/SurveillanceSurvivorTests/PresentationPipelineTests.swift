import XCTest
@testable import SurveillanceSurvivor
import SurveillanceCore

@MainActor
final class PresentationPipelineTests: XCTestCase {
    func testQualityTierRespectAccessibility() {
        XCTAssertEqual(PresentationQualityTier.resolve(reducedMotion: false, reducedFlash: false), .full)
        XCTAssertEqual(PresentationQualityTier.resolve(reducedMotion: false, reducedFlash: true), .reduced)
        XCTAssertEqual(PresentationQualityTier.resolve(reducedMotion: true, reducedFlash: false), .minimal)
        XCTAssertEqual(PresentationQualityTier.resolve(reducedMotion: true, reducedFlash: true), .minimal)
        XCTAssertEqual(PresentationQualityTier.full.snapshotBlend(rawAlpha: 0.25), 0.25, accuracy: 0.0001)
        XCTAssertEqual(PresentationQualityTier.minimal.snapshotBlend(rawAlpha: 0.25), 1, accuracy: 0.0001)
        XCTAssertEqual(PresentationQualityTier.minimal.secondaryMotionScale, 0, accuracy: 0.0001)
        // Density soft-out lives on the same quality ladder (CombatLimits-calibrated).
        XCTAssertEqual(PresentationQualityTier.full.densityScale(entityCount: 10), 1, accuracy: 0.0001)
        XCTAssertLessThan(
            PresentationQualityTier.full.densityScale(entityCount: CombatLimits.maximumProjectiles + 1),
            PresentationQualityTier.full.densityScale(entityCount: 10)
        )
        XCTAssertLessThan(
            PresentationQualityTier.minimal.densityScale(entityCount: 10),
            PresentationQualityTier.full.densityScale(entityCount: 10)
        )
    }

    func testPoseInterpolationIsBoundedAndDeterministic() {
        let a = PresentationPose(x: 0, y: 0, heading: 0)
        let b = PresentationPose(x: 10, y: 20, heading: .pi / 2)
        let mid = a.interpolated(toward: b, alpha: 0.5)
        XCTAssertEqual(mid.x, 5, accuracy: 0.0001)
        XCTAssertEqual(mid.y, 10, accuracy: 0.0001)
        XCTAssertEqual(mid.heading, .pi / 4, accuracy: 0.0001)
        let end = a.interpolated(toward: b, alpha: 1)
        XCTAssertEqual(end.x, 10, accuracy: 0.0001)
        XCTAssertEqual(end.y, 20, accuracy: 0.0001)
    }

    func testPoseBufferDoesNotRequireSimulationMutation() {
        var buffer = PresentationPoseBuffer()
        let e0 = Entity(id: 1, kind: .player, position: .init(x: 0, y: 0), health: 100, radius: 10)
        let e1 = Entity(id: 1, kind: .player, position: .init(x: 100, y: 0), health: 100, radius: 10)
        buffer.commit(entities: [e0])
        buffer.commit(entities: [e1])
        let mid = buffer.displayPose(id: 1, blend: 0.5)
        XCTAssertEqual(mid?.x ?? -1, 50, accuracy: 0.001)
        // Original entities remain caller-owned; buffer only copies poses.
        XCTAssertEqual(e0.position.x, 0, accuracy: 0.0001)
        XCTAssertEqual(e1.position.x, 100, accuracy: 0.0001)
    }

    func testPlayerAnimationStateFromAuthoritativeFields() {
        var player = Entity(id: 1, kind: .player, position: .init(), velocity: .init(x: 40, y: 0), health: 100, radius: 10)
        XCTAssertEqual(EntityAnimationStateMachine.playerState(entity: player, extractionOpen: false), .moving)
        player.velocity = .init()
        XCTAssertEqual(EntityAnimationStateMachine.playerState(entity: player, extractionOpen: false), .idle)
        player.health = 0
        XCTAssertEqual(EntityAnimationStateMachine.playerState(entity: player, extractionOpen: false), .defeated)
    }

    func testSecondaryMotionStaysBoundedAndDiesUnderMinimalTier() {
        var motion = SecondaryMotionSimulator()
        motion.maxOffset = 4
        let entity = Entity(
            id: 7,
            kind: .player,
            position: .init(),
            velocity: .init(x: 120, y: 0),
            health: 100,
            radius: 10
        )
        let prev = [UInt64(7): (x: 0.0, y: 0.0)]
        let sample = motion.step(entities: [entity], previousVelocities: prev, dt: 1.0 / 60.0, scale: 1)[7]
        XCTAssertNotNil(sample)
        XCTAssertLessThanOrEqual(hypot(sample!.offsetX, sample!.offsetY), 4.01)

        var pipeline = PresentationPipeline()
        pipeline.applyAccessibility(reducedMotion: true, reducedFlash: false)
        pipeline.hardReset(entities: [entity])
        pipeline.commitSimulationStep(entities: [entity])
        let display = pipeline.sample(
            entities: [entity],
            tick: 1,
            extractionOpen: false,
            rawAlpha: 1,
            frameDelta: 1.0 / 60.0
        )
        XCTAssertEqual(display[7]?.secondary.offsetX ?? 1, 0, accuracy: 0.0001)
        XCTAssertEqual(display[7]?.secondary.offsetY ?? 1, 0, accuracy: 0.0001)
    }

    func testPipelineSampleNeverWritesEntityState() {
        var entity = Entity(id: 3, kind: .projectile, position: .init(x: 5, y: 5), velocity: .init(x: 10, y: 0), health: 1, radius: 3)
        let before = entity
        var pipeline = PresentationPipeline()
        pipeline.hardReset(entities: [entity])
        pipeline.commitSimulationStep(entities: [entity])
        entity.position = .init(x: 50, y: 5)
        pipeline.commitSimulationStep(entities: [entity])
        _ = pipeline.sample(
            entities: [entity],
            tick: 2,
            extractionOpen: false,
            rawAlpha: 0.5,
            frameDelta: 0.016
        )
        XCTAssertEqual(entity.position.x, 50, accuracy: 0.0001)
        XCTAssertEqual(before.position.x, 5, accuracy: 0.0001)
    }
}
