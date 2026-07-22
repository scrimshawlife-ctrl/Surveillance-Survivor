import SwiftUI
import SpriteKit

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var scene = GameScene(size: CGSize(width: 844, height: 390))

    var body: some View {
        SpriteView(scene: scene, options: [.ignoresSiblingOrder])
            .ignoresSafeArea()
            .overlay(alignment: .topLeading) {
                HUDView(scene: scene).padding()
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    scene.toggleControlSide()
                } label: {
                    Label(
                        scene.controlsOnLeft ? "Move stick to right" : "Move stick to left",
                        systemImage: "hand.point.\(scene.controlsOnLeft ? "right" : "left").fill"
                    )
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(.black.opacity(0.72))
                .padding()
                .accessibilityLabel(scene.controlsOnLeft ? "Use right-handed movement controls" : "Use left-handed movement controls")
            }
            .overlay {
                if scene.isRunPaused {
                    PauseOverlay()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                scene.setRunPaused(phase != .active)
            }
    }
}

private struct HUDView: View {
    @ObservedObject var scene: GameScene

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SURVEILLANCE SURVIVOR")
                .font(.caption.bold().monospaced())
                .foregroundStyle(.white.opacity(0.88))
            SuspicionMeter(value: scene.suspicion, tier: scene.suspicionTier)
        }
    }
}

private struct PauseOverlay: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "eye.slash.fill")
                .font(.largeTitle)
            Text("SIGNAL SUSPENDED")
                .font(.headline.monospaced())
            Text("The run will resume when the app becomes active.")
                .font(.caption)
        }
        .padding(24)
        .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
    }
}
