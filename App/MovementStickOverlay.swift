import SwiftUI
import SurveillanceCore

// Hallmark · component: movement-stick · genre: atmospheric · theme: terminal-grid

/// SwiftUI-owned virtual stick. SpriteKit touch routing on device was unreliable
/// for the left landscape half under hybrid overlays, so movement input lives here.
///
/// The active pad is exactly one half of the field (left or right by handedness).
/// Both halves use explicit equal widths so right-hand mode cannot collapse to zero
/// when a GeometryReader competes with an unframed clear sibling.
struct MovementStickOverlay: View {
    var controlsOnLeft: Bool
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
            let halfWidth = max(geometry.size.width * 0.5, 1)
            let fullHeight = geometry.size.height
            HStack(spacing: 0) {
                if controlsOnLeft {
                    stickPad
                        .frame(width: halfWidth, height: fullHeight)
                    Color.clear
                        .frame(width: halfWidth, height: fullHeight)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                } else {
                    Color.clear
                        .frame(width: halfWidth, height: fullHeight)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    stickPad
                        .frame(width: halfWidth, height: fullHeight)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(controlsOnLeft ? "Movement stick, left half" : "Movement stick, right half")
        .accessibilityIdentifier("movement-stick-overlay")
    }

    private var stickPad: some View {
        GeometryReader { pad in
            let rest = restOrigin(in: pad.size)
            ZStack {
                // Idle dock so the active half is obvious before the first touch.
                if origin == nil {
                    Circle()
                        .stroke(VisualDesignTokens.ink.opacity(stickOpacity * 0.35), lineWidth: 2)
                        .background(Circle().fill(VisualDesignTokens.paperElevated.opacity(stickOpacity * 0.28)))
                        .frame(width: radius * 2, height: radius * 2)
                        .position(rest)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }

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
            .frame(width: pad.size.width, height: pad.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        let start = origin ?? value.startLocation
                        if origin == nil {
                            origin = start
                        }
                        let dx = value.location.x - start.x
                        let dy = value.location.y - start.y
                        let distance = max(0.0001, hypot(dx, dy))
                        let scale = min(1, radius / distance)
                        let clamped = CGPoint(
                            x: start.x + dx * scale,
                            y: start.y + dy * scale
                        )
                        knob = clamped
                        // A resting thumb is never perfectly still, and direction taken
                        // from a two-pixel offset is mostly noise. Ignore the innermost
                        // ring, then rescale what is left across the full range so there
                        // is no speed step at the edge of the dead zone.
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
            // Keep the active pad on the lower two-thirds so thumbs rest naturally
            // and top chrome buttons remain free on the opposite side.
            .padding(.top, pad.size.height * 0.12)
        }
    }

    /// Default dock sits lower-centre of the active half so landscape thumbs land on it.
    private func restOrigin(in size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width * 0.5,
            y: size.height * 0.72
        )
    }
}
