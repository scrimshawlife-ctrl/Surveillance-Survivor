import CoreGraphics
import Foundation
import SurveillanceCore

/// Previous/current authoritative poses for presentation interpolation only.
struct PresentationPose: Equatable, Sendable {
    var x: Double
    var y: Double
    var heading: Double
    var velocityX: Double
    var velocityY: Double

    init(entity: Entity) {
        x = entity.position.x
        y = entity.position.y
        heading = entity.heading
        velocityX = entity.velocity.x
        velocityY = entity.velocity.y
    }

    init(x: Double, y: Double, heading: Double = 0, velocityX: Double = 0, velocityY: Double = 0) {
        self.x = x
        self.y = y
        self.heading = heading
        self.velocityX = velocityX
        self.velocityY = velocityY
    }

    func interpolated(toward next: PresentationPose, alpha: CGFloat) -> PresentationPose {
        let t = Double(max(0, min(1, alpha)))
        return PresentationPose(
            x: x + (next.x - x) * t,
            y: y + (next.y - y) * t,
            heading: heading + shortestAngleDelta(from: heading, to: next.heading) * t,
            velocityX: velocityX + (next.velocityX - velocityX) * t,
            velocityY: velocityY + (next.velocityY - velocityY) * t
        )
    }

    var point: CGPoint { CGPoint(x: x, y: y) }
}

/// Tracks last committed sim poses. Updating never mutates `SurveillanceCore` state.
struct PresentationPoseBuffer: Sendable {
    private var previous: [UInt64: PresentationPose] = [:]
    private var current: [UInt64: PresentationPose] = [:]

    mutating func commit(entities: [Entity]) {
        previous = current
        var next: [UInt64: PresentationPose] = [:]
        next.reserveCapacity(entities.count)
        for entity in entities {
            let pose = PresentationPose(entity: entity)
            next[entity.id] = pose
            if previous[entity.id] == nil {
                previous[entity.id] = pose
            }
        }
        current = next
        // Drop stale IDs
        let live = Set(next.keys)
        previous = previous.filter { live.contains($0.key) }
    }

    func displayPose(id: UInt64, blend: CGFloat) -> PresentationPose? {
        guard let cur = current[id] else { return nil }
        let prev = previous[id] ?? cur
        return prev.interpolated(toward: cur, alpha: blend)
    }

    func currentPose(id: UInt64) -> PresentationPose? { current[id] }
}

private func shortestAngleDelta(from: Double, to: Double) -> Double {
    var d = to - from
    while d > .pi { d -= 2 * .pi }
    while d < -.pi { d += 2 * .pi }
    return d
}
