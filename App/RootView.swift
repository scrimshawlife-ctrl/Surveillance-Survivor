import SwiftUI
import SpriteKit

struct RootView: View {
    @State private var scene = GameScene(size: CGSize(width: 844, height: 390))

    var body: some View {
        SpriteView(scene: scene, options: [.ignoresSiblingOrder])
            .ignoresSafeArea()
            .overlay(alignment: .topLeading) {
                HUDView(scene: scene).padding()
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
    }
}
