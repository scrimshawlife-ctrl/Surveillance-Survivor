import CoreGraphics
import Foundation
import SurveillanceCore

/// Orchestrates pose buffering, animation state, and secondary motion.
/// Pure presentation: never mutates simulation entities or emits gameplay events.
struct PresentationPipeline: Sendable {
    private(set) var settings = PresentationSettings()
    private var poseBuffer = PresentationPoseBuffer()
    private var secondary = SecondaryMotionSimulator()
    private var lastVelocities: [UInt64: (x: Double, y: Double)] = [:]
    private(set) var lastStates: [UInt64: EntityAnimationState] = [:]
    private(set) var lastSecondary: [UInt64: SecondaryMotionSample] = [:]

    struct PresentationSettings: Equatable, Sendable {
        var tier: PresentationQualityTier = .full
        var reducedMotion: Bool = false
        var reducedFlash: Bool = false

        mutating func apply(reducedMotion: Bool, reducedFlash: Bool) {
            self.reducedMotion = reducedMotion
            self.reducedFlash = reducedFlash
            tier = .resolve(reducedMotion: reducedMotion, reducedFlash: reducedFlash)
        }
    }

    struct DisplaySample: Equatable, Sendable {
        var position: CGPoint
        var heading: CGFloat
        var animationState: EntityAnimationState
        var secondary: SecondaryMotionSample
    }

    mutating func applyAccessibility(reducedMotion: Bool, reducedFlash: Bool) {
        settings.apply(reducedMotion: reducedMotion, reducedFlash: reducedFlash)
        if settings.tier == .minimal {
            secondary.reset()
            lastSecondary = [:]
        }
    }

    /// Call once per fixed simulation step after entities advance.
    mutating func commitSimulationStep(entities: [Entity]) {
        poseBuffer.commit(entities: entities)
        lastVelocities = Dictionary(uniqueKeysWithValues: entities.map {
            ($0.id, ($0.velocity.x, $0.velocity.y))
        })
    }

    /// Call every render frame. `rawAlpha` is accumulator/fixedStep in 0…1 between sim ticks.
    mutating func sample(
        entities: [Entity],
        tick: UInt64,
        extractionOpen: Bool,
        rawAlpha: CGFloat,
        frameDelta: CGFloat
    ) -> [UInt64: DisplaySample] {
        let blend = settings.tier.snapshotBlend(rawAlpha: rawAlpha)
        let scale = settings.tier.secondaryMotionScale
        let motion = secondary.step(
            entities: entities,
            previousVelocities: lastVelocities,
            dt: min(0.05, max(0, frameDelta)),
            scale: scale
        )
        lastSecondary = motion

        var out: [UInt64: DisplaySample] = [:]
        out.reserveCapacity(entities.count)
        for entity in entities {
            let pose = poseBuffer.displayPose(id: entity.id, blend: blend)
                ?? PresentationPose(entity: entity)
            let state = EntityAnimationStateMachine.state(
                for: entity,
                tick: tick,
                extractionOpen: extractionOpen
            )
            lastStates[entity.id] = state
            let sec = motion[entity.id] ?? .zero
            // Gameplay-significant stems stay locked to sim pose; only actors get decorative drift.
            let applyOffset = Self.allowsSecondaryPositionOffset(entity.kind)
            out[entity.id] = DisplaySample(
                position: CGPoint(
                    x: pose.point.x + (applyOffset ? sec.offsetX : 0),
                    y: pose.point.y + (applyOffset ? sec.offsetY : 0)
                ),
                heading: CGFloat(pose.heading),
                animationState: state,
                secondary: applyOffset ? sec : .zero
            )
        }
        // Keep velocity baseline for next frame's impulse estimate without overwriting
        // committed step velocities until the next commitSimulationStep.
        return out
    }

    /// Boot / district change: hard snap poses to entities.
    mutating func hardReset(entities: [Entity]) {
        poseBuffer = PresentationPoseBuffer()
        poseBuffer.commit(entities: entities)
        secondary.reset()
        lastVelocities = Dictionary(uniqueKeysWithValues: entities.map {
            ($0.id, ($0.velocity.x, $0.velocity.y))
        })
        lastStates = [:]
        lastSecondary = [:]
    }

    /// Actors may lean/recoil; projectiles, sensors, deployables, and extraction stay on sim pose.
    static func allowsSecondaryPositionOffset(_ kind: EntityKind) -> Bool {
        switch kind {
        case .player, .securityGuard, .boss:
            return true
        case .cameraPole, .projectile, .extraction, .mirrorArray, .signalFlood:
            return false
        }
    }
}
