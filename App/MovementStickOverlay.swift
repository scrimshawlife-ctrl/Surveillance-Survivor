import SwiftUI
import SurveillanceCore

/// SwiftUI-owned virtual stick. SpriteKit touch routing on device was unreliable
/// for the left landscape half under hybrid overlays, so movement input lives here.
struct MovementStickOverlay: View {
    var controlsOnLeft: Bool
    var stickScale: CGFloat
    var stickOpacity: Double
    var onMove: (Vector2) -> Void
    var onEnd: () -> Void

    @State private var origin: CGPoint?
    @State private var knob: CGPoint?

    private var radius: CGFloat { 64 * stickScale }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                if controlsOnLeft {
                    stickPad
                    Color.clear
                        .allowsHitTesting(false)
                } else {
                    Color.clear
                        .allowsHitTesting(false)
                    stickPad
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }

    private var stickPad: some View {
        GeometryReader { pad in
            ZStack {
                if let origin, let knob {
                    Circle()
                        .stroke(Color.white.opacity(stickOpacity * 0.7), lineWidth: 2)
                        .background(Circle().fill(Color.white.opacity(stickOpacity * 0.12)))
                        .frame(width: radius * 2, height: radius * 2)
                        .position(origin)
                    Circle()
                        .fill(Color.cyan.opacity(stickOpacity * 0.85))
                        .frame(width: radius * 0.9, height: radius * 0.9)
                        .position(knob)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        // UIKit/SwiftUI Y grows downward; simulation Y grows upward.
                        onMove(
                            Vector2(
                                x: Double((clamped.x - start.x) / radius),
                                y: Double((start.y - clamped.y) / radius)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
