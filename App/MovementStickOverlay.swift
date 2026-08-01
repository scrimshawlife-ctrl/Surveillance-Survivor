import SwiftUI
import SurveillanceCore

// Hallmark · component: movement-stick · genre: atmospheric · theme: terminal-grid

/// SwiftUI-owned virtual stick. SpriteKit touch routing on device was unreliable
/// under hybrid overlays, so movement input lives here.
///
/// Dynamic pad: the base appears at the press point anywhere on the playfield and
/// follows that origin until the finger lifts. No left/right half restriction.
struct MovementStickOverlay: View {
    var stickScale: CGFloat
    var stickOpacity: Double
    var onMove: (Vector2) -> Void
    var onEnd: () -> Void

    @State private var origin: CGPoint?
    @State private var knob: CGPoint?

    /// Fraction of the stick's travel treated as centre. Touch has no detent, so
    /// without this a thumb resting on the pad walks the player around slowly.
    private static let deadZone: CGFloat = 0.12

    private var radius: CGFloat { 64 * stickScale }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let origin, let knob {
                    Circle()
                        .stroke(VisualDesignTokens.ink.opacity(stickOpacity * 0.65), lineWidth: 2)
                        .background(Circle().fill(VisualDesignTokens.paperElevated.opacity(stickOpacity * 0.55)))
                        .frame(width: radius * 2, height: radius * 2)
                        .position(origin)
                        .allowsHitTesting(false)
                    Circle()
                        .fill(VisualDesignTokens.accent.opacity(stickOpacity * 0.9))
                        .frame(width: radius * 0.9, height: radius * 0.9)
                        .position(knob)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        // First sample of this drag becomes the stick base — wherever pressed.
                        let start = origin ?? value.startLocation
                        if origin == nil {
                            origin = start
                        }
                        let dx = value.location.x - start.x
                        let dy = value.location.y - start.y
                        let distance = max(0.0001, hypot(dx, dy))
                        let scale = min(1, radius / distance)
                        knob = CGPoint(
                            x: start.x + dx * scale,
                            y: start.y + dy * scale
                        )
                        // Ignore the innermost ring, then rescale the rest so there is
                        // no speed step at the dead-zone edge.
                        let travel = min(distance, radius) / radius
                        let throttle = travel <= Self.deadZone
                            ? 0
                            : (travel - Self.deadZone) / (1 - Self.deadZone)
                        // UIKit/SwiftUI Y grows downward; simulation Y grows upward.
                        onMove(
                            Vector2(
                                x: Double(dx / distance) * Double(throttle),
                                y: Double(-dy / distance) * Double(throttle)
                            )
                        )
                    }
                    .onEnded { _ in
                        origin = nil
                        knob = nil
                        onEnd()
                    }
            )
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Movement stick")
        .accessibilityHint("Press and drag anywhere on the field to move")
        .accessibilityIdentifier("movement-stick-overlay")
    }
}
