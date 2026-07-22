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
        VStack(alignment: .leading, spacing: 4) {
            Text("SURVEILLANCE SURVIVOR").font(.caption.bold())
            Text("SUSPICION \(scene.suspicionTier)/5").font(.headline.monospacedDigit())
            ProgressView(value: scene.suspicion, total: 100).frame(width: 180)
        }
        .padding(10)
        .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 10))
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Suspicion tier \(scene.suspicionTier) of 5")
        .accessibilityValue("\(Int(scene.suspicion)) percent")
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
