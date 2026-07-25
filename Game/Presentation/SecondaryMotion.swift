import CoreGraphics
import Foundation
import SurveillanceCore

/// Bounded decorative offsets. Never written back into simulation entities.
struct SecondaryMotionSample: Equatable, Sendable {
    var offsetX: CGFloat
    var offsetY: CGFloat
    var lean: CGFloat
    var squash: CGFloat

    static let zero = SecondaryMotionSample(offsetX: 0, offsetY: 0, lean: 0, squash: 1)

    var pointOffset: CGPoint { CGPoint(x: offsetX, y: offsetY) }
}

struct SecondaryMotionSimulator: Sendable {
    /// Max visual offset in points (presentation pixels at 1x world scale).
    var maxOffset: CGFloat = 4
    var maxLean: CGFloat = 0.12
    var spring: CGFloat = 18
    var damping: CGFloat = 10

    private var offsetX: [UInt64: CGFloat] = [:]
    private var offsetY: [UInt64: CGFloat] = [:]
    private var velX: [UInt64: CGFloat] = [:]
    private var velY: [UInt64: CGFloat] = [:]
    private var lean: [UInt64: CGFloat] = [:]

    mutating func reset() {
        offsetX.removeAll(keepingCapacity: true)
        offsetY.removeAll(keepingCapacity: true)
        velX.removeAll(keepingCapacity: true)
        velY.removeAll(keepingCapacity: true)
        lean.removeAll(keepingCapacity: true)
    }

    /// Step decorative springs using authoritative velocity changes as impulse cues.
    mutating func step(
        entities: [Entity],
        previousVelocities: [UInt64: (x: Double, y: Double)],
        dt: CGFloat,
        scale: CGFloat
    ) -> [UInt64: SecondaryMotionSample] {
        guard scale > 0.001, dt > 0 else {
            return Dictionary(uniqueKeysWithValues: entities.map { ($0.id, .zero) })
        }

        var samples: [UInt64: SecondaryMotionSample] = [:]
        let live = Set(entities.map(\.id))
        offsetX = offsetX.filter { live.contains($0.key) }
        offsetY = offsetY.filter { live.contains($0.key) }
        velX = velX.filter { live.contains($0.key) }
        velY = velY.filter { live.contains($0.key) }
        lean = lean.filter { live.contains($0.key) }

        for entity in entities {
            let id = entity.id
            let prev = previousVelocities[id] ?? (entity.velocity.x, entity.velocity.y)
            let dvx = CGFloat(entity.velocity.x - prev.x)
            let dvy = CGFloat(entity.velocity.y - prev.y)

            // Impulse opposite acceleration (recoil / weight feel), clamped.
            var ox = (offsetX[id] ?? 0) - dvx * 0.02 * scale
            var oy = (offsetY[id] ?? 0) - dvy * 0.02 * scale
            var vx = (velX[id] ?? 0)
            var vy = (velY[id] ?? 0)

            // Critically-ish damped spring toward 0.
            let ax = -spring * ox - damping * vx
            let ay = -spring * oy - damping * vy
            vx += ax * dt
            vy += ay * dt
            ox += vx * dt
            oy += vy * dt

            let mag = hypot(ox, oy)
            let cap = maxOffset * scale
            if mag > cap, mag > 0 {
                ox = ox / mag * cap
                oy = oy / mag * cap
            }

            let targetLean = max(-maxLean, min(maxLean, CGFloat(entity.velocity.x) * 0.002)) * scale
            let currentLean = lean[id] ?? 0
            let nextLean = currentLean + (targetLean - currentLean) * min(1, dt * 12)

            offsetX[id] = ox
            offsetY[id] = oy
            velX[id] = vx
            velY[id] = vy
            lean[id] = nextLean

            let speed = hypot(entity.velocity.x, entity.velocity.y)
            let squash: CGFloat = speed > 40 ? max(0.92, 1 - CGFloat(speed) * 0.0004 * scale) : 1

            samples[id] = SecondaryMotionSample(offsetX: ox, offsetY: oy, lean: nextLean, squash: squash)
        }
        return samples
    }
}
