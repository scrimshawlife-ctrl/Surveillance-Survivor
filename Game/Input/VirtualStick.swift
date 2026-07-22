import CoreGraphics
import SurveillanceCore

struct VirtualStick {
    let radius: CGFloat
    private(set) var origin: CGPoint?
    private(set) var knob: CGPoint?

    init(radius: CGFloat = 64) {
        self.radius = radius
    }

    mutating func begin(at point: CGPoint) {
        origin = point
        knob = point
    }

    mutating func move(to point: CGPoint) -> Vector2 {
        guard let origin else { return .init() }

        let dx = point.x - origin.x
        let dy = point.y - origin.y
        let distance = max(0.0001, hypot(dx, dy))
        let scale = min(1, radius / distance)
        let clamped = CGPoint(x: origin.x + dx * scale, y: origin.y + dy * scale)
        knob = clamped

        return Vector2(
            x: Double((clamped.x - origin.x) / radius),
            y: Double((clamped.y - origin.y) / radius)
        )
    }

    mutating func end() {
        origin = nil
        knob = nil
    }
}
